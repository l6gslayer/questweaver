local Q,test=...
local C,T=Q.Core,Q.Trips
local function state(pos)
    return {level=5,classID=1,raceID=4,pos=pos or {x=.612,y=.476},done={[921]=true},
        log={[928]={complete=true}},skip={},offered={},mode="xp",budget=10}
end
local function known(s)
    local out={}
    for _,q in ipairs(Q.Provider.Quests(s,{rewards={},profile="melee"})) do
        if q.id==928 or q.id==2159 then out[#out+1]=q end
    end
    return out
end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function index(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return i,m end end end
end

test("passing Porthannius adds a low-value delivery before the Dolanaar leg",function()
    local s=state();s.pin=928;s.previous={tripKey="928",nextKey="928:return"}
    local qs=known(s)
    local route,trips=T.Plan(qs,s)
    local pickup,m=index(route,2159,"PICK UP")
    local crown=index(route,928,"TURN IN")
    assert(pickup==1 and crown>pickup and #trips[1].quests==2 and trips[1].onRoutePickups)
    assert(m.label:find("check availability",1,true))
    assert(s.log[2159]==nil and not find(qs,2159).onRoutePickup)
end)
test("observed NPC offer is distinguished from estimated pickup availability",function()
    local s=state();s.pin=928;s.offered[2159]=true
    local qs=known(s);find(qs,2159).xp=1
    local route=T.Plan(qs,s)
    local _,m=index(route,2159,"PICK UP")
    assert(m and m.quest.pickupObserved and not m.label:find("check availability",1,true))
end)
test("geometric on-route pickup stays ahead of a sticky destination leg",function()
    local s=state({x=.591,y=.395});s.pin=928;s.previous={tripKey="928",nextKey="928:return"}
    local qs=known(s);local delivery=find(qs,2159)
    delivery.start={x=.582,y=.462};delivery.xp=1
    local route,trips=T.Plan(qs,s)
    assert(index(route,2159,"PICK UP")==1 and trips[1].onRoutePickups)
    assert(index(route,2159,"PICK UP")<index(route,928,"TURN IN"))
end)
test("unrelated pickup location or return cannot interrupt the outing",function()
    local s=state();s.pin=928
    local qs=known(s);local delivery=find(qs,2159);delivery.xp=1
    delivery.start={x=.50,y=.25}
    assert(not T.Choose(qs,s).onRoutePickups)
    delivery.start=C.Copy(s.pos);delivery.finish={x=.50,y=.25};delivery.objective=delivery.finish
    assert(not T.Choose(qs,s).onRoutePickups)
end)
test("on-route pickups respect capacity skip completion gates and risk",function()
    local s=state();s.pin=928
    local qs=known(s);local delivery=find(qs,2159);delivery.xp=1
    s.freeSlots=0;assert(not T.Choose(qs,s).onRoutePickups)
    s.freeSlots=1;s.skip[2159]=true;assert(not T.Choose(qs,s).onRoutePickups)
    s.skip={};s.done[2159]=true;assert(not T.Choose(qs,s).onRoutePickups)
    s.done[2159]=nil;delivery.requiredClassID=3;assert(not T.Choose(qs,s).onRoutePickups)
    delivery.requiredClassID=nil;delivery.all={99999};assert(not T.Choose(qs,s).onRoutePickups)
    delivery.all=nil;delivery.level=20;assert(not T.Choose(qs,s).onRoutePickups)
end)
test("unknown stages and substantial work are not treated as free pickups",function()
    local s=state();s.pin=928
    local qs=known(s);local delivery=find(qs,2159);delivery.xp=1
    delivery.minutes=10;assert(not T.Choose(qs,s).onRoutePickups)
    delivery.minutes=.15;delivery.stageOnly=true;assert(not T.Choose(qs,s).onRoutePickups)
    delivery.stageOnly=nil;delivery.offeredOnly=true;assert(not T.Choose(qs,s).onRoutePickups)
end)
test("ready turnins beside player and accepted timed deliveries keep priority",function()
    local s=state({x=.561,y=.617});s.pin=928
    local qs=known(s);find(qs,2159).start=C.Copy(s.pos);find(qs,2159).xp=1
    local trip=T.Choose(qs,s)
    assert(trip.nearbyReturns and not trip.onRoutePickups and #trip.quests==1)
    s=state();qs=known(s);find(qs,928).timed=true
    assert(T.Choose(qs,s).urgent and not T.Choose(qs,s).onRoutePickups)
end)
test("pickup supplement remains within the four-quest and detour bounds",function()
    local s=state();s.pin=928
    local qs=known(s)
    find(qs,2159).xp=1
    for id=90001,90005 do
        qs[#qs+1]={id=id,name="Optional delivery",minLevel=1,level=5,xp=1,minutes=.05,
            start=C.Copy(s.pos),objective={x=.556,y=.598},finish={x=.556,y=.598}}
    end
    local baseline=T.Build({find(qs,928)},s)
    local trip=T.Choose(qs,s)
    assert(#trip.quests<=4 and trip.onRoutePickups)
    assert(trip.walking-baseline.walking<=.5 and trip.minutes-baseline.minutes<=1.5)
end)
