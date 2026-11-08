local Q,test=...
local saved=C_QuestLog
local R=Q.Runtime
local function state(log)
    return {level=3,pos={x=.588,y=.443},done={[456]=true},log=log or {},skip={},mode="xp",budget=10}
end
local function quests(log)
    return Q.Provider.Quests(state(log),{rewards={},profile="melee"})
end
local function find(list,id)
    for _,q in ipairs(list) do if q.id==id then return q end end
end

test("current waypoint wins over map area without changing tracked quest",function()
    C_QuestLog={GetNextWaypoint=function(id) assert(id==457); return 1438,.61,.36 end,
        GetNextWaypointForMap=function() error("should not need fallback") end}
    local p=R.QuestLocation(457,1438,{{questID=457,x=.62,y=.37}})
    assert(p.x==.61 and p.y==.36 and p.source=="WoW objective")
end)
test("map-specific waypoint uses requested coordinate space",function()
    C_QuestLog={GetNextWaypoint=function() return 999,.1,.2 end,
        GetNextWaypointForMap=function(id,map) assert(id==457 and map==1438); return .60,.35 end}
    assert(R.QuestLocation(457,1438).x==.60)
end)
test("quest map area supplies fallback when waypoint APIs unavailable",function()
    C_QuestLog={}
    local p=R.QuestLocation(457,1438,{{questID=456,x=.1,y=.2},{questID=457,x=.61,y=.36}})
    assert(p.x==.61 and p.source=="WoW quest area")
end)
test("invalid foreign and failing APIs degrade to matching map area",function()
    C_QuestLog={GetNextWaypoint=function() return 999,.5,.5 end,
        GetNextWaypointForMap=function() error("unavailable") end}
    assert(not R.QuestLocation(457,1438,{{questID=456,x=.5,y=.5}}))
    for _,v in ipairs({-1,2,math.huge,0/0,".6"}) do
        C_QuestLog.GetNextWaypoint=function() return 1438,v,.4 end
        assert(R.QuestLocation(457,1438,{{questID=457,x=.61,y=.36}}).x==.61)
    end
    C_QuestLog.GetNextWaypoint=function() return 1438,0,0 end
    assert(not R.QuestLocation(457,1438))
    assert(not R.QuestLocation(457,1438,"bad data"))
end)
test("live Nightsaber location drives planned step and TomTom destination",function()
    local log={[457]={progress=12/14,progressKnown=true,location={x=.61,y=.36,source="WoW objective"}}}
    local q=find(quests(log),457)
    local route=Q.Trips.Plan({q},state(log),3)
    assert(route[1].action=="DO" and route[1].target.x==.61)
    local dest=Q.Navigation.Destination(route[1])
    assert(dest.map==1438 and dest.x==.61 and dest.y==.36)
    log[457].location={x=.62,y=.37,source="WoW objective"}
    local changed=Q.Trips.Plan({find(quests(log),457)},state(log),3)
    assert(Q.Navigation.Destination(changed[1]).key~=dest.key)
end)
test("live quest stage does not duplicate gathering tasks or mutate seeds",function()
    local q=find(quests({[3521]={location={x=.61,y=.36}}}),3521)
    assert(not q.tasks and q.objective.x==.61)
    assert(#find(Q.Pack.quests,3521).tasks==3)
    assert(#find(quests({}),3521).tasks==3)
end)
test("completed quest location changes return only and forecast uses seeds",function()
    local q=find(quests({[457]={complete=true,location={x=.60,y=.44}}}),457)
    assert(q.finish.x==.60 and q.objective.x==.579)
    local seed=find(quests({}),457)
    assert(seed.objective.x==.579 and seed.finish.x==.588)
end)
test("missing live data and failed quests preserve starter locations",function()
    assert(find(quests({[457]={progress=.85}}),457).objective.x==.579)
    assert(find(quests({[457]={failed=true,location={x=.61,y=.36}}}),457).objective.x==.579)
end)
test("snapshot reads map POIs once and refreshes current quest locations",function()
    local reads=0
    C_QuestLog={GetQuestsOnMap=function(map) assert(map==1438); reads=reads+1; return {{questID=457,x=.61,y=.36}} end,
        GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=457} end,
        GetQuestObjectives=function() return {{numFulfilled=5,numRequired=7},{finished=true,numRequired=7}} end}
    local s=R.Snapshot()
    assert(reads==1 and s.log[457].location.x==.61 and s.log[457].progress==12/14)
    C_QuestLog.GetQuestsOnMap=function() return nil end
    assert(not R.Snapshot().log[457].location)
end)
C_QuestLog=saved
