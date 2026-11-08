local Q,test=...
local C,T=Q.Core,Q.Trips
local hub={x=.578,y=.417}
local function state()
    return {level=5,pos=C.Copy(hub),done={},log={},skip={},mode="xp",budget=10}
end
local function quest(id,finish)
    return {id=id,name="Quest "..id,level=5,minLevel=1,xp=450,minutes=2,
        start={x=.61,y=.42},objective={x=.60,y=.33},finish=finish or C.Copy(hub)}
end
local function firstMember(route,id,action)
    local step=route[1]
    if not step or step.action~=action then return false end
    for _,m in ipairs(step.members) do if m.id==id then return true end end
    return false
end

test("nearby completed Fang outranks far high-value pickup pin and previous route",function()
    local s=state();s.log[97236]={complete=true};s.pin=1;s.mode="gear"
    s.previous={tripKey="1",nextKey="1:pickup"}
    local far=quest(1);far.xp=100000;far.gear=10;far.minutes=.1
    local route,trips=T.Plan({far,quest(97236)},s)
    assert(firstMember(route,97236,"TURN IN") and trips[1].nearbyReturns)
    assert(#trips[1].quests==1 and trips[1].completed[97236])
end)
test("nearby observed returns group before any elective departures",function()
    local s=state();s.log[97236]={complete=true};s.log[917]={complete=true}
    local egg=quest(917,{x=.581,y=.418})
    local route,trips=T.Plan({quest(97236),egg,quest(1)},s)
    assert(route[1].action=="TURN IN" and #route[1].members==2)
    assert(trips[1].nearbyReturns and #trips[1].quests==2)
end)
test("accepted timed delivery still outranks ordinary nearby returns",function()
    local s=state();s.log[97236]={complete=true};s.log[3522]={}
    local timed=quest(3522,{x=.546,y=.329});timed.timed=true;timed.objective=timed.finish
    local trip=T.Choose({quest(97236),timed},s)
    assert(trip.urgent and #trip.quests==1 and trip.quests[1].id==3522)
end)
test("nearby priority follows the actual current player position",function()
    local s=state();s.log[97236]={complete=true}
    local far=quest(1);far.xp=100000;far.minutes=.1;s.pin=1
    local fang=quest(97236)
    assert(T.Choose({fang,far},s).nearbyReturns)
    s.pos={x=hub.x+.009,y=hub.y}
    assert(not T.Choose({fang,far},s).nearbyReturns)
    s.pos={x=hub.x+.007,y=hub.y}
    assert(T.Choose({fang,far},s).nearbyReturns)
end)
test("proximity and finished objective rows never manufacture completion",function()
    local s=state();s.log[97236]={complete=false,progress=1,
        objectives={{text="Fang",finished=true}}}
    local far=quest(1);far.xp=100000;far.minutes=.1;s.pin=1
    local trip=T.Choose({quest(97236),far},s)
    assert(not trip.nearbyReturns)
    local fang=T.Build({quest(97236)},s)
    assert(fang.steps[1].action=="DO")
end)
test("nearby priority excludes failed skipped done and unresolved item stages",function()
    local s=state();local qs={}
    for id=1,4 do qs[id]=quest(id);s.log[id]={complete=true} end
    s.log[1].failed=true;s.skip[2]=true;s.done[3]=true;qs[4].stageOnly=true;qs[4].pendingAction="ACCEPT ITEM"
    local trip=T.Choose(qs,s)
    assert(not trip or not trip.nearbyReturns)
end)
test("nearby returns free full quest log slots before projected pickups",function()
    local s=state();s.log[97236]={complete=true};s.freeSlots=0
    local route,trips=T.Plan({quest(97236),quest(1)},s)
    assert(firstMember(route,97236,"TURN IN") and trips[1].nearbyReturns)
    assert(#trips>1 and trips[2].steps[1].action=="PICK UP")
    assert(s.freeSlots==0 and s.log[97236].complete and not s.done[97236])
end)
test("nearby completed discovered quests use live return points",function()
    local s=state();s.log[90001]={complete=true};s.pos={x=.604,y=.345}
    local q=quest(90001,{x=.605,y=.345,source="WoW objective"});q.dynamic=true;q.acceptedOnly=true
    local route,trips=T.Plan({q},s)
    assert(firstMember(route,90001,"TURN IN") and route[1].target.x==.605)
    assert(trips[1].nearbyReturns and not s.done[90001])
end)
test("nearby return group remains bounded and deterministically nearest first",function()
    local s=state();local qs={}
    for id=1,6 do
        qs[#qs+1]=quest(id,{x=hub.x+(7-id)*.001,y=hub.y})
        s.log[id]={complete=true}
    end
    s.previous={nextKey="1:return",tripKey="1"}
    local a=T.Choose(qs,s);local b=T.Choose(qs,s)
    assert(#a.quests==4 and a.quests[1].id==6 and a.quests[4].id==3)
    assert(a.steps[1].id==6 and a.key==b.key and #a.steps[1].members==4)
    assert(s.previous.nextKey=="1:return" and s.pos.x==hub.x)
end)
