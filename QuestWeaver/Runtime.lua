local _, Q = ...
Q.Runtime={}
local R=Q.Runtime
local function call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c=pcall(fn,...)
    if ok then return a,b,c end
end
-- Quest-level positions describe the client's current stage, not every task
-- or a projected follow-up. Only accept coordinates in the planner's map space.
local function location(x,y,source)
    if type(x)=="number" and type(y)=="number" and x==x and y==y
        and x>=0 and x<=1 and y>=0 and y<=1 and not (x==0 and y==0) then
        return {x=x,y=y,source=source}
    end
end
function R.QuestLocation(id,map,pois)
    local api=C_QuestLog or {}
    local nextMap,x,y=call(api.GetNextWaypoint,id)
    local pos=nextMap==map and location(x,y,"WoW objective")
    if pos then return pos end
    x,y=call(api.GetNextWaypointForMap,id,map)
    pos=location(x,y,"WoW objective")
    if pos then return pos end
    for _,poi in ipairs(type(pois)=="table" and pois or {}) do
        if type(poi)=="table" and poi.questID==id then
            pos=location(poi.x,poi.y,"WoW quest area")
            if pos then return pos end
        end
    end
end
function R.Snapshot()
    local _,class,classID=UnitClass("player")
    local _,_,raceID=UnitRace("player")
    local s={level=UnitLevel("player"),class=class,classID=classID,raceID=raceID,
        done={},log={},skip=Q.db.skip,pin=Q.db.pin,mode=Q.db.mode,budget=Q.db.budget,previous=Q.previous}
    s.map=call(C_Map and C_Map.GetBestMapForUnit,"player")
    local pos=call(C_Map and C_Map.GetPlayerMapPosition,s.map,"player")
    if pos then s.pos={x=pos.x,y=pos.y} end
    local pois=call(C_QuestLog and C_QuestLog.GetQuestsOnMap,Q.Pack.mapID)
    local count=call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries) or call(GetNumQuestLogEntries) or 0
    for i=1,count do
        local info=call(C_QuestLog and C_QuestLog.GetInfo,i)
        if not info and GetQuestLogTitle then
            local title,level,_,header,_,complete,_,id=GetQuestLogTitle(i)
            info={title=title,level=level,isHeader=header,questID=id,isComplete=complete}
        end
        if info and not info.isHeader and info.questID and info.questID>0 then
            local id=info.questID
            local complete=call(C_QuestLog and C_QuestLog.IsComplete,id)
            if complete==nil then complete=info.isComplete==true or info.isComplete==1 end
            local objectives=call(C_QuestLog and C_QuestLog.GetQuestObjectives,id)
            local fulfilled,total=0,0
            for _,o in ipairs(objectives or {}) do
                local required=math.max(1,o.numRequired or 1)
                total=total+required
                fulfilled=fulfilled+(o.finished and required or math.min(required,o.numFulfilled or 0))
            end
            local text={}
            for _,o in ipairs(objectives or {}) do if o.text then text[#text+1]=o.text end end
            s.log[id]={complete=complete,failed=info.isComplete==-1 or info.isFailed,
                location=R.QuestLocation(id,Q.Pack.mapID,pois),
                objectives=objectives,text=table.concat(text,"; "),progressKnown=complete or total>0,
                progress=complete and 1 or (total>0 and fulfilled/total or 0)}
        end
    end
    for _,q in ipairs(Q.Pack.quests) do
        local done=call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,q.id)
        if done==nil then done=call(IsQuestFlaggedCompleted,q.id) end
        s.done[q.id]=done or Q.db.completed[q.id] or false
    end
    if type(MAX_QUESTLOG_QUESTS)=="number" then
        local active=0
        for _ in pairs(s.log) do active=active+1 end
        s.freeSlots=math.max(0,MAX_QUESTLOG_QUESTS-active)
    end
    return s
end

function R.Refresh()
    if not Q.db then return end
    local s=R.Snapshot()
    Q.state=s
    if Q.inWorld==false then
        Q.route={}; Q.status="Waiting for the world to load."
    elseif s.map~=Q.Pack.mapID or not s.pos then
        Q.route={}; Q.status="Travel to Shadowglen in Teldrassil to use this starter pack."
    elseif s.classID==nil or not s.raceID then
        Q.route={}; Q.status="Waiting for character information."
    elseif UnitFactionGroup("player")~="Alliance" then
        Q.route={}; Q.status="This starter pack is for Alliance characters."
    elseif s.pos.x<.50 or s.pos.x>.65 or s.pos.y<.23 or s.pos.y>.50 then
        Q.route={}; Q.status="Shadowglen pack: return to the starting area (northeast Teldrassil)."
    else
        Q.quests=Q.Provider.Quests(s,Q.db)
        Q.route,Q.trips=Q.Trips.Plan(Q.quests,s,24)
        Q.status=#Q.route>0 and "Next action is live. Later steps assume you complete this trip." or "No eligible quests remain in this pack. Check your level, skips, and prerequisites."
    end
    local first=Q.route[1]
    Q.previous=first and {tripKey=first.tripKey,nextKey=first.key} or nil
    if not first then Q.trips={} end
    Q.Navigation.Sync(first)
    if Q.UI then Q.UI.Render() end
