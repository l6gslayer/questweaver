local Q,test=...
local Z,C,T,P=Q.Catalogues,Q.Core,Q.Trips,Q.Provider
local originalPack,oldDB,oldNpc=Q.Pack,QuestDB,NpcDB
Z.Select(1439);QuestDB=nil;NpcDB=nil
local function state()
    return {map=1439,level=20,classID=3,raceID=4,pos={x=.37,y=.44},
        log={},done={},skip={},offered={},itemStarts={},mode="balanced",budget=10,freeSlots=30}
end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function q(s,id) return find(P.Quests(s,{rewards={},profile="ranged"}),id) end

test("Darkshore records separate advance conditional and owned pickup coverage",function()
    assert(Q.Pack.mapID==1439 and Q.Pack.areaID==148 and Q.Pack.faction=="Alliance")
    local seen,a,o,b={},0,0,0
    for _,seed in ipairs(Q.Pack.quests) do
        assert(not seen[seed.id] and seed.catalogue);seen[seed.id]=true
        if seed.ownedOnly then b=b+1 elseif seed.offeredOnly then o=o+1 else a=a+1 end
        for _,key in ipairs({"start","objective","finish"}) do
            assert(not seed[key] or C.IsMapPoint(seed[key]))
        end
    end
    assert(#Q.Pack.quests==28 and a==8 and o==18 and b==2)
    for _,seed in ipairs(Q.Pack.quests) do for _,id in ipairs(seed.all or {}) do assert(seen[id]) end end
end)
test("Auberdine pickup can be proposed before interaction without invented work",function()
    local s=state();local a=q(s,983)
    assert(C.Eligible(a,s) and a.pendingAction=="PICK UP")
    local route,trips=T.Plan({a},s)
    assert(route[1].action=="PICK UP" and #route==1 and not trips[1].completed[983])
    assert(a.pendingLabel:find("Check availability",1,true))
end)
test("Darkshore prerequisite links and current live stage drive planning",function()
    local s=state();assert(not C.Eligible(q(s,1001),s))
    s.done[983]=true;assert(C.Eligible(q(s,1001),s))
    assert(not C.Eligible(q(s,985),s));s.done[984]=true;assert(C.Eligible(q(s,985),s))
    assert(not C.Eligible(q(s,4813),s));s.done[4812]=true;assert(C.Eligible(q(s,4813),s))
    s.log[983]={xp=777,progress=.5,location={x=.39,y=.48,source="WoW objective"}}
    local a=q(s,983);s.done[983]=nil
    assert(a.xp==777 and a.objective.y==.48 and not a.pendingAction)
    assert(T.Plan({a},s)[1].action=="DO")
end)
test("conditional Darkshore offer gains current pickup without claiming known recipient",function()
    local s=state();assert(not C.Eligible(q(s,2118),s))
    s.offered[2118]=true
    local a=q(s,2118);local route,trips=T.Plan({a},s)
    assert(C.Eligible(a,s) and a.start.x==s.pos.x)
    assert(route[1].action=="PICK UP" and not a.finish and not trips[1].completed[2118])
end)
test("Darkshore dropped starters require ownership and never guess city destination",function()
    local s=state();assert(not C.Eligible(q(s,968),s) and not C.Eligible(q(s,98028),s))
    for id,itemID in pairs({[968]=5352,[98028]=279275}) do
        s.itemStarts[id]={itemID=itemID,name="Carried quest starter"}
        local route,trips=T.Plan({q(s,id)},s)
        assert(route[1].action=="ACCEPT ITEM" and not trips[1].completed[id])
    end
    assert(q(s,968).destinationMap==1455 and not q(s,968).finish)
    s.log[968]={complete=true};s.itemStarts={}
    assert(#T.Plan({q(s,968)},s)==0)
end)
Q.Pack=originalPack;QuestDB=oldDB;NpcDB=oldNpc
