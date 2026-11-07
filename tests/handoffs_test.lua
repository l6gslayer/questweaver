local Q,test=...
local C,T=Q.Core,Q.Trips
local savedDB=QuestDB
QuestDB=nil
local home={x=.588,y=.443}
local function state()
    return {level=5,classID=1,raceID=4,pos=C.Copy(home),done={},log={},skip={},offered={},itemStarts={},mode="xp",budget=10}
end
local function provider(s) return Q.Provider.Quests(s,{rewards={},profile="melee"}) end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function member(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return m,i end end end
end

test("each sigil introduction is offered only to its observed class and race",function()
    local classes={[3116]=1,[3117]=3,[3118]=4,[3119]=5,[3120]=11}
    for id,class in pairs(classes) do
        local s=state();s.classID=class
        assert(not C.Eligible(find(provider(s),id),s))
        s.offered[id]=true
        local q=find(provider(s),id)
        assert(C.Eligible(q,s) and q.intro and q.requiredClassID==class and q.requiredRaceID==4)
        assert(T.Plan({q},s)[1].action=="PICK UP")
        s.classID=2;assert(not C.Eligible(find(provider(s),id),s))
        s.classID=class;s.raceID=1;assert(not C.Eligible(find(provider(s),id),s))
        s.log[id]={complete=true};assert(C.Eligible(find(provider(s),id),s))
    end
end)
test("accepted sigils lead to individual trainers then disappear after return",function()
    local s=state();s.classID=11;s.log[3120]={}
    local q=find(provider(s),3120)
    assert(not q.pendingAction and q.objective.x==q.finish.x)
    assert(T.Plan({q},s)[1].action=="DO")
    s.log[3120].complete=true
    assert(T.Plan({find(provider(s),3120)},s)[1].action=="TURN IN")
    s.done[3120]=true;assert(#T.Plan({q},s)==0)
    local warrior=find(provider(state()),3116);local hunter=find(provider(state()),3117)
    assert(warrior.finish.x~=hunter.finish.x or warrior.finish.y~=hunter.finish.y)
end)
test("Crown handoff waits for actual or projected first Crown return",function()
    local s=state();local qs=provider(s);local crown=find(qs,928)
    assert(crown.handoff and not C.Eligible(crown,s))
    s.done[921]=true;assert(C.Eligible(find(provider(s),928),s))
    assert(crown.finish.y>.50 and C.IsLocal(crown.finish))
    local first=find(qs,921);s.done[920]=true;s.done[921]=nil
    s.log[921]={complete=true};s.pos=C.Copy(first.finish)
    local route=T.Plan({first,crown},s)
    local _,pre=member(route,921,"TURN IN");local _,pickup=member(route,928,"PICK UP")
    assert(pre and pickup and pre<pickup)
end)
test("Dolanaar handoffs share southbound travel and retain pickup precedence",function()
    local s=state();s.done[921]=true
    local qs=provider(s);local a,b=find(qs,928),find(qs,2159)
    local trip=T.Choose({a,b},s)
    assert(#trip.quests==2 and a.handoff and b.handoff)
    for _,q in ipairs({a,b}) do
        local _,pickup=member(trip.steps,q.id,"PICK UP")
        local _,ret=member(trip.steps,q.id,"TURN IN")
        assert(pickup and ret and pickup<ret)
    end
    local solo=T.Build({a},s).walking+T.Build({b},s).walking
    assert(trip.walking<solo)
end)
test("full log cannot forecast unaccepted handoffs until a slot is freed",function()
    local s=state();s.done[921]=true;s.freeSlots=0
    local qs=provider(s)
    assert(#T.Plan({find(qs,928),find(qs,2159)},s)==0)
    s.log[2159]={complete=true};s.pos=C.Copy(find(qs,2159).finish)
    local route=T.Plan({find(qs,928),find(qs,2159)},s)
    assert(route[1].id==2159 and route[1].action=="TURN IN")
end)
test("Dolanaar accepted quest discovery uses the expanded corridor",function()
    local s=state();s.pos={x=.556,y=.598}
    assert(C.IsLocal(s.pos) and C.IsLocal({x=.561,y=.617}))
    assert(not C.IsLocal({x=.2,y=.2}) and not C.IsLocal({x=.56,y=.70}))
    s.log[90001]={title="Dolanaar quest",location={x=.56,y=.62},xp=300}
    local q=find(provider(s),90001)
    assert(q and q.stageOnly and T.Plan({q},s)[1].target.y==.62)
    s.log[90001].complete=true;s.log[90001].location=C.Copy(s.pos)
    local route,trips=T.Plan({find(provider(s),90001)},s)
    assert(route[1].action=="TURN IN" and trips[1].nearbyReturns)
    local dest=Q.Navigation.Destination(route[1]);assert(dest.map==1438 and dest.y==.598)
end)
test("runtime and automatic guidance stay active after leaving Shadowglen",function()
    local oldMap,oldApi,oldWorld,oldAuto=C_Map,C_QuestLog,Q.inWorld,Q.db.autoWaypoint
    local oldTT=TomTom
    local pos={x=.556,y=.598};local added,removed=0,0
    C_Map={GetBestMapForUnit=function() return 1438 end,GetPlayerMapPosition=function() return pos end}
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=2159} end,
        ReadyForTurnIn=function() return true end,
        GetNextWaypoint=function() return 1438,.556,.598 end}
    TomTom={AddWaypoint=function(_,map,x,y) assert(map==1438 and y==.598);added=added+1;return {} end,
        RemoveWaypoint=function() removed=removed+1 end}
    Q.Navigation.Clear();Q.inWorld=true;Q.db.autoWaypoint=true
    Q.Runtime.Refresh()
    assert(#Q.route>0 and Q.route[1].id==2159 and Q.route[1].action=="TURN IN" and added==1)
    pos={x=.56,y=.70};Q.Runtime.Refresh()
    assert(#Q.route==0 and not Q.Navigation.current and removed>=1)
    C_Map,C_QuestLog,Q.inWorld,Q.db.autoWaypoint,TomTom=oldMap,oldApi,oldWorld,oldAuto,oldTT
end)
QuestDB=savedDB
