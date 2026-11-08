local Q,test=...
local savedDB,savedNPC,savedGossip,savedQuestAPI=QuestDB,NpcDB,C_GossipInfo,C_QuestLog
local savedTitle,savedLevel,savedCount,savedID=GetAvailableTitle,GetAvailableLevel,GetNumAvailableQuests,GetAvailableQuestID
local R=Q.Runtime
local savedOpen=R.gossipOpen
QuestDB=nil;NpcDB=nil
local function state()
    return {level=6,classID=3,raceID=4,pos={x=.576,y=.566},map=1438,done={},log={},skip={},offered={},offerDetails={},itemStarts={},mode="balanced",budget=10,freeSlots=35}
end
local function provider(s) return Q.Provider.Quests(s,{rewards={},profile="ranged"}) end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function offered()
    local s=state();s.offered[90001]=true;s.offerDetails[90001]={title="A confirmed local task",level=6};return s
end

test("unknown confirmed NPC offer creates one manual pickup without invented work or return",function()
    local s=offered();local q=find(provider(s),90001)
    assert(q and q.dynamicOffer and q.offeredOnly and q.pendingAction=="PICK UP")
    assert(q.name=="A confirmed local task" and q.start.source=="Observed NPC offer")
    assert(not q.objective and not q.finish and q.stageOnly and q.xpEstimated)
    local route,trips=Q.Trips.Plan({q},s)
    assert(#route==1 and route[1].action=="PICK UP" and not trips[1].completed[90001])
    assert(route[1].target.x==s.pos.x and #trips==1)
end)
test("unknown live offer bypasses stale database gates but not skips done or capacity",function()
    QuestDB={Get=function(id,key)
        if id~=90001 then return end
        if key=="name" then return "Database task" end
        if key=="requiredLevel" then return 60 end
        if key=="preQuestGroup" then return {99999} end
        if key=="requiredSkill" then return 100 end
        if key=="finishedBy" then return {{123}} end
    end}
    NpcDB={Get=function() return {[141]={{57.6,56.6}}} end}
    local s=offered();local q=find(provider(s),90001)
    assert(Q.Core.Eligible(q,s) and q.stageOnly and not q.all)
    assert(q.name=="A confirmed local task" and q.level==6)
    assert(#Q.Trips.Plan({q},s)==1)
    s.freeSlots=0;assert(#Q.Trips.Plan({q},s)==0)
    s.freeSlots=35;s.skip[90001]=true;assert(#Q.Trips.Plan({q},s)==0)
    s.skip={};s.done[90001]=true;assert(#Q.Trips.Plan({q},s)==0)
    QuestDB=nil;NpcDB=nil
end)
test("offer disappearance removes unaccepted candidate and no saved availability is inferred",function()
    local s=offered();assert(find(provider(s),90001))
    s.offered={};assert(not find(provider(s),90001))
    s.offered[90001]=true;s.pos={x=.2,y=.2}
    local q=find(provider(s),90001);assert(q and Q.Core.Eligible(q,s) and q.pendingAction=="PICK UP")
    s.pos={x=.576,y=.566};s.map=999;assert(not find(provider(s),90001))
end)
test("confirmed outside-corridor offers stay manual and preserve pickup safeguards",function()
    local s=offered();s.pos={x=.61,y=.69}
    for _,source in ipairs({"Observed NPC offer","Observed quest detail"}) do
        s.offerDetails[90001].source=source
        local q=find(provider(s),90001)
        assert(Q.Core.Eligible(q,s) and q.pendingAction=="PICK UP" and q.start.source==source)
        assert(q.start.y==.69 and q.stageOnly and not q.objective and not q.finish)
        local route,trips=Q.Trips.Plan({q},s)
        assert(#route==1 and route[1].action=="PICK UP" and not trips[1].completed[90001])
        s.freeSlots=0;assert(#Q.Trips.Plan({q},s)==0);s.freeSlots=35
        s.skip[90001]=true;assert(not Q.Core.Eligible(q,s));s.skip={}
        s.done[90001]=true;assert(not Q.Core.Eligible(q,s));s.done={}
    end
    s.offered={};assert(not find(provider(s),90001))
end)
test("observed authored offers outside corridor do not project seed work or bypass class gates",function()
    local s=state();s.pos={x=.61,y=.69};s.offered[3117]=true
    local q=find(provider(s),3117)
    assert(Q.Core.Eligible(q,s) and q.pendingAction=="PICK UP" and q.start.x==s.pos.x)
    assert(q.stageOnly and not q.objective and not q.finish and not q.tasks)
    local route,trips=Q.Trips.Plan({q},s)
    assert(#route==1 and not trips[1].completed[3117])
    s.classID=1;assert(not Q.Core.Eligible(find(provider(s),3117),s))
    s.classID=3;s.raceID=1;assert(not Q.Core.Eligible(find(provider(s),3117),s))
    s.raceID=4;s.offered={};assert(not Q.Core.Eligible(find(provider(s),3117),s))
end)
test("outside offers require valid same-map position and retain return priorities",function()
    local s=offered();s.pos={x=.61,y=.69}
    for _,pos in ipairs({{x=0,y=0},{x=0/0,y=.69},{x=math.huge,y=.69}}) do
        s.pos=pos;assert(not find(provider(s),90001))
    end
    s.pos={x=.61,y=.69};s.map=999;assert(not find(provider(s),90001))
    s.map=1438;s.log[90002]={complete=true,location=Q.Core.Copy(s.pos),xp=100}
    local qs=provider(s);local route=Q.Trips.Plan({find(qs,90001),find(qs,90002)},s)
    assert(route[1].action=="TURN IN" and route[1].id==90002)
    assert(route[2].action=="PICK UP" and route[2].id==90001)
end)
test("accepting an offered quest transitions to one live objective candidate",function()
    local s=offered();s.log[90001]={title="A confirmed local task",level=6,xp=410,location={x=.577,y=.567}}
    local qs=provider(s);local q=find(qs,90001);local count=0
    for _,item in ipairs(qs) do if item.id==90001 then count=count+1 end end
    assert(count==1 and not q.dynamicOffer and not q.pendingAction and q.objective.x==.577)
    assert(q.acceptedOnly and q.stageOnly and not q.finish and q.xp==410 and not q.xpEstimated)
    assert(Q.Trips.Plan({q},s)[1].action=="DO")
end)
test("ready nearby return outranks a newly observed manual offer",function()
    local s=offered();s.log[90002]={title="Ready here",complete=true,xp=410,location={x=.576,y=.566}}
    local qs=provider(s);local route=Q.Trips.Plan({find(qs,90001),find(qs,90002)},s)
    assert(route[1].action=="TURN IN" and route[1].id==90002)
    assert(route[2].action=="PICK UP" and route[2].id==90001)
end)
test("modern offer names levels and ignored rows are transient snapshot data",function()
    C_GossipInfo={GetAvailableQuests=function() return {
        {questID=90001,title="A confirmed local task",questLevel=6},
        {questID=90002,title="Ignored task",questLevel=6,isIgnored=true}} end}
    GetNumAvailableQuests=function() return 1 end;GetAvailableQuestID=function() return 90002 end
    R.gossipOpen=true;R.gossipMap=Q.Pack.mapID
    local s=R.Snapshot()
    assert(s.offered[90001] and s.offerDetails[90001].title=="A confirmed local task")
    assert(s.offerDetails[90001].level==6 and not s.offered[90002])
    R.gossipOpen=false;s=R.Snapshot()
    assert(next(s.offered)==nil and next(s.offerDetails)==nil)
end)
test("legacy quest greeting can identify an unknown offered pickup",function()
    C_GossipInfo=nil;R.gossipOpen=true;R.gossipMap=Q.Pack.mapID
    GetNumAvailableQuests=function() return 1 end;GetAvailableQuestID=function() return 90003 end
    GetAvailableTitle=function() return "Legacy available task" end;GetAvailableLevel=function() return 4 end
    local s=R.Snapshot()
    assert(s.offered[90003] and s.offerDetails[90003].title=="Legacy available task" and s.offerDetails[90003].level==4)
end)
test("NPC opening and refresh events update immediately without selecting or accepting quests",function()
    local refresh,oldRefresh=0,R.Refresh
    R.Refresh=function() refresh=refresh+1 end
    local event=Q.events:GetScript("OnEvent")
    event(nil,"GOSSIP_SHOW");assert(R.gossipOpen and refresh==1)
    event(nil,"GOSSIP_OPTIONS_REFRESHED");assert(refresh==2)
    event(nil,"GOSSIP_CLOSED",true);assert(R.gossipOpen)
    event(nil,"GOSSIP_CLOSED",false);assert(not R.gossipOpen)
    event(nil,"GOSSIP_OPTIONS_REFRESHED");assert(not R.gossipOpen and refresh==2)
    event(nil,"QUEST_GREETING");assert(R.gossipOpen and refresh==3)
    event(nil,"QUEST_FINISHED");assert(not R.gossipOpen)
    R.Refresh=oldRefresh
end)
QuestDB,NpcDB,C_GossipInfo,C_QuestLog=savedDB,savedNPC,savedGossip,savedQuestAPI
GetAvailableTitle,GetAvailableLevel,GetNumAvailableQuests,GetAvailableQuestID=savedTitle,savedLevel,savedCount,savedID
R.gossipOpen=savedOpen
test("new capture tag preserves earlier build observations and sequence",function()
    local F=Q.Feedback
    local oldTag="0.2.0-route-feedback-1"
    local db={feedback={session=1,nextSeq=99,entries={{seq=98,session=1,kind="MARK",build=oldTag,context={}}}}}
    assert(F.BUILD~=oldTag)
    F.Initialize(db);F.Mark("New build check",state(),{})
    assert(db.feedback.entries[1].build==oldTag and db.feedback.entries[2].build==F.BUILD)
    assert(db.feedback.entries[2].seq==99 and db.feedback.entries[2].session==2)
    assert(F.Report(db):find(oldTag,1,true) and F.Report(db):find(F.BUILD,1,true))
    F.Initialize(Q.db)
end)
