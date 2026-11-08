local Q,test=...
local C,T=Q.Core,Q.Trips
local function state(progress,target)
    return {level=3,classID=1,raceID=4,pos={x=.563,y=.456},done={[458]=true},skip={},offered={},mode="xp",budget=10,
        log={[459]={progress=progress or .8,progressKnown=true,location={x=.563,y=.456}},
            [97977]={progress=0,progressKnown=true,location=target or {x=.55,y=.441}}}}
end
local function quests(s)
    local out={}
    for _,q in ipairs(Q.Provider.Quests(s,{rewards={},profile="melee"})) do
        if q.id==459 or q.id==97977 then out[#out+1]=q end
    end
    return out
end
local function index(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return i end end end
end
local function allWorkFirst(route)
    local lastWork,firstReturn=0,math.huge
    for i,g in ipairs(route) do
        if g.action=="DO" then lastWork=i end
        if g.action=="TURN IN" then firstReturn=math.min(firstReturn,i) end
    end
    assert(lastWork>0 and firstReturn>lastWork)
end

test("forced Moss and Totems trip does both objectives before shared return",function()
    local s=state();local qs=quests(s)
    local trip=T.Build(qs,s)
    allWorkFirst(trip.steps)
    assert(trip.completed[459] and trip.completed[97977])
end)
test("near-complete Moss keeps nearby accepted Totems in the current outing",function()
    for _,progress in ipairs({0,.5,.8,.95}) do
        local s=state(progress);local qs=quests(s)
        local route,trips=T.Plan(qs,s)
        assert(#trips[1].quests==2)
        assert(index(route,459,"DO") and index(route,97977,"DO"))
        allWorkFirst(trips[1].steps)
        assert(index(route,459,"TURN IN")==index(route,97977,"TURN IN"))
    end
end)
test("combined outing is cheaper than actually doing the two return trips",function()
    local s=state();local qs=quests(s)
    local first=T.Build({qs[1]},s)
    local after=C.Copy(s);after.pos=C.Copy(first.steps[#first.steps].lastTarget)
    after.log[qs[1].id]=nil;after.done[qs[1].id]=true
    local second=T.Build({qs[2]},after)
    local combined=T.Build(qs,s)
    assert(combined.walking<first.walking+second.walking)
    assert(combined.minutes<first.minutes+second.minutes)
    assert(combined.xp==first.xp+second.xp)
end)
test("prior solo route cannot split the shared outing on the next refresh",function()
    local s=state(.95);s.previous={tripKey="459",nextKey="459:task:1"}
    local route,trips=T.Plan(quests(s),s)
    assert(#trips[1].quests==2);allWorkFirst(trips[1].steps)
    s.log[459].complete=true;s.log[459].location={x=.578,y=.452}
    local route2,trips2=T.Plan(quests(s),s)
    assert(#trips2[1].quests==2 and index(route2,97977,"DO")<index(route2,459,"TURN IN"))
end)
test("actual nearby ready turn-in still wins before shared-outing work",function()
    local s=state();s.log[459].complete=true;s.pos={x=.578,y=.452};s.log[459].location=C.Copy(s.pos)
    local route,trips=T.Plan(quests(s),s)
    assert(route[1].action=="TURN IN" and trips[1].nearbyReturns and #trips[1].quests==1)
end)
test("same return alone cannot pull distant or excessive work into outing",function()
    local s=state();local qs=quests(s)
    qs[2].objective={x=.20,y=.20};qs[2].minutes=60
    local trip=T.Choose(qs,s)
    assert(#trip.quests==1 and trip.quests[1].id==459)
    qs[2].objective={x=.55,y=.441}
    trip=T.Choose(qs,s);assert(#trip.quests==1 and trip.quests[1].id==459)
end)
test("skipped failed unaccepted and unlocated companions remain excluded",function()
    local s=state();s.skip[97977]=true
    assert(#T.Choose(quests(s),s).quests==1)
    s.skip={};s.log[97977].failed=true
    assert(#T.Choose(quests(s),s).quests==1)
    s.log[97977]=nil
    assert(#T.Choose(quests(s),s).quests==1)
    s.log[97977]={progress=0}
    assert(#T.Choose(quests(s),s).quests==1)
end)
test("shared return batching preserves timed delivery and player pin choice",function()
    local s=state();local qs=quests(s)
    qs[2].timed=true
    local trip=T.Choose(qs,s)
    assert(trip.urgent and #trip.quests==1 and trip.quests[1].id==97977)
    qs[2].timed=nil;s.pin=459
    local chosen=T.Choose(qs,s)
    local found=false;for _,q in ipairs(chosen.quests) do if q.id==459 then found=true end end
    assert(found and #chosen.quests==2)
end)
test("multi-stage gathering work retains precedence and shared return bounds",function()
    local s=state();local qs=quests(s)
    qs[2].tasks={{label="Totems A",match="A",target={x=.55,y=.441},minutes=1},
        {label="Totems B",match="B",target={x=.552,y=.435},minutes=1}}
    s.log[97977].objectives={{text="A",numRequired=2},{text="B",numRequired=2}}
    local trip=T.Build(qs,s)
    allWorkFirst(trip.steps)
    assert(#trip.quests<=4)
    assert(s.log[459].progress==.8 and not s.done[459] and not s.done[97977])
end)

test("shared-return batching also spans separate nearby objective stops",function()
    local s=state(.8,{x=.55,y=.411})
    local route,trips=T.Plan(quests(s),s)
    assert(#trips[1].quests==2)
    allWorkFirst(trips[1].steps)
end)
test("return barriers never deadlock a quest unlocked by that return",function()
    local s=state();s.log[97977]=nil
    local a=quests(s)[1]
    local child={id=90001,name="Unlocked gathering",level=3,minLevel=1,xp=500,minutes=2,
        all={459},start=C.Copy(a.finish),objective={x=.55,y=.441},finish=C.Copy(a.finish)}
    local trip=T.Build({a,child},s)
    assert(trip)
    local ret=index(trip.steps,459,"TURN IN");local pickup=index(trip.steps,90001,"PICK UP")
    assert(ret and pickup and ret<pickup)
end)
test("unconfirmed finished rows are not inserted as free companion work",function()
    local s=state(.95);s.log[97977].progress=1
    local trip=T.Choose(quests(s),s)
    assert(#trip.quests==1 and trip.quests[1].id==459)
end)
test("batching cannot add higher-risk work merely for shared travel",function()
    local s=state(.95);local qs=quests(s)
    qs[2].level=20
    local trip=T.Choose(qs,s)
    assert(#trip.quests==1 and trip.quests[1].id==459)
end)
