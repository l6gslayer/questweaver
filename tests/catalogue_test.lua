local Q,test=...
local C,T,P=Q.Core,Q.Trips,Q.Provider
local oldDB,oldNpc=QuestDB,NpcDB
QuestDB=nil;NpcDB=nil
local function state()
    return {map=Q.Pack.mapID,level=10,classID=3,raceID=4,pos={x=.60,y=.69},
        log={},done={},skip={},offered={},itemStarts={},mode="balanced",budget=10,freeSlots=30}
end
local function provider(s) return P.Quests(s,{rewards={},profile="ranged"}) end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function q(s,id) return find(provider(s),id) end
local function member(route,id,action)
    for _,g in ipairs(route) do for _,m in ipairs(g.members) do if m.id==id and (not action or m.action==action) then return true end end end
end

test("catalogue prerequisites are internal acyclic and points stay on the pack map",function()
    local byID={};for _,seed in ipairs(Q.Pack.quests) do assert(not byID[seed.id]);byID[seed.id]=seed end
    local visiting,done={},{}
    local function visit(id)
        assert(byID[id] and not visiting[id],"missing prerequisite or cycle")
        if done[id] then return end
        visiting[id]=true
        for _,parent in ipairs(byID[id].all or {}) do visit(parent) end
        visiting[id]=nil;done[id]=true
    end
    for id in pairs(byID) do visit(id) end
    assert(#Q.Pack.quests>=70 and Q.Pack.catalogueVersion==1)
    assert(not byID[922].finish and byID[922].destinationMap==1457)
    assert(not byID[98391].finish and byID[98391].destinationMap==1457)
end)
test("known catalogue pickup is planned before seeing NPC beyond the old corridor",function()
    local s=state();s.done[997]=true
    local a,b=q(s,918),q(s,919)
    assert(C.Eligible(a,s) and C.Eligible(b,s) and a.pendingAction=="PICK UP")
    local route,trips=T.Plan({a,b},s)
    assert(member(route,918,"PICK UP") and member(route,919,"PICK UP"))
    assert(not member(route,918,"DO") and not trips[1].completed[918])
    assert(a.pendingLabel:find("Check availability",1,true))
end)
test("confirmed catalogue offer overrides conservative prerequisite but not skips or capacity",function()
    local s=state();assert(not C.Eligible(q(s,918),s))
    s.offered[918]=true;assert(C.Eligible(q(s,918),s))
    s.skip[918]=true;assert(not C.Eligible(q(s,918),s));s.skip={}
    s.freeSlots=0;assert(#T.Plan({q(s,918)},s)==0)
end)
test("accepted catalogue work uses live objective without fabricated return or duplicate discovery",function()
    local s=state();s.log[918]={title="Timberling Seeds",level=7,xp=625,progress=.25,
        progressKnown=true,location={x=.57,y=.71,source="WoW objective"}}
    local qs=provider(s);local count=0;for _,v in ipairs(qs) do if v.id==918 then count=count+1 end end
    local a=find(qs,918)
    assert(count==1 and a.xp==625 and not a.pendingAction and a.objective.y==.71)
    local route=T.Plan({a},s);assert(member(route,918,"DO"))
    s.log[918].complete=true;s.log[918].location={x=.61,y=.69}
    route=T.Plan({q(s,918)},s);assert(route[1].action=="TURN IN" and route[1].target.y==.69)
end)
test("catalogue city handoff waits for live map projection then routes observed return",function()
    local s=state();s.log[922]={complete=true,location={x=.25,y=.51,source="WoW objective"},xp=320}
    local a=q(s,922);local route=T.Plan({a},s)
    assert(a.finish.x==.25 and a.objective.x==.25 and not a.stageOnly)
    assert(route[1].action=="TURN IN")
    s.log[922].location=nil;a=q(s,922)
    assert(not a.finish and #T.Plan({a},s)==0)
end)
test("catalogue chains respect actual prerequisites and Forever intermediary steps",function()
    local s=state();assert(not C.Eligible(q(s,476),s));s.done[475]=true;assert(C.Eligible(q(s,476),s))
    assert(not C.Eligible(q(s,2459),s));s.done[2438]=true;assert(C.Eligible(q(s,2459),s))
    assert(q(s,98398).all[1]==98392 and q(s,940).all[1]==98398)
    assert(q(s,98403).all[1]==932 and q(s,98403).elite and q(s,98403).risk>0)
    s.done[932]=true;assert(not C.Eligible(q(s,98403),s))
end)
test("profession regional elite and unresolved entries require observed offers",function()
    local s=state()
    for _,id in ipairs({96630,96606,96634,97949,97939,98403,2541,938}) do
        assert(not C.Eligible(q(s,id),s))
        s.offered[id]=true;assert(C.Eligible(q(s,id),s));s.offered[id]=nil
    end
end)
test("heart starter is owned-only while fruit frond and planting supplies are not starters",function()
    local s=state();local heart=q(s,927)
    assert(heart.itemStartID==5179 and heart.ownedOnly and heart.dropNPCID==3535 and not C.Eligible(heart,s))
    s.itemStarts[927]={itemID=5179,name="Moss-twined Heart"}
    local route,trips=T.Plan({q(s,927)},s)
    assert(route[1].action=="ACCEPT ITEM" and not trips[1].completed[927])
    assert(not q(s,930).itemStartID and q(s,930).objectStartID==6751)
    assert(not q(s,931).itemStartID and q(s,931).objectStartID==6752)
    assert(not q(s,941).itemStartID and q(s,941).all[1]==927)
    assert(not q(s,2399).itemStartID and q(s,2399).objectStartID==7510)
end)
test("rare opportunity is advisory nearby and never schedules a guaranteed farming stop",function()
    local s=state();s.pos={x=.43,y=.33}
    local qs,notes=provider(s)
    local found=false;for _,note in ipairs(notes) do if note:find("Optional rare nearby",1,true) then found=true end end
    assert(found and not C.Eligible(find(qs,927),s))
    s.skip[927]=true;local _,skipNotes=provider(s)
    for _,note in ipairs(skipNotes) do assert(not note:find("Optional rare nearby",1,true)) end
end)
test("optional incomplete database does not erase catalogue prerequisites",function()
    local s=state()
    QuestDB={Get=function(id,key) if key=="name" then return "Metadata name" end end}
    assert(q(s,476).all[1]==475 and not C.Eligible(q(s,476),s))
    QuestDB.Get=function(id,key)
        if key=="name" then return "Metadata name" end
        if key=="preQuestGroup" then return {999999} end
    end
    assert(q(s,476).all[1]==475)
    QuestDB=nil
end)
test("unlocated accepted catalogue quest remains a notice and foreign map cannot schedule pickups",function()
    local s=state();s.log[2541]={title="Sleeping Druid",progress=0}
    local a=q(s,2541);assert(not a.objective and #T.Plan({a},s)==0)
    local _,notes=provider(s);local found=false
    for _,note in ipairs(notes) do if note:find("current destination unavailable",1,true) then found=true end end
    assert(found)
    s.log[2541].complete=true
    a=q(s,2541);assert(not a.objective and not a.finish and #T.Plan({a},s)==0)
    s=state();s.map=999;s.done[997]=true;assert(not C.Eligible(q(s,918),s))
end)
QuestDB=oldDB;NpcDB=oldNpc