end
function R.Waypoint()
    local next=Q.route and Q.route[1]
    if not next then return end
    if Q.Navigation.Available() then
        Q.Navigation.Show(next,true)
        if Q.UI then Q.UI.Render() end
        return
    end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(Q.Pack.mapID,next.target.x,next.target.y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    else
        print(string.format("QuestWeaver: %s %.1f, %.1f",next.name,next.target.x*100,next.target.y*100))
    end
end

local f=CreateFrame("Frame")
Q.events=f
f:SetScript("OnEvent",function(_,event,...)
    if event=="ADDON_LOADED" then
        if ...~="QuestWeaver" then
            if ...=="TomTom" then Q.dirty=true end
            return
        end
        QuestWeaverDB=type(QuestWeaverDB)=="table" and QuestWeaverDB or {}
        Q.db=QuestWeaverDB
        local db=Q.db
        db.skip=type(db.skip)=="table" and db.skip or {}
        db.completed=type(db.completed)=="table" and db.completed or {}
        db.rewards=type(db.rewards)=="table" and db.rewards or {}
        if db.mode~="xp" and db.mode~="gear" then db.mode="balanced" end
        if not Q.Gear.profiles[db.profile] then
            local _,class=UnitClass("player")
            db.profile=({HUNTER="ranged",MAGE="caster",WARLOCK="caster",PRIEST="caster",DRUID="caster",SHAMAN="caster"})[class] or "melee"
        end
        db.budget=math.max(0,math.min(30,tonumber(db.budget) or 10))
        if type(db.locked)~="boolean" then db.locked=false end
        db.compact=db.compact==true
        if type(db.autoWaypoint)~="boolean" then db.autoWaypoint=true end
        db.schema=3
        Q.UI.Create()
    elseif Q.db then
        if event=="PLAYER_LEAVING_WORLD" then Q.inWorld=false; Q.Navigation.Clear() end
        if event=="PLAYER_ENTERING_WORLD" then Q.inWorld=true end
        if event=="QUEST_DETAIL" or event=="QUEST_COMPLETE" or event=="QUEST_ITEM_UPDATE" then Q.Gear.Capture(Q.db) end
        if event=="QUEST_TURNED_IN" then
            local id=...
            if type(id)=="number" then Q.db.completed[id]=true; if Q.db.pin==id then Q.db.pin=nil end end
        end
        Q.dirty=true
    end
end)
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","QUEST_LOG_UPDATE","QUEST_POI_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED",
    "QUEST_TURNED_IN","QUEST_DETAIL","QUEST_COMPLETE","QUEST_ITEM_UPDATE","PLAYER_LEVEL_UP","PLAYER_EQUIPMENT_CHANGED","ZONE_CHANGED_NEW_AREA","GET_ITEM_INFO_RECEIVED"}) do
    pcall(f.RegisterEvent,f,event)
end
local elapsed=0
f:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<1 then return end
    elapsed=0
    if Q.db and (Q.dirty or Q.Navigation.NeedsUpdates() or (Q.UI.frame and Q.UI.frame:IsShown())) then
        Q.dirty=false; R.Refresh()
    end
end)

SLASH_QUESTWEAVER1="/qw"
SLASH_QUESTWEAVER2="/questweaver"
SlashCmdList.QUESTWEAVER=function(text)
    if not Q.db then return end
    local cmd,arg=(text or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd=cmd:lower()
    if cmd=="" or cmd=="show" then Q.UI.frame:Show(); Q.db.hidden=false
    elseif cmd=="hide" then Q.UI.frame:Hide(); Q.db.hidden=true
    elseif cmd=="mode" and (arg=="balanced" or arg=="xp" or arg=="gear") then Q.db.mode=arg
    elseif cmd=="profile" and Q.Gear.profiles[arg] then Q.db.profile=arg
    elseif cmd=="budget" and tonumber(arg) then Q.db.budget=math.max(0,math.min(30,tonumber(arg)))
    elseif cmd=="skip" or cmd=="pin" or cmd=="unskip" then
        local id=tonumber(arg) or (Q.route and Q.route[1] and Q.route[1].id)
        local supported=false
        for _,q in ipairs(Q.Pack.quests) do if q.id==id then supported=true end end
        if supported then
            if cmd=="pin" then Q.db.pin=id; Q.db.skip[id]=nil
            else Q.db.skip[id]=cmd=="skip" or nil; if Q.db.pin==id then Q.db.pin=nil end end
        else print("QuestWeaver: use a quest ID from the Shadowglen pack.") end
    elseif cmd=="unpin" then Q.db.pin=nil
    elseif cmd=="restore" then Q.db.skip={}; Q.db.pin=nil
    elseif cmd=="way" then R.Waypoint()
    elseif cmd=="auto" and (arg=="on" or arg=="off" or arg=="") then
        Q.Navigation.SetAutomatic(arg=="on" or (arg=="" and not Q.db.autoWaypoint))
    elseif cmd=="unlock" then Q.db.locked=false
    elseif cmd=="lock" then Q.db.locked=true
    elseif cmd=="minimize" or cmd=="compact" then Q.UI.SavePosition(); Q.db.compact=true; Q.UI.Layout()
    elseif cmd=="expand" then Q.UI.SavePosition(); Q.db.compact=false; Q.UI.Layout()
    elseif cmd=="resetposition" then Q.UI.ResetPosition()
    else print("QuestWeaver: /qw show|hide|way|unlock|lock|minimize|expand|resetposition; auto on|off; mode balanced|xp|gear; profile melee|ranged|caster|healer|tank; budget 0-30; skip|unskip|pin [questID]; unpin; restore") end
    if cmd~="" and cmd~="show" and cmd~="hide" and cmd~="way" and cmd~="lock" and cmd~="unlock" then Q.previous=nil end
    R.Refresh()
end
