local Q,test=...
local Z,C,R,N=Q.Catalogues,Q.Core,Q.Runtime,Q.Navigation
local originalPack=Q.Pack
local originalTeldrassil,originalDarkshore=Z.packs[1438],Z.packs[1439]
local originalMap,originalAPI,originalDB,originalNpc=C_Map,C_QuestLog,QuestDB,NpcDB
local originalTomTom,originalCurrent,originalError=TomTom,N.current,N.error
local originalUI,originalWorld,originalPrevious=Q.UI,Q.inWorld,Q.previous
local originalOuting,originalAuto=Q.db.outing,Q.db.autoWaypoint
local originalFaction=UnitFactionGroup
local originalRoute,originalTrips,originalState=Q.route,Q.trips,Q.state
local originalDetail,originalOpen,originalGossipMap=R.detailOffer,R.gossipOpen,R.gossipMap
N.current=nil;N.error=nil
local function fixture(map,area,id)
    local p={x=.4,y=.4}
    return {mapID=map,areaID=area,name="Zone fixture",faction="Alliance",
        bounds={minX=0,maxX=1,minY=0,maxY=1},quests={{id=id,name="Zone task",
            minLevel=1,level=5,xp=200,minutes=2,start=C.Copy(p),objective=C.Copy(p),finish=C.Copy(p)}}}
end
local teldrassil=fixture(1438,141,991001)
local darkshore=fixture(1439,148,991002)
Z.packs[1438]=teldrassil;Z.packs[1439]=darkshore
local function state(map)
    return {map=map,level=10,classID=3,raceID=4,pos={x=.4,y=.4},done={},log={},
        offered={},skip={},itemStarts={},mode="balanced",budget=10}
end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function step()
    return {id=991010,key="991010:task:1",action="DO",name="Zone objective",target={x=.4,y=.4},
        members={{id=991010,action="DO",quest={id=991010,name="Zone objective"}}}}
