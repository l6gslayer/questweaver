local _, Q = ...
Q.UI={}
local U=Q.UI
local function label(parent,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    return t
end
local function button(parent,text,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetText(text); b:SetScript("OnClick",callback)
    return b
end
local function safe(text)
    return tostring(text or ""):gsub("|","||")
end

function U.Instruction(step)
    if not step then return "No next action" end
    if #step.members==1 then
        local m=step.members[1]
        return step.action..": "..safe(m.label or m.quest.name)
    end
    if step.action=="ACCEPT ITEM" then return "Accept quests from items in your bags" end
    if step.action=="LOOT ITEM" then return "Collect nearby quest-starting drops" end
    if step.action=="PICK UP" then return "Collect nearby quests" end
    if step.action=="TURN IN" then return "Turn in nearby quests" end
    return "Work nearby objectives"
end
function U.MemberText(member)
    local text=safe(member.label or member.quest.name)
    if member.action=="DO" then
        local log=Q.state and Q.state.log[member.id]
        if log then
            local task=Q.Trips.Tasks(member.quest)[member.task or 1]
            if task then
                local progress,known=Q.Trips.Progress(member.quest,task,log)
                text=text..(known and string.format(" (%.0f%%)",progress*100) or " (check quest log)")
            end
        end
    end
    if member.quest.xpEstimated then text=text.." (XP estimate)" end
    if member.quest.dynamic and member.quest.stageOnly and member.action=="DO" then
        text=text.." - current stage; return unknown"
    end
    return text
end
function U.SavePosition()
    local f=U.frame
    Q.db.position={x=f:GetLeft()/UIParent:GetWidth(),y=f:GetTop()/UIParent:GetHeight(),normalized=true}
end
function U.Place()
    local f,pos=U.frame,Q.db.position
    f:ClearAllPoints()
    if type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number" then
        local w,h=UIParent:GetWidth(),UIParent:GetHeight()
        local x,y=pos.x,pos.y
        if pos.normalized then x=x*w; y=y*h end
        x=math.max(0,math.min(w-f:GetWidth(),x)); y=math.max(f:GetHeight(),math.min(h,y))
        f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y)
    else f:SetPoint("CENTER",UIParent,"CENTER",0,0) end
end
function U.ResetPosition()
    Q.db.position=nil; U.Place(); U.SavePosition()
end
function U.Layout()
    local f=U.frame
    if not f then return end
    local compact=Q.db.compact
    f:SetSize(compact and 360 or 500,compact and 190 or 640)
    U.title:SetWidth(compact and 164 or 300)
    U.toggle:SetText(compact and "+" or "-")
    U.nextText:SetWidth(compact and 332 or 472)
    U.nextText:SetHeight(36)
    U.current:SetWidth(compact and 332 or 472)
    for _,widget in ipairs({U.summary,U.mode,U.skip,U.restore,U.scroll,U.footer}) do widget:SetShown(not compact) end
    if not compact then U.child:SetWidth(438); U.body:SetWidth(438) end
    U.Place()
end
function U.Create()
    local f=CreateFrame("Frame","QuestWeaverWindow",UIParent,BackdropTemplateMixin and "BackdropTemplate" or nil)
    U.frame=f
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    if f.SetBackdrop then
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=false,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
        f:SetBackdropColor(.035,.055,.065,.96); f:SetBackdropBorderColor(.25,.65,.48,1)
    end
    U.drag=CreateFrame("Frame",nil,f)
    U.drag:SetPoint("TOPLEFT",8,-4); U.drag:SetPoint("TOPRIGHT",-142,-4); U.drag:SetHeight(34)
    U.drag:EnableMouse(true); U.drag:RegisterForDrag("LeftButton")
    U.drag:SetScript("OnDragStart",function() if not Q.db.locked then f:StartMoving() end end)
    U.drag:SetScript("OnDragStop",function() f:StopMovingOrSizing(); U.SavePosition() end)
    U.title=label(U.drag,"GameFontNormalLarge"); U.title:SetPoint("TOPLEFT",6,-10); U.title:SetText("QuestWeaver")
    U.lock=button(f,"Lock",60,function() Q.db.locked=not Q.db.locked; U.Render() end)
    U.lock:SetPoint("TOPRIGHT",-78,-8)
    U.toggle=button(f,"-",28,function() U.SavePosition(); Q.db.compact=not Q.db.compact; U.Layout(); U.Render() end)
    U.toggle:SetPoint("TOPRIGHT",-44,-8)
    local close=button(f,"x",28,function() Q.db.hidden=true; f:Hide() end); close:SetPoint("TOPRIGHT",-10,-8)
    U.nextText=label(f,"GameFontNormal"); U.nextText:SetPoint("TOPLEFT",14,-48)
    U.current=label(f); U.current:SetPoint("TOPLEFT",U.nextText,"BOTTOMLEFT",0,-10)
    U.way=button(f,"Waypoint",92,function() Q.Runtime.Waypoint() end); U.way:SetPoint("BOTTOMLEFT",14,12)
    U.auto=button(f,"Auto: On",112,function()
        Q.Navigation.SetAutomatic(not Q.db.autoWaypoint); Q.Runtime.Refresh()
    end); U.auto:SetPoint("BOTTOMLEFT",114,12)
    U.navStatus=label(f); U.navStatus:SetPoint("BOTTOMLEFT",14,42); U.navStatus:SetWidth(332); U.navStatus:SetHeight(18)
    U.summary=label(f); U.summary:SetPoint("TOPLEFT",14,-208); U.summary:SetWidth(472)
    U.mode=button(f,"Balanced",116,function()
        Q.db.mode=({balanced="xp",xp="gear",gear="balanced"})[Q.db.mode]; Q.previous=nil; Q.Runtime.Refresh()
    end); U.mode:SetPoint("TOPLEFT",14,-264)
    U.skip=button(f,"Skip first quest",124,function()
        if Q.route and Q.route[1] then
            local id=Q.route[1].id; Q.db.skip[id]=true
            if Q.db.pin==id then Q.db.pin=nil end
            Q.previous=nil; Q.Runtime.Refresh()
        end
    end); U.skip:SetPoint("TOPLEFT",138,-264)
    U.restore=button(f,"Restore skips",116,function() Q.db.skip={}; Q.db.pin=nil; Q.previous=nil; Q.Runtime.Refresh() end)
    U.restore:SetPoint("TOPLEFT",270,-264)
    U.scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
    U.scroll:SetPoint("TOPLEFT",14,-304); U.scroll:SetPoint("BOTTOMRIGHT",-36,110)
    U.child=CreateFrame("Frame",nil,U.scroll); U.child:SetHeight(1); U.scroll:SetScrollChild(U.child)
    U.body=label(U.child); U.body:SetPoint("TOPLEFT")
    U.footer=label(f); U.footer:SetPoint("BOTTOMLEFT",14,72); U.footer:SetWidth(472)
    U.footer:SetText("Drag the title to move; Lock fixes its position. +/- changes layout.\n/qw resetposition recenters. Coordinates and times are estimates.")
    U.Layout()
    if Q.db.hidden then f:Hide() end
    U.Render()
end
function U.Render()
    if not U.frame then return end
    local step=Q.route and Q.route[1]
    U.lock:SetText(Q.db.locked and "Unlock" or "Lock")
    U.drag:EnableMouse(not Q.db.locked)
    U.mode:SetText(({xp="Fastest XP",balanced="Balanced",gear="Gear focused"})[Q.db.mode])
    U.auto:SetText(Q.db.autoWaypoint and "Auto: On" or "Auto: Off")
    U.navStatus:SetText(Q.Navigation.Status())
    U.nextText:SetText(U.Instruction(step))
    local lines={}
    if step then
        local ids={}
        for i,m in ipairs(step.members) do
            ids[m.id]=true
            if i<=3 then lines[#lines+1]=U.MemberText(m) end
        end
        if #step.members>3 then lines[#lines+1]="+"..(#step.members-3).." more: expand for details" end
        if step.action=="ACCEPT ITEM" then
            lines[#lines+1]="Use the item yourself; the plan refreshes after acceptance."
        else
            lines[#lines+1]=string.format("Destination %.1f, %.1f (%s)",step.target.x*100,step.target.y*100,step.target.source or "starter estimate")
        end
        local n=0; for _ in pairs(ids) do n=n+1 end
        if n>1 then lines[#lines+1]=n.." quests share this stop" end
        local trip=Q.trips and Q.trips[1]
        if trip and trip.urgent then lines[#lines+1]="Timed quest: avoid detours" end
        local destination=Q.Navigation.Destination(step)
        if destination and destination.hint then lines[#lines+1]=destination.hint end
    else lines[1]=Q.status or "Reading quest progress..." end
    for i,notice in ipairs(Q.notices or {}) do
        if i<=2 then lines[#lines+1]=safe(notice) end
    end
    if Q.notices and #Q.notices>2 then lines[#lines+1]="+"..(#Q.notices-2).." more: expand for details" end
    U.current:SetText(table.concat(lines,"\n"))
    U.way:SetEnabled(step~=nil and step.action~="ACCEPT ITEM")
    local height=math.min(360,math.max(190,162+math.min(190,U.current:GetStringHeight())))
    U.current:SetHeight(Q.db.compact and 190 or 100)
    if Q.db.compact then U.frame:SetHeight(height); return end
    local trip=Q.trips and Q.trips[1]
    U.summary:SetText(trip and string.format("%s | %.0f min gear allowance\nThis trip: %d quests | ~%.1f min | ~%d quest XP%s",Q.db.profile,Q.db.budget,#trip.quests,trip.minutes,trip.xp,
        trip.gearDetour and "\nPotential gear upgrade favored within your allowance." or (#trip.quests>1 and "\nShared travel is counted once for this trip." or "")) or (Q.status or "No trip"))
    local body={"|cff8ae8b1"..safe(Q.status or "Planning...").."|r"}
    local index=0
    for _,group in ipairs(Q.route or {}) do
        if group.trip~=index then
            index=group.trip
            body[#body+1]="\n|cffffd36a"..(index==1 and "CURRENT TRIP" or "PROJECTED TRIP "..index).."|r"
        end
        body[#body+1]="\n|cff8ae8b1"..U.Instruction(group).."|r"
        for _,m in ipairs(group.members) do
            if m.action=="ACCEPT ITEM" then
                body[#body+1]=string.format("  %s [quest %d]",U.MemberText(m),m.id)
            else body[#body+1]=string.format("  %s [quest %d] - %.1f, %.1f",U.MemberText(m),m.id,m.target.x*100,m.target.y*100) end
            if m.quest.note then body[#body+1]="  "..safe(m.quest.note) end
        end
    end
    if trip and trip.stageOnly then body[#body+1]="\nPlan stops at an observed stage; accept/advance quests to refresh. Reserved return time is estimated." end
    for _,notice in ipairs(Q.notices or {}) do body[#body+1]=safe(notice) end
    U.body:SetText(table.concat(body,"\n")); U.child:SetHeight(math.max(1,U.body:GetStringHeight()+24))
end
