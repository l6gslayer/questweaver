local Q,test=...
local T,C=Q.Trips,Q.Core
local hub={x=.58,y=.44}
local function state() return {level=5,pos=hub,done={},log={},skip={},mode="xp",budget=10} end
local function quest(id,target)
    return {id=id,name="Quest "..id,level=3,minLevel=1,xp=300,minutes=4,start=hub,finish=hub,objective=target or {x=.58,y=.30}}
end
local function memberIndex(route,id,action)
    for i,step in ipairs(route) do for _,m in ipairs(step.members) do if m.id==id and m.action==action then return i end end end
end
test("trip collects compatible quests before leaving the hub",function()
    local a,b=quest(1),quest(2,{x=.585,y=.305})
    local route,trips=T.Plan({a,b},state())
    assert(#trips[1].quests==2)
    assert(memberIndex(route,1,"PICK UP")<memberIndex(route,1,"DO"))
    assert(memberIndex(route,2,"PICK UP")<memberIndex(route,1,"DO"))
    assert(#route[1].members==2 and route[1].action=="PICK UP")
end)
test("one trip reduces travel versus two independent out-and-back walks",function()
    local a,b=quest(1),quest(2,{x=.585,y=.305})
    local trip=T.Build({a,b},state())
    local solo=T.Build({a},state()).walking+T.Build({b},state()).walking
    assert(trip.walking<solo*.7)
    assert(trip.xp==600)
end)
test("objectives and nearby turn-ins are batched",function()
    local a,b=quest(1),quest(2,{x=.585,y=.305})
    local route=T.Plan({a,b},state())
    assert(#route[2].members==2 and route[2].action=="DO")
    assert(#route[3].members==2 and route[3].action=="TURN IN")
end)
test("a chain of adjacent points cannot stretch one stop across an area",function()
    local a,b,c=quest(1),quest(2,{x=.595,y=.30}),quest(3,{x=.610,y=.30})
    local trip=T.Build({a,b,c},state())
    local work={}
    for _,step in ipairs(trip.steps) do if step.action=="DO" then work[#work+1]=step end end
    assert(#work==2 and #work[1].members==2 and #work[2].members==1)
end)
test("close objectives do not invent shared combat savings",function()
    local a,b=quest(1),quest(2)
    local independent=T.Build({a,b},state())
    a.tasks={{label="Spiders",target=a.objective,minutes=4,combatKey="spiders"}}
    b.tasks={{label="Spider loot",target=b.objective,minutes=3,combatKey="spiders"}}
    local shared=T.Build({a,b},state())
    assert(math.abs(independent.minutes-shared.minutes-4)<.001)
    b.tasks[1].combatKey="boars"
    assert(T.Build({a,b},state()).minutes>shared.minutes+2.9)
end)
test("multi-area gathering preserves all unfinished areas",function()
    local q=quest(1)
    q.tasks={{label="Mushrooms",match="mushroom",target={x=.57,y=.39},minutes=2},
        {label="Lilies",match="lily",target={x=.57,y=.36},minutes=2},
        {label="Spiders",match="ichor",target={x=.57,y=.30},minutes=2}}
    local s=state(); s.log[1]={objectives={{text="Mushroom: 7/7",finished=true},{text="Lily: 1/4",numFulfilled=1,numRequired=4},{text="Ichor: 0/1",numRequired=1}}}
    local trip=T.Build({q},s)
    local labels={}
    for _,step in ipairs(trip.steps) do for _,m in ipairs(step.members) do labels[m.label or ""]=true end end
    assert(not labels.Mushrooms and labels.Lilies and labels.Spiders)
    assert(T.Progress(q,q.tasks[2],s.log[1])==.25)
end)
test("unknown objective language does not complete a task",function()
    local q=quest(1); q.tasks={{match="mushroom",target=q.objective}}
    local progress,known=T.Progress(q,q.tasks[1],{objectives={{text="Unmatched objective",finished=true}}})
    assert(progress==0 and not known)
end)
test("client completion is required before a live turn-in instruction",function()
    local q=quest(1); q.tasks={{match="test",target=q.objective}}
    local s=state(); s.log[1]={objectives={{text="test",finished=true}}}
    local route=T.Plan({q},s)
    assert(route[1].action=="DO" and route[1].members[1].label:find("Check remaining"))
    s.log[1].complete=true
    assert(T.Plan({q},s)[1].action=="TURN IN")
end)
test("completed quest skips objective work and returns once",function()
    local s=state(); s.log[1]={complete=true}
    local trip=T.Build({quest(1)},s)
    assert(#trip.steps==1 and trip.steps[1].action=="TURN IN" and trip.xp==300)
end)
test("partial progress reduces trip time",function()
    local a,b=state(),state(); a.log[1]={progress=0}; b.log[1]={progress=.75}
    assert(T.Build({quest(1)},b).minutes<T.Build({quest(1)},a).minutes-2.9)
end)
test("prerequisites remain locked until a projected return",function()
    local a,b=quest(1),quest(2); b.all={1}
    local route,trips=T.Plan({a,b},state())
    assert(memberIndex(route,1,"TURN IN")<memberIndex(route,2,"PICK UP"))
    assert(route[1].id==1)
end)
test("valuable chain unlocks can be included in the same trip",function()
    local a,b=quest(1),quest(2); a.xp=30; a.minutes=.2; b.all={1}; b.xp=500
    local trip=T.Choose({a,b},state())
    assert(#trip.quests==2)
    assert(memberIndex(trip.steps,1,"TURN IN")<memberIndex(trip.steps,2,"PICK UP"))
end)
test("skipped, failed and completed quests are excluded",function()
    local s=state(); s.done[1]=true; s.skip[2]=true; s.log[3]={failed=true}
    assert(#T.Plan({quest(1),quest(2),quest(3)},s)==0)
end)
test("accepted timed quest interrupts elective batching and pinning",function()
    local a,b=quest(1),quest(2); b.timed=true
    local s=state(); s.log[2]={}; s.pin=1
    local trip=T.Choose({a,b},s)
    assert(trip.urgent and #trip.quests==1 and trip.ids[1]==2)
end)
test("timed pickups do not include optional detours",function()
    local a,b=quest(1),quest(2); b.timed=true
    local s=state(); s.pin=2
    local trip=T.Choose({a,b},s)
    assert(#trip.quests==1 and trip.ids[1]==2)
end)
test("full quest log plans a return before a new pickup",function()
    local a,b=quest(1),quest(2); local s=state()
    s.log[1]={complete=true}; s.freeSlots=0
    local route=T.Plan({a,b},s)
    assert(route[1].action=="TURN IN" and memberIndex(route,2,"PICK UP")>1)
end)
test("pinning cannot bypass a prerequisite or skip",function()
    local a,b=quest(1),quest(2); b.all={1}; local s=state(); s.pin=2
    assert(T.Plan({a,b},s)[1].id==1)
    s.skip[2]=true
    local _,trips=T.Plan({a,b},s)
    assert(#trips==1)
end)
test("far low-value quests are not added merely because they exist",function()
    local a,b=quest(1),quest(2,{x=.1,y=.1}); b.xp=1; b.start={x=.1,y=.1}; b.finish=b.start
    local trip=T.Choose({a,b},state())
    assert(#trip.quests==1 and trip.ids[1]==1)
end)
test("whole-trip gear allowance respects zero budget",function()
    local a,b=quest(1),quest(2,{x=.2,y=.2}); b.start=b.objective; b.finish=b.objective; b.gear=1
    local s=state(); s.mode="balanced"; s.budget=0
    assert(T.Choose({a,b},s).ids[1]==1)
    s.pin=2; assert(T.Choose({a,b},s).ids[1]==2)
end)
test("XP and balanced modes make different bounded gear choices",function()
    local a,b=quest(1),quest(2); a.timed=true; b.timed=true; b.minutes=5; b.gear=1
    local s=state()
    assert(T.Choose({a,b},s).ids[1]==1)
    s.mode="balanced"; assert(T.Choose({a,b},s).ids[1]==2)
    s.budget=0; assert(T.Choose({a,b},s).ids[1]==1)
end)
test("known chain reward can favor its prerequisite within trip allowance",function()
    local a,b,c=quest(1),quest(2),quest(3)
    a.timed=true; b.timed=true; b.xp=280; c.all={2}; c.gear=1; c.minutes=1
    local s=state(); assert(T.Choose({a,b,c},s).ids[1]==1)
    s.mode="balanced"; assert(T.Choose({a,b,c},s).ids[1]==2)
    s.budget=0; assert(T.Choose({a,b,c},s).ids[1]==1)
end)
test("an early nearby return can unlock the next projected quest",function()
    local a,b,c=quest(1),quest(2),quest(3); c.all={1}
    local s=state(); s.log[1]={complete=true}; s.log[2]={}
    local route=T.Plan({a,b,c},s)
    assert(route[1].action=="TURN IN" and route[1].id==1)
    assert(memberIndex(route,3,"PICK UP")>memberIndex(route,1,"TURN IN"))
end)
test("a near-tie retains the preceding trip",function()
    local a,b=quest(1),quest(2); a.timed=true; b.timed=true; b.xp=310
    local s=state(); s.previous={tripKey="1",nextKey="1:pickup"}
    assert(T.Choose({a,b},s).ids[1]==1)
    b.xp=1000; assert(T.Choose({a,b},s).ids[1]==2)
end)
test("planner is deterministic, bounded and does not mutate the snapshot",function()
    local s=state(); local qs={quest(1),quest(2)}
    local a=T.Plan(qs,s,2); local b=T.Plan(qs,s,2)
    assert(#a==2 and #b==2 and a[1].key==b[1].key)
    assert(next(s.log)==nil and next(s.done)==nil and s.pos==hub)
end)
test("invalid coordinates suppress unusable quest candidates",function()
    local q=quest(1); q.objective=nil
    assert(T.Choose({q},state())==nil)
end)
test("Shadowglen pack combines antidote spider work with venom",function()
    local quests={}
    for _,q in ipairs(Q.Pack.quests) do if q.id==916 or q.id==3521 then quests[#quests+1]=q end end
    local s=state(); s.log[916]={}; s.log[3521]={}; s.pos={x=.575,y=.328}
    local trip=T.Build(quests,s)
    assert(#trip.steps[1].members==2 and trip.steps[1].action=="DO")
end)
test("abandoning a quest schedules its pickup again",function()
    local q=quest(1); local s=state(); s.log[1]={progress=.5}
    assert(T.Plan({q},s)[1].action=="DO")
    s.log[1]=nil; assert(T.Plan({q},s)[1].action=="PICK UP")
end)

-- A small deterministic benchmark gives an order-of-magnitude regression signal.
test("Shadowglen planning remains bounded under repeated updates",function()
    local s=state(); local start=os.clock()
    for _=1,20 do T.Plan(Q.Pack.quests,s) end
    local elapsed=os.clock()-start
    print(string.format("BENCHMARK 20 Shadowglen plans: %.3f sec",elapsed))
    assert(elapsed<10)
end)
