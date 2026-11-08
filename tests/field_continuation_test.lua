local Q,test=...
local T,C=Q.Trips,Q.Core
local function fixture()
    local s={level=7,pos={x=.58,y=.58},done={},skip={},mode="xp",budget=10,
        previous={tripKey="92001,92002",nextKey="92001:task:1"},
        log={[92001]={complete=true},[92002]={progress=.8,progressKnown=true}}}
    local qs={{id=92001,name="Ready field quest",level=7,minLevel=1,xp=400,minutes=5,
        start={x=.60,y=.55},objective={x=.60,y=.59},finish={x=.60,y=.55}},
        {id=92002,name="Accepted field companion",level=7,minLevel=1,xp=600,minutes=5,
        start={x=.60,y=.55},objective={x=.60,y=.59},stageOnly=true,acceptedOnly=true}}
    return s,qs
end
local function member(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return i end end end
end

test("previous grouped unknown-return work finishes before elective field departure",function()
    local s,qs=fixture()
    local route,trips=T.Plan(qs,s)
    assert(trips[1].fieldContinuation and #trips[1].quests==2)
    assert(member(route,92002,"DO")<member(route,92001,"TURN IN"))
    assert(not member(route,92002,"TURN IN") and not trips[1].completed[92002])
    assert(trips[1].stageOnly and #trips==1)
    assert(not qs[1].fieldContinuation and not qs[2].fieldCompanion and not s.done[92001])
end)
test("field continuation persists across repeated planner refreshes",function()
    local s,qs=fixture()
    for _=1,4 do
        local route,trips=T.Plan(qs,s)
        assert(trips[1].fieldContinuation and route[1].action=="DO")
        s.previous={tripKey=route[1].tripKey,nextKey=route[1].key}
    end
end)
test("field continuation preserves near-ready and timed priorities",function()
    local s,qs=fixture();s.pos=C.Copy(qs[1].finish)
    assert(T.Choose(qs,s).nearbyReturns)
    s,qs=fixture();qs[1].timed=true
    assert(T.Choose(qs,s).urgent)
end)
test("field continuation needs previous grouping and respects an outside pin",function()
    local s,qs=fixture();s.previous=nil
    assert(not T.Choose(qs,s).fieldContinuation)
    s,qs=fixture();s.previous.tripKey="92001"
    assert(not T.Choose(qs,s).fieldContinuation)
    s,qs=fixture();s.pin=92003
    qs[3]={id=92003,name="Pinned",level=7,minLevel=1,xp=100,minutes=1,
        start=C.Copy(s.pos),objective=C.Copy(s.pos),finish={x=.64,y=.60}}
    assert(not T.Choose(qs,s).fieldContinuation)
end)
test("field continuation excludes remote risky excessive and unresolved work",function()
    for _,edit in ipairs({
        function(s,qs) qs[2].objective={x=.4,y=.4} end,
        function(s,qs) qs[2].risk=.1 end,
        function(s,qs) qs[2].level=10 end,
        function(s,qs) qs[2].minutes=30 end,
        function(s,qs) s.log[92002].progressKnown=false end,
        function(s,qs) s.log[92002].progress=1 end,
        function(s,qs) s.log[92002].progress=.2 end,
        function(s,qs) s.log[92002].failed=true end,
        function(s,qs) s.skip[92002]=true end,
        function(s,qs) s.log[92002]=nil end}) do
        local s,qs=fixture();edit(s,qs)
        assert(not T.Choose(qs,s).fieldContinuation)
    end
end)
test("ready companion adopts observed recipient without fabricated field completion",function()
    local s,qs=fixture();s.log[92002].complete=true
    qs[2].stageOnly=false;qs[2].finish={x=.59,y=.55}
    local route,trips=T.Plan(qs,s)
    assert(not trips[1].fieldContinuation and member(route,92002,"TURN IN"))
end)
