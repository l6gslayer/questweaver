local Q,test=...
local C,T=Q.Core,Q.Trips
local function fixture()
    local s={map=Q.Pack.mapID,level=8,pos={x=.58,y=.70},mode="balanced",budget=10,
        done={},skip={},log={[93001]={progress=.5,progressKnown=true},[93002]={progress=.25,progressKnown=true}}}
    local qs={}
    for _,id in ipairs({93001,93002}) do
        qs[#qs+1]={id=id,name="Field task "..id,level=8,minLevel=1,xp=600,minutes=5,
            start={x=.60,y=.70},objective={x=.58,y=.70},stageOnly=true,acceptedOnly=true}
    end
    local trip=T.Build(qs,s)
    assert(#trip.steps[1].members==2)
    s.outing=T.RetainOuting(nil,s,trip.steps)
    return s,qs
end
local function index(route,id,action)
    for i,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and m.action==action then return i end end end
end
local function ready(s,qs)
    s.log[93001].complete=true
    qs[1].stageOnly=false;qs[1].finish={x=.63,y=.70}
    s.previous={tripKey="93001",nextKey="93001:return"}
end

test("outing retains actual grouped accepted work through singleton replans",function()
    local s,qs=fixture();assert(s.outing and #s.outing.ids==2)
    local singleton=T.Build({qs[1]},s)
    for _=1,4 do s.outing=T.RetainOuting(s.outing,s,singleton.steps);assert(#s.outing.ids==2) end
    ready(s,qs)
    local route,trips=T.Plan(qs,s)
    assert(trips[1].fieldContinuation and index(route,93002,"DO")<index(route,93001,"TURN IN"))
    assert(not trips[1].completed[93002] and not index(route,93002,"TURN IN"))
end)
test("retained outing continues quarter-complete work within six-minute bound",function()
    local s,qs=fixture();ready(s,qs)
    qs[2].minutes=8 -- six estimated minutes remain
    assert(T.Choose(qs,s).fieldContinuation)
    qs[2].minutes=9;assert(not T.Choose(qs,s).fieldContinuation)
    qs[2].minutes=5;s.log[93002].progress=0
    assert(T.Choose(qs,s).fieldContinuation)
    s.log[93002].progressKnown=false;assert(not T.Choose(qs,s).fieldContinuation)
end)
test("retained work with known shared recipient still precedes all returns",function()
    local s,qs=fixture();ready(s,qs)
    qs[2].stageOnly=false;qs[2].finish=C.Copy(qs[1].finish)
    local route,trips=T.Plan(qs,s)
    assert(trips[1].fieldContinuation)
    assert(index(route,93002,"DO")<index(route,93001,"TURN IN"))
    assert(index(route,93002,"DO")<index(route,93002,"TURN IN"))
end)
test("outing context survives saved-value copy and excludes unrelated accepted work",function()
    local s,qs=fixture();s.outing=C.Copy(s.outing);s.previous=nil;ready(s,qs);s.previous=nil
    assert(T.Choose(qs,s).fieldContinuation)
    s.outing.ids={93001,93003};s.log[93003]={progress=.2,progressKnown=true}
    assert(not T.Choose(qs,s).fieldContinuation)
end)
test("outing context prunes removals skips failures and stale map area",function()
    for _,edit in ipairs({
        function(s) s.log[93002]=nil end,
        function(s) s.skip[93002]=true end,
        function(s) s.done[93002]=true end,
        function(s) s.log[93002].failed=true end,
        function(s) s.map=999 end,
        function(s) s.pos={x=.2,y=.2} end,
        function(s) s.outing.center={x=0/0,y=.5} end}) do
        local s=fixture();edit(s);assert(not T.RetainOuting(s.outing,s))
    end
    local s=fixture();s.outing.ids={93001,93001,"bad",93002,93003}
    assert(T.RetainOuting(s.outing,s) and #T.RetainOuting(s.outing,s).ids==2)
    assert(not T.RetainOuting({map=s.map,center=s.pos,ids={}},s))
end)
test("retained outing respects nearby returns timed deliveries pins and task distance",function()
    local s,qs=fixture();ready(s,qs);s.pos=C.Copy(qs[1].finish)
    assert(T.Choose(qs,s).nearbyReturns)
    s,qs=fixture();ready(s,qs);qs[1].timed=true;assert(T.Choose(qs,s).urgent)
    s,qs=fixture();ready(s,qs);s.pin=93003;assert(not T.Choose(qs,s).fieldContinuation)
    s,qs=fixture();ready(s,qs);qs[2].objective={x=.48,y=.70}
    assert(not T.Choose(qs,s).fieldContinuation)
end)
test("unaccepted forecast work cannot establish an outing",function()
    local s,qs=fixture();s.outing=nil;s.log[93002]=nil
    local route={{action="DO",target=qs[1].objective,members={{id=93001},{id=93002}}}}
    assert(not T.RetainOuting(nil,s,route))
end)
test("runtime saves and reloads numeric outing context before singleton return choice",function()
    local oldMap,oldAPI,oldLevel,oldFaction=C_Map,C_QuestLog,UnitLevel,UnitFactionGroup
    local oldUI,oldSync,oldWorld=Q.UI,Q.Navigation.Sync,Q.inWorld
    local oldOuting,oldPrevious,oldSkip=Q.db.outing,Q.previous,Q.db.skip
    Q.db.outing=nil;Q.db.skip={};Q.previous=nil;Q.UI=nil;Q.Navigation.Sync=function() end;Q.inWorld=true
    UnitLevel=function() return 8 end;UnitFactionGroup=function() return "Alliance" end
    C_Map={GetBestMapForUnit=function() return Q.Pack.mapID end,
        GetPlayerMapPosition=function() return {x=.58,y=.70} end}
    local completed=false
    C_QuestLog={GetNumQuestLogEntries=function() return 2 end,
        GetInfo=function(i) return {questID=93000+i,title="Field task",level=8} end,
        GetQuestObjectives=function(id) return {{numFulfilled=id==93001 and 2 or 1,numRequired=4}} end,
        ReadyForTurnIn=function(id) return completed and id==93001 end,
        GetNextWaypoint=function(id)
            if completed and id==93001 then return Q.Pack.mapID,.63,.70 end
            return Q.Pack.mapID,.58,.70
        end}
    Q.Runtime.Refresh();assert(Q.db.outing and #Q.db.outing.ids==2)
    Q.db.outing=C.Copy(Q.db.outing);Q.previous=nil -- saved-value restore across reload
    completed=true
    assert(Q.Runtime.Snapshot().outing and #Q.Runtime.Snapshot().outing.ids==2)
    Q.Runtime.Refresh();assert(Q.route[1].action=="DO" and Q.route[1].id==93002)
    Q.db.skip[93002]=true;Q.Runtime.Refresh();assert(not Q.db.outing)
    C_Map,C_QuestLog,UnitLevel,UnitFactionGroup=oldMap,oldAPI,oldLevel,oldFaction
    Q.UI,Q.Navigation.Sync,Q.inWorld=oldUI,oldSync,oldWorld
    Q.db.outing,Q.previous,Q.db.skip=oldOuting,oldPrevious,oldSkip
end)
