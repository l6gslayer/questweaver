local Q,test=...
local C,T=Q.Core,Q.Trips
local function state()
    return {level=5,classID=1,raceID=4,pos={x=.60,y=.40},done={},log={[91001]={complete=true},[91002]={complete=true}},
        skip={},offered={},freeSlots=38,mode="xp",budget=10}
end
local function quests()
    return {
        {id=91001,name="First ready return",level=5,minLevel=1,xp=500,minutes=.1,start={x=.58,y=.43},objective={x=.57,y=.50},finish={x=.57,y=.50}},
        {id=91002,name="Later ready return",level=5,minLevel=1,xp=100,minutes=.1,start={x=.58,y=.43},objective={x=.55,y=.57},finish={x=.55,y=.57}},
        {id=91003,name="Delivery passed now",level=5,minLevel=1,xp=10,minutes=.1,start={x=.60,y=.40},objective={x=.548,y=.558},finish={x=.548,y=.558}},
    }
end
local function index(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return i,m end end end
end
local function count(route,id,action)
    local n=0;for _,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then n=n+1 end end end;return n
end

test("pickup beside player can serve a later stop after an intermediate return",function()
    local s,qs=state(),quests()
    assert(C.Distance(qs[3].finish,qs[1].finish)>.03 and C.Distance(qs[3].finish,qs[2].finish)<.03)
    local route,trips=T.Plan(qs,s)
    local pickup,m=index(route,91003,"PICK UP")
    assert(pickup==1 and trips[1].multiStopPickups and trips[1].lookaheadTrips==2)
    assert(index(route,91001,"TURN IN")>pickup)
    assert(index(route,91003,"DO")>index(route,91001,"TURN IN"))
    assert(#trips[1].quests==3 and m.label:find("check availability",1,true))
    assert(not s.log[91003] and not s.done[91001] and s.freeSlots==38)
end)
test("multi-stop reforecast never repeats pickup reward or completion",function()
    local s,qs=state(),quests();local route,trips=T.Plan(qs,s)
    assert(count(route,91003,"PICK UP")==1 and count(route,91003,"TURN IN")==1)
    local xp=0;for _,trip in ipairs(trips) do xp=xp+trip.xp;assert(#trip.quests<=4) end
    assert(xp==610 and #trips<=3 and #route<=24)
    s.log[91003]={complete=true};s.pos=C.Copy(qs[3].finish)
    local accepted=T.Plan(qs,s);assert(not index(accepted,91003,"PICK UP"))
end)
test("multi-stop pickup retains live offer provenance and current eligibility",function()
    local s,qs=state(),quests();s.offered[91003]=true
    local route=T.Plan(qs,s);local _,m=index(route,91003,"PICK UP")
    assert(m.quest.pickupObserved and not m.label:find("check availability",1,true))
    s.skip[91003]=true;assert(not index(T.Plan(qs,s),91003,"PICK UP"))
    s.skip={};s.freeSlots=0
    local full,fullTrips=T.Plan(qs,s)
    assert(not fullTrips[1].multiStopPickups and index(full,91001,"TURN IN")<index(full,91003,"PICK UP"))
    s.freeSlots=38;qs[3].all={91002}
    local r,trips=T.Plan(qs,s)
    assert(not trips[1].multiStopPickups)
    local pickup=index(r,91003,"PICK UP")
    assert(not pickup or pickup>index(r,91002,"TURN IN"))
end)
test("urgent and actually nearby ready returns precede multi-stop pickup folding",function()
    local s,qs=state(),quests();qs[1].timed=true
    local route,trips=T.Plan(qs,s);assert(route[1].id==91001 and trips[1].urgent and not trips[1].multiStopPickups)
    s,qs=state(),quests();s.pos=C.Copy(qs[1].finish);qs[3].start=C.Copy(s.pos)
    route,trips=T.Plan(qs,s)
    assert(route[1].action=="TURN IN" and route[1].id==91001 and trips[1].nearbyReturns)
end)
test("unresolved later work cannot supply invented pickup return evidence",function()
    local s,qs=state(),quests();s.log[91002].complete=false;qs[2].stageOnly=true;qs[2].finish=nil
    local _,trips=T.Plan(qs,s)
    assert(not trips[1].multiStopPickups)
end)
test("four-quest prefixes and display bounds remain conservative",function()
    local s,qs=state(),quests()
    -- Four observed returns may already fill the prefix; no fifth quest can
    -- be folded into that outing just to reach another forecast destination.
    for i=4,5 do
        qs[i]={id=91000+i,name="Ready return",level=5,minLevel=1,xp=450,minutes=.1,
            start={x=.58,y=.43},objective={x=.57+(i-4)*.001,y=.50},finish={x=.57+(i-4)*.001,y=.50}}
        s.log[91000+i]={complete=true}
    end
    local route,trips=T.Plan(qs,s,2)
    assert(#route<=2 and #trips<=3)
    for _,trip in ipairs(trips) do assert(#trip.quests<=4) end
end)
test("ready-return lookahead can reach the third bounded forecast stop",function()
    local s,qs=state(),quests()
    qs[3].finish={x=.531,y=.628};qs[3].objective=C.Copy(qs[3].finish)
    qs[4]={id=91004,name="Third ready return",level=5,minLevel=1,xp=50,minutes=.1,
        start={x=.58,y=.43},objective={x=.53,y=.64},finish={x=.53,y=.64}}
    s.log[91004]={complete=true}
    local route,trips=T.Plan(qs,s)
    assert(index(route,91003,"PICK UP")==1)
    assert(trips[1].multiStopPickups and trips[1].lookaheadTrips==3 and #trips[1].quests==4)
    assert(index(route,91003,"DO")>index(route,91002,"TURN IN"))
end)

test("multi-stop lookahead preserves optional state-table defaults without mutation",function()
    local s,qs=state(),quests();s.done=nil;s.skip=nil
    local route,trips=T.Plan(qs,s)
    assert(route[1].action=="PICK UP" and trips[1].multiStopPickups)
    assert(s.done==nil and s.skip==nil)
end)
