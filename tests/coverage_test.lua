local Q,test=...
local savedAPI,savedGossip,savedOpen=C_QuestLog,C_GossipInfo,Q.Runtime.gossipOpen
local function state()
    return {level=5,raceID=4,pos={x=.578,y=.417},done={},log={},skip={},itemStarts={},offered={},mode="xp",budget=10}
end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function provider(s) return Q.Provider.Quests(s,{rewards={},profile="melee"}) end

test("new local quests require actual NPC offer before recommending pickup",function()
    local s=state();local qs=provider(s)
    assert(not Q.Core.Eligible(find(qs,97977),s) and not Q.Core.Eligible(find(qs,97979),s))
    s.offered[97977]=true
    local nature=find(provider(s),97977)
    assert(Q.Core.Eligible(nature,s) and nature.pendingAction=="PICK UP" and nature.stageOnly)
    local route,trips=Q.Trips.Plan({nature},s)
    assert(#route==1 and route[1].action=="PICK UP" and not trips[1].completed[97977])
    assert(not nature.objective and route[1].target.x==.577)
end)
test("accepted Nature uses live totem area without making the totem a starter",function()
    local s=state();s.log[97977]={location={x=.55,y=.411},progress=.5}
    local nature=find(provider(s),97977)
    assert(nature.objective.x==.55 and not nature.itemStartID and not nature.pendingAction)
    assert(not nature.stageOnly and Q.Trips.Plan({nature},s)[1].action=="DO")
    s.log[97977].complete=true;s.log[97977].location={x=.577,y=.451};s.pos=s.log[97977].location
    local route,trips=Q.Trips.Plan({find(provider(s),97977)},s)
    assert(route[1].action=="TURN IN" and trips[1].nearbyReturns)
end)
test("new quests without live objectives explain missing location rather than inventing it",function()
    local s=state();s.log[97977]={}
    local qs,notices=provider(s)
    assert(#Q.Trips.Plan({find(qs,97977)},s)==0 and #notices==1)
    s.log[97977].complete=true
    assert(Q.Trips.Plan({find(provider(s),97977)},s)[1].action=="TURN IN")
end)
test("Goddess racial gate does not invent a priest restriction",function()
    local s=state();s.offered[97979]=true;s.classID=1
    assert(Q.Core.Eligible(find(provider(s),97979),s))
    s.raceID=1;assert(not Q.Core.Eligible(find(provider(s),97979),s))
    s.log[97979]={location={x=.592,y=.405}}
    assert(Q.Core.Eligible(find(provider(s),97979),s))
end)
test("voucher never becomes an unowned farming opportunity",function()
    local s=state();s.pos={x=.588,y=.443}
    local q=find(provider(s),5842)
    assert(q.itemStartID==14648 and not Q.Core.Eligible(q,s))
    s.itemStarts[5842]={itemID=14648,name="Shadowglen Gift Voucher"}
    q=find(provider(s),5842)
    local route=Q.Trips.Plan({q},s)
    assert(#route==1 and route[1].action=="ACCEPT ITEM" and not Q.Navigation.Destination(route[1]))
    s.itemStarts={};s.log[5842]={complete=true,location={x=.588,y=.443}}
    q=find(provider(s),5842)
    assert(not q.stageOnly and Q.Trips.Plan({q},s)[1].action=="TURN IN")
end)
test("ready-for-turnin API recognizes item delivery even when IsComplete is false",function()
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=97236,title="Fang of Githyiss"} end,
        IsComplete=function() return false end,ReadyForTurnIn=function(id) assert(id==97236);return true end,
        GetNextWaypoint=function() return 1438,.578,.417 end}
    local s=Q.Runtime.Snapshot();s.pos={x=.578,y=.417}
    assert(s.log[97236].complete)
    local route,trips=Q.Trips.Plan({find(provider(s),97236)},s)
    assert(route[1].action=="TURN IN" and trips[1].nearbyReturns)
end)
test("negative or missing readiness never comes from proximity or finished rows",function()
    C_QuestLog.IsComplete=function() return true end
    C_QuestLog.ReadyForTurnIn=function() return false end
    assert(not Q.Runtime.Snapshot().log[97236].complete)
    C_QuestLog.ReadyForTurnIn=function() error("unsupported") end
    assert(Q.Runtime.Snapshot().log[97236].complete)
    C_QuestLog.IsComplete=function() return false end
    C_QuestLog.GetQuestObjectives=function() return {{finished=true,numRequired=1}} end
    assert(not Q.Runtime.Snapshot().log[97236].complete)
end)
test("NPC offers are guarded and not reused after interaction closes",function()
    C_GossipInfo={GetAvailableQuests=function() return {{questID=97977},{questID=97979}} end}
    Q.Runtime.gossipOpen=true
    local s=Q.Runtime.Snapshot()
    assert(s.offered[97977] and s.offered[97979])
    Q.Runtime.gossipOpen=false;assert(next(Q.Runtime.Snapshot().offered)==nil)
    Q.Runtime.gossipOpen=true;C_GossipInfo.GetAvailableQuests=function() error("unsupported") end
    assert(next(Q.Runtime.Snapshot().offered)==nil)
end)
C_QuestLog,C_GossipInfo,Q.Runtime.gossipOpen=savedAPI,savedGossip,savedOpen
