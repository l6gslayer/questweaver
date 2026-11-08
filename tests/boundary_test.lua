local Q,test=...
local C,P,T=Q.Core,Q.Provider,Q.Trips
local savedDB,savedNpc=QuestDB,NpcDB
QuestDB=nil;NpcDB=nil
local function state()
    return {map=Q.Pack.mapID,level=7,classID=3,raceID=4,pos={x=.55,y=.67},
        log={},done={},skip={},mode="xp",budget=10,itemStarts={}}
end
local function provider(s) return P.Quests(s,{rewards={},profile="melee"}) end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end

test("accepted objectives and returns continue beyond both corridor edges",function()
    for _,pos in ipairs({{x=.55,y=.68},{x=.68,y=.60},{x=.44,y=.58}}) do
        local s=state();s.pos=C.Copy(pos)
        s.log[90001]={progress=.7,location=C.Copy(pos)}
        local q=find(provider(s),90001)
        assert(q and q.stageOnly and not q.finish)
        local route=T.Plan({q},s)
        assert(route[1].action=="DO" and route[1].target.x==pos.x)
        s.log[90001]={complete=true,location=C.Copy(pos)}
        q=find(provider(s),90001);route=T.Plan({q},s)
        assert(route[1].action=="TURN IN" and q.finish.y==pos.y)
    end
end)
test("outside corridor does not unlock authored pickups or item starts",function()
    local s=state();s.itemStarts[90002]={location={x=.58,y=.44},name="Starter"}
    local qs=provider(s)
    for _,q in ipairs(qs) do if not q.catalogue then assert(not C.Eligible(q,s)) end end
    s.log[457]={progress=.5,location={x=.61,y=.69}}
    assert(C.Eligible(find(provider(s),457),s))
    s.skip[457]=true;assert(not C.Eligible(find(provider(s),457),s))
end)
test("accepted discovery rejects foreign map and invalid points",function()
    local s=state();s.map=999;s.log[90001]={location={x=.55,y=.68}}
    assert(not find(provider(s),90001))
    s.map=Q.Pack.mapID
    for _,pos in ipairs({{x=0,y=0},{x=0/0,y=.5},{x=math.huge,y=.5},{x=-.1,y=.5}}) do
        s.log[90001].location=pos;assert(not find(provider(s),90001))
    end
end)
test("runtime keeps accepted guidance outside corridor and clears wrong-map route",function()
    local savedSnapshot,savedUI,savedSync=Q.Runtime.Snapshot,Q.UI,Q.Navigation.Sync
    local savedFaction,savedWorld=UnitFactionGroup,Q.inWorld
    local s=state();s.log[90001]={progress=.5,location={x=.55,y=.69}}
    for _,q in ipairs(Q.Pack.quests) do if q.catalogue then s.skip[q.id]=true end end
    Q.Runtime.Snapshot=function() return s end
    UnitFactionGroup=function() return "Alliance" end
    Q.UI=nil;Q.inWorld=true
    local nextStep
    Q.Navigation.Sync=function(step) nextStep=step end
    Q.Runtime.Refresh()
    assert(#Q.route>0 and nextStep and nextStep.target.y==.69)
    s.map=999;Q.Runtime.Refresh();assert(#Q.route==0 and not nextStep)
    s.map=Q.Pack.mapID;s.pos={x=0/0,y=.5}
    Q.Runtime.Refresh();assert(#Q.route==0 and not nextStep)
    Q.Runtime.Snapshot=savedSnapshot;Q.UI=savedUI;Q.Navigation.Sync=savedSync
    UnitFactionGroup=savedFaction;Q.inWorld=savedWorld
end)
QuestDB=savedDB;NpcDB=savedNpc
