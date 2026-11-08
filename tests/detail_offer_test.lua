local Q,test=...
local R,F=Q.Runtime,Q.Feedback
local saved={quest=C_QuestLog,gossip=C_GossipInfo,id=GetQuestID,title=GetTitleText,
    count=GetNumAvailableQuests,capture=Q.Gear.Capture,refresh=R.Refresh,
    detail=R.detailOffer,open=R.gossipOpen,snapshot=R.Snapshot}
local event=Q.events:GetScript("OnEvent")
local function setup()
    R.detailOffer=nil;R.gossipOpen=false
    C_GossipInfo=nil;GetNumAvailableQuests=function() return 0 end
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() end,
        GetQuestDifficultyLevel=function() return 6 end}
    GetQuestID=function() return 90011 end
    GetTitleText=function() return "Direct available task" end
    Q.Gear.Capture=function() end
    R.Refresh=function() end
end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function state()
    local s=R.Snapshot()
    s.map=Q.Pack.mapID;s.pos={x=.57,y=.57};s.level=7;s.classID=3;s.raceID=4
    s.done={};s.skip={};s.freeSlots=30
    return s
end

test("direct detail without gossip creates a manual pickup and offer observation",function()
    setup();local calls=0;R.Refresh=function() calls=calls+1 end
    event(nil,"QUEST_DETAIL")
    assert(calls==1 and not R.gossipOpen and R.detailOffer.id==90011)
    local s=state()
    assert(s.offered[90011] and s.offerDetails[90011].title=="Direct available task")
    local qs=Q.Provider.Quests(s,{rewards={},profile="ranged"})
    local q=find(qs,90011)
    assert(q and q.start.source=="Observed quest detail" and q.level==6)
    local route,trips=Q.Trips.Plan({q},s)
    assert(route[1].action=="PICK UP" and q.stageOnly and not q.finish and not trips[1].completed[90011])
    F.Initialize({});F.Observe(s,route,trips)
    assert(F.Report():find("Offered: 90011",1,true))
    assert(not Q.db.detailOffer)
end)
test("direct detail closes and cannot leak into progress rewards or another greeting",function()
    for _,close in ipairs({"QUEST_FINISHED","QUEST_PROGRESS","QUEST_COMPLETE","QUEST_GREETING","GOSSIP_SHOW","PLAYER_LEAVING_WORLD"}) do
        setup();event(nil,"QUEST_DETAIL");assert(state().offered[90011])
        event(nil,close)
        assert(not R.detailOffer and not state().offered[90011])
    end
    Q.inWorld=true
end)
test("direct offer survives gossip close during detail transition but not quest closure",function()
    setup();event(nil,"QUEST_DETAIL");event(nil,"GOSSIP_CLOSED",false)
    assert(state().offered[90011])
    event(nil,"QUEST_FINISHED");assert(not state().offered[90011])
end)
test("accepting direct detail switches to accepted stage without stale pickup",function()
    setup();event(nil,"QUEST_DETAIL")
    C_QuestLog.GetNumQuestLogEntries=function() return 1 end
    C_QuestLog.GetInfo=function() return {questID=90011,title="Accepted task",level=6} end
    C_QuestLog.GetQuestObjectives=function() return {{numFulfilled=0,numRequired=3}} end
    C_QuestLog.GetNextWaypoint=function() return Q.Pack.mapID,.59,.58 end
    assert(not state().offered[90011])
    event(nil,"QUEST_ACCEPTED",1,90011)
    assert(not R.detailOffer)
    local s=state();local q=find(Q.Provider.Quests(s,{rewards={},profile="ranged"}),90011)
    assert(q and q.acceptedOnly and not q.pendingAction and not q.dynamicOffer)
    assert(Q.Trips.Plan({q},s)[1].action=="DO")
end)
test("direct detail missing bad or failing optional APIs never invents an offer",function()
    setup();GetQuestID=nil;event(nil,"QUEST_DETAIL");assert(not R.detailOffer)
    for _,v in ipairs({0,-1,0/0,math.huge,"90011"}) do
        GetQuestID=function() return v end;event(nil,"QUEST_DETAIL");assert(not R.detailOffer)
    end
    GetQuestID=function() error("unavailable") end
    event(nil,"QUEST_DETAIL");assert(not R.detailOffer)
    GetQuestID=function() return 90011 end;GetTitleText=nil
    C_QuestLog.GetQuestDifficultyLevel=function() error("unavailable") end
    event(nil,"QUEST_DETAIL");assert(state().offered[90011])
end)
test("failing reward reads cannot abort immediate offer refresh",function()
    setup();Q.Gear.Capture=saved.capture
    GetQuestID=function() error("unavailable") end
    local refreshed=0;R.Refresh=function() refreshed=refreshed+1 end
    event(nil,"QUEST_DETAIL")
    assert(refreshed==1 and not R.detailOffer)
end)
test("direct offers still respect observed completed flags",function()
    setup();C_QuestLog.IsQuestFlaggedCompleted=function(id) return id==90011 end
    event(nil,"QUEST_DETAIL")
    local s=state();s.done[90011]=R.Snapshot().done[90011]
    local q=find(Q.Provider.Quests(s,{rewards={},profile="ranged"}),90011)
    assert(s.done[90011] and q and not Q.Core.Eligible(q,s))
end)
test("immediate direct refresh records offer before fast manual acceptance",function()
    setup();local s
    F.Initialize({})
    R.Refresh=function()
        s=state();local qs=Q.Provider.Quests(s,{rewards={},profile="ranged"})
        local route,trips=Q.Trips.Plan({find(qs,90011)},s)
        Q.route=route;F.Observe(s,route,trips)
    end
    event(nil,"QUEST_DETAIL")
    F.Event("QUEST_ACCEPTED",90011,s,Q.route)
    local report=F.Report()
    assert(report:find("Offered: 90011",1,true) and report:find("kind=ACCEPTED quest=90011 relation=matches_next",1,true))
end)
C_QuestLog,C_GossipInfo,GetQuestID,GetTitleText=saved.quest,saved.gossip,saved.id,saved.title
GetNumAvailableQuests=saved.count;Q.Gear.Capture=saved.capture;R.Refresh=saved.refresh
R.detailOffer=saved.detail;R.gossipOpen=saved.open;R.Snapshot=saved.snapshot
F.Initialize(Q.db)