end
local function spy()
    local result={added={},removed={},other={}}
    function result:AddWaypoint(map,x,y)
        local uid={};self.added[#self.added+1]={map=map,x=x,y=y,uid=uid};return uid
    end
    function result:RemoveWaypoint(uid)
        assert(uid~=self.other);self.removed[#self.removed+1]=uid
    end
    return result
end

test("zone registry selects supported packs and leaves unknown maps unselected",function()
    local extra=fixture(999998,999997,991009)
    Z.Register(extra);assert(Z.packs[999998]==extra)
    assert(Z.Select(1438)==teldrassil and Q.Pack==teldrassil)
    assert(Z.Select(1439)==darkshore and Q.Pack==darkshore)
    assert(Z.Select(999999)==nil and Q.Pack==darkshore)
    Z.packs[999998]=nil
end)
test("provider optional spawn lookup uses active area rather than Teldrassil coordinates",function()
    QuestDB={Get=function(id,key)
        if id==991003 and key=="finishedBy" then return {{123}} end
    end}
    NpcDB={Get=function(id,key)
        if id==123 and key=="spawns" then return {[141]={{11,12}},[148]={{42,43}}} end
    end}
    Z.Select(1439)
    local s=state(1439);s.log[991003]={location={x=.5,y=.5},progress=.2}
    local q=find(Q.Provider.Quests(s,{rewards={},profile="ranged"}),991003)
    assert(q and q.finish.x==.42 and q.finish.y==.43)
    Z.Select(1438);s.map=1438
    q=find(Q.Provider.Quests(s,{rewards={},profile="ranged"}),991003)
    assert(q and q.finish.x==.11 and q.finish.y==.12)
    QuestDB=nil;NpcDB=nil
end)
test("snapshot changes active catalogue before reading map objectives",function()
    local map=1439;local reads={}
    C_Map={GetBestMapForUnit=function() return map end,
        GetPlayerMapPosition=function(requested) assert(requested==map);return {x=.4,y=.4} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=991003,title="Accepted zone task"} end,
        GetQuestsOnMap=function(requested) reads[#reads+1]=requested;assert(requested==map);return {} end,
        GetNextWaypoint=function() return map,.6,.7 end,
        GetQuestObjectives=function() return {{numFulfilled=1,numRequired=4}} end}
    Z.Select(1438)
    local s=R.Snapshot()
    assert(Q.Pack==darkshore and s.map==1439 and s.log[991003].location.x==.6)
    map=1438;s=R.Snapshot()
    assert(Q.Pack==teldrassil and s.map==1438 and s.log[991003].location.y==.7)
    assert(reads[1]==1439 and reads[2]==1438)
end)
test("snapshot checks prerequisites whose quests live in another catalogue",function()
    local checked={}
    darkshore.quests[1].all={991100};darkshore.quests[1].any={991101}
    C_Map={GetBestMapForUnit=function() return 1439 end,
        GetPlayerMapPosition=function() return {x=.4,y=.4} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() end,
        IsQuestFlaggedCompleted=function(id) checked[id]=true;return id==991100 end}
    local s=R.Snapshot()
    assert(checked[991100] and checked[991101] and s.done[991100])
    darkshore.quests[1].all=nil;darkshore.quests[1].any=nil
end)
test("zone waypoint change removes only owned old-map point even with identical coordinates",function()
    N.current=nil;N.error=nil;Q.db.autoWaypoint=true
    local tt=spy();TomTom=tt
    Z.Select(1438);N.Sync(step());local old=N.current.uid
    Z.Select(1439);N.Sync(step())
    assert(#tt.added==2 and tt.added[1].map==1438 and tt.added[2].map==1439)
    assert(#tt.removed==1 and tt.removed[1]==old and N.current.uid~=old)
    N.Clear()
end)
test("retained field outing cannot transfer coordinate context between catalogues",function()
    local s=state(1439);s.log[991001]={progress=.5};s.log[991002]={progress=.25}
    local old={map=1438,center={x=.4,y=.4},ids={991001,991002}}
    Z.Select(1439);assert(not Q.Trips.RetainOuting(old,s))
    old.map=1439;assert(Q.Trips.RetainOuting(old,s))
end)
test("unsupported runtime zone clears route and owned arrow without falling back to another catalogue",function()
    local map=1439
    C_Map={GetBestMapForUnit=function() return map end,
        GetPlayerMapPosition=function() return {x=.4,y=.4} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=991002,title="Ready zone task"} end,
        ReadyForTurnIn=function() return true end,
        GetNextWaypoint=function() return map,.4,.4 end}
    UnitFactionGroup=function() return "Alliance" end
    QuestDB=nil;NpcDB=nil;Q.UI=nil;Q.inWorld=true;Q.db.autoWaypoint=true
    N.current=nil;local tt=spy();TomTom=tt
    R.Refresh();assert(#Q.route>0 and Q.Pack==darkshore and N.current)
    Q.db.outing={map=1439,center={x=.4,y=.4},ids={991001,991002}}
    map=999999;R.Refresh()
    assert(#Q.route==0 and not N.current and not Q.db.outing)
    assert(Q.Pack==darkshore and #tt.removed>=1)
end)

test("first interaction after zone entry retains only the new map offer",function()
    local oldID,oldTitle,oldGossip,oldCapture=GetQuestID,GetTitleText,C_GossipInfo,Q.Gear.Capture
    C_Map={GetBestMapForUnit=function() return 1439 end,
        GetPlayerMapPosition=function() return {x=.4,y=.4} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() end}
    UnitFactionGroup=function() return "Alliance" end
    Q.UI=nil;Q.inWorld=true;Q.Gear.Capture=function() end
    GetQuestID=function() return 991020 end;GetTitleText=function() return "Direct zone task" end
    Z.Select(1438)
    Q.events:GetScript("OnEvent")(nil,"QUEST_DETAIL")
    assert(Q.Pack==darkshore and Q.state.offered[991020])
    Z.Select(1438)
    C_GossipInfo={GetAvailableQuests=function() return {{questID=991021,title="Gossip zone task"}} end}
    Q.events:GetScript("OnEvent")(nil,"GOSSIP_SHOW")
    assert(Q.Pack==darkshore and Q.state.offered[991021] and not Q.state.offered[991020])
    GetQuestID,GetTitleText,C_GossipInfo,Q.Gear.Capture=oldID,oldTitle,oldGossip,oldCapture
end)

test("unsupported detour cannot resurrect previous zone offers on return",function()
    local oldGossip=C_GossipInfo
    local map=1438
    C_Map={GetBestMapForUnit=function() return map end,
        GetPlayerMapPosition=function() return {x=.4,y=.4} end}
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() end}
    Z.Select(1438);R.gossipOpen=true;R.gossipMap=1438
    C_GossipInfo={GetAvailableQuests=function() return {{questID=991021}} end}
    R.detailOffer={id=991020,map=1438}
    assert(R.Snapshot().offered[991020])
    map=999999;R.Snapshot();assert(not R.detailOffer and not R.gossipOpen)
    map=1438;assert(next(R.Snapshot().offered)==nil)
    C_GossipInfo=oldGossip
end)

test("carried starter identity survives zone changes without ambiguous item guesses",function()
    local oldContainer,oldBags,oldLegacy=C_Container,NUM_BAG_SLOTS,GetContainerItemQuestInfo
    C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,
        GetContainerItemID=function() return 5179 end,GetContainerItemQuestInfo=function() return {} end}
    NUM_BAG_SLOTS=0;GetContainerItemQuestInfo=function() return nil end
    Z.packs[1438]=originalTeldrassil;Z.Select(1439)
    assert(R.ItemStarts({})[927])
    darkshore.quests[2]={id=991110,itemStartID=5179}
    assert(next(R.ItemStarts({}))==nil)
    darkshore.quests[2]=nil;Z.packs[1438]=teldrassil
    C_Container,NUM_BAG_SLOTS,GetContainerItemQuestInfo=oldContainer,oldBags,oldLegacy
end)

Z.packs[1438],Z.packs[1439]=originalTeldrassil,originalDarkshore
Q.Pack=originalPack
C_Map,C_QuestLog,QuestDB,NpcDB=originalMap,originalAPI,originalDB,originalNpc
TomTom,N.current,N.error=originalTomTom,originalCurrent,originalError
Q.UI,Q.inWorld,Q.previous=originalUI,originalWorld,originalPrevious
Q.db.outing,Q.db.autoWaypoint=originalOuting,originalAuto
UnitFactionGroup=originalFaction
Q.route,Q.trips,Q.state=originalRoute,originalTrips,originalState
R.detailOffer,R.gossipOpen,R.gossipMap=originalDetail,originalOpen,originalGossipMap
