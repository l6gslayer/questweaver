local Q,test=...
local Z,C,T,R,P=Q.Catalogues,Q.Core,Q.Trips,Q.Runtime,Q.Provider
local originalPack,oldDB,oldNpc=Q.Pack,QuestDB,NpcDB
Z.Select(1457);QuestDB=nil;NpcDB=nil
local function state()
    return {map=1457,level=12,classID=3,raceID=4,pos={x=.38,y=.21},
        log={},done={},skip={},offered={},itemStarts={},mode="balanced",budget=10,freeSlots=30}
end
local function q(s,id)
    local qs,notes=P.Quests(s,{rewards={},profile="ranged"})
    for _,v in ipairs(qs) do if v.id==id then return v,notes end end
end
local function has(notes,text)
    for _,note in ipairs(notes) do if note:find(text,1,true) then return true end end
end

test("Darnassus has a separate city catalogue with incoming accepted-only handoffs",function()
    assert(Q.Pack.mapID==1457 and Q.Pack.areaID==1657 and #Q.Pack.quests==11)
    local s=state()
    for _,id in ipairs({922,935,940,98391}) do
        assert(not C.Eligible(q(s,id),s))
        s.log[id]={complete=true}
        local a=q(s,id);local route=T.Plan({a},s)
        assert(route[1].action=="TURN IN" and a.finish and a.finish.source)
        assert(Q.Navigation.Destination(route[1]).map==1457)
    end
end)
test("live city return replaces catalogue reference without importing forest coordinates",function()
    local s=state();s.log[922]={complete=true,location={x=.41,y=.23},destinationMap=1457}
    local a=q(s,922);assert(a.finish.x==.41)
    assert(T.Plan({a},s)[1].target.x==.41)
    s.log[922]={complete=true,destinationMap=1438}
    local a,notes=q(s,922)
    assert(not a.finish and #T.Plan({a},s)==0 and has(notes,"Teldrassil"))
end)
test("city work transitions name the target zone rather than inventing a local objective",function()
    local s=state();s.done[922]=true
    local a=q(s,923);assert(C.Eligible(a,s) and a.pendingAction=="PICK UP")
    s.log[923]={progress=.25};local a,notes=q(s,923)
    assert(not a.objective and not a.finish and has(notes,"Teldrassil"))
    assert(#T.Plan({a},s)==0)
    s.log[923]={complete=true};assert(T.Plan({q(s,923)},s)[1].action=="TURN IN")
    s.log[952]={complete=true};a,notes=q(s,952)
    assert(#T.Plan({a},s)==0 and has(notes,"Darkshore"))
end)
test("unknown cross-zone accepted quest gives a transition notice",function()
    local s=state();s.log[991220]={destinationMap=1439,progress=.1}
    local qs,notes=P.Quests(s,{rewards={},profile="ranged"})
    assert(has(notes,"Darkshore"))
    for _,v in ipairs(qs) do assert(v.id~=991220) end
end)
test("foreign waypoint and current-map projection cannot project completion before travel",function()
    local oldAPI=C_QuestLog
    C_QuestLog={GetNextWaypoint=function() return 1438,.5,.6 end,
        GetNextWaypointForMap=function() return .30,.40 end}
    local point,map=R.QuestLocation(923,1457)
    assert(point.x==.30 and map==1438)
    local s=state();s.log[923]={progress=.5,location=point,destinationMap=map}
    local a,notes=q(s,923)
    assert(#T.Plan({a},s)==0 and has(notes,"Teldrassil"))
    C_QuestLog=oldAPI
end)
test("runtime entering Darnassus selects city guidance and returns to forest catalogue",function()
    local oldMap,oldAPI,oldUI,oldSync=C_Map,C_QuestLog,Q.UI,Q.Navigation.Sync
    local oldSkip,oldWorld,oldOuting=Q.db.skip,Q.inWorld,Q.db.outing
    local oldFaction=UnitFactionGroup
    local map=1457;local synced
    C_Map={GetBestMapForUnit=function() return map end,
        GetPlayerMapPosition=function() return {x=.40,y=.22} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=922,title="Rellian Greenspyre",level=7} end,
        ReadyForTurnIn=function() return true end,
        GetNextWaypoint=function() return map,.40,.22 end}
    UnitFactionGroup=function() return "Alliance" end
    Q.UI=nil;Q.db.skip={};Q.inWorld=true;Q.Navigation.Sync=function(step) synced=step end
    Z.Select(1438);R.Refresh()
    assert(Q.Pack.mapID==1457 and Q.route[1].id==922 and synced)
    assert(Q.Navigation.Destination(synced).map==1457)
    assert(not Q.status:find("No catalogue",1,true))
    map=1438;R.Refresh();assert(Q.Pack.mapID==1438)
    C_Map,C_QuestLog,Q.UI,Q.Navigation.Sync=oldMap,oldAPI,oldUI,oldSync
    Q.db.skip,Q.inWorld,Q.db.outing=oldSkip,oldWorld,oldOuting
    UnitFactionGroup=oldFaction;Z.Select(1457)
end)

test("version and build label stays visible in both layouts",function()
    local U=Q.UI;local oldCompact=Q.db.compact
    for _,compact in ipairs({true,false}) do
        Q.db.compact=compact;U.Layout();U.Render()
        assert(U.build:GetText():find("v0.2.0 | UI dev 3",1,true))
        assert(U.zone:GetText():find("Darnassus",1,true) and U.zone:IsShown() and U.build:IsShown())
    end
    Q.db.compact=oldCompact;U.Layout()
end)
test("city transition records and feedback retain foreign destination map",function()
    local F=Q.Feedback;F.Initialize({})
    local s=state();s.log[923]={progress=.5,destinationMap=1438}
    F.Observe(s,{},{});assert(F.Report():find("destMap=1438",1,true))
    F.Initialize(Q.db)
end)
Q.Pack=originalPack;QuestDB=oldDB;NpcDB=oldNpc
