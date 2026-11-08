local Q={}
local count=0
local function test(name,fn)
    fn(); count=count+1; print("PASS "..name)
end
local function load(name) assert(loadfile("QuestWeaver/"..name..".lua"))("QuestWeaver",Q) end
load("Core"); load("Trips"); load("Shadowglen"); load("Teldrassil"); load("Catalogues"); load("Darkshore"); load("Darnassus"); load("Gear"); load("Provider"); load("Navigation"); load("Feedback")
assert(loadfile("tests/reference_planner.lua"))("QuestWeaver",Q)
local C=Q.Core
local p={x=.58,y=.44}
local function state()
    return {level=5,pos=p,done={},log={},skip={},mode="xp",budget=10}
end
local function quest(id,xp,minutes)
    return {id=id,name="Quest "..id,xp=xp or 100,minutes=minutes or 4,
        minLevel=1,level=3,start=p,objective=p,finish=p}
end

test("pickup, objective and turn-in form a sequence",function()
    local route=C.Plan({quest(1)},state(),5)
    assert(#route==3 and route[1].action=="PICK UP" and route[2].action=="DO" and route[3].action=="TURN IN")
end)
test("prerequisite unlocks only after turn-in",function()
    local a,b=quest(1),quest(2,10000); b.all={1}
    local r=C.Plan({a,b},state(),8)
    assert(r[1].id==1 and r[3].action=="TURN IN" and r[4].id==2)
end)
test("AND and OR prerequisites have distinct semantics",function()
    local q=quest(3); q.all={1,2}
    local s=state(); s.done[1]=true
    assert(not C.Eligible(q,s)); q.all=nil; q.any={1,2}; assert(C.Eligible(q,s))
end)
test("completed and skipped quests never reappear",function()
    local s=state(); s.done[1]=true; s.skip[2]=true
    assert(#C.Plan({quest(1),quest(2)},s,10)==0)
end)
test("active quests remain eligible after a level gate changes",function()
    local s=state(); local q=quest(1); q.minLevel=20
    assert(not C.Eligible(q,s)); s.log[1]={}; assert(C.Eligible(q,s))
end)
test("pin cannot bypass prerequisites",function()
    local s=state(); s.pin=2; local b=quest(2); b.all={1}
    assert(C.Plan({quest(1),b},s,1)[1].id==1)
end)
test("pin prioritizes an eligible quest",function()
    local s=state(); s.pin=2
    assert(C.Plan({quest(1,999),quest(2)},s,1)[1].id==2)
end)
test("failure does not turn a quest in",function()
    local s=state(); s.log[1]={failed=true}
    assert(#C.Plan({quest(1)},s,5)==0)
end)
test("progress shortens remaining effort",function()
    local a,b=state(),state(); a.log[1]={progress=0}; b.log[1]={progress=.8}
    assert(C.Plan({quest(1)},b,1)[1].minutes<C.Plan({quest(1)},a,1)[1].minutes)
end)
test("fastest mode ignores gear bonuses",function()
    local a,b=quest(1,100,4),quest(2,100,5); b.gear=1
    assert(C.Plan({a,b},state(),1)[1].id==1)
end)
test("balanced admits useful gear within budget",function()
    local a,b=quest(1,100,4),quest(2,100,5); b.gear=1
    local s=state(); s.mode="balanced"
    assert(C.Plan({a,b},s,1)[1].id==2)
end)
test("zero detour budget rejects slower gear candidate",function()
    local a,b=quest(1,100,4),quest(2,100,5); b.gear=1
    local s=state(); s.mode="balanced"; s.budget=0
    assert(C.Plan({a,b},s,1)[1].id==1)
end)
test("known downstream gear can favor its prerequisite within allowance",function()
    local a,b,c=quest(1,100,4),quest(2,90,4),quest(3,100,1)
    c.all={2}; c.gear=1
    local s=state(); s.mode="balanced"; s.budget=10
    assert(C.Plan({a,b,c},s,1)[1].id==2)
    s.budget=0
    assert(C.Plan({a,b,c},s,1)[1].id==1)
end)
test("planning does not mutate live quest state",function()
    local s=state(); C.Plan({quest(1)},s,3)
    assert(not s.log[1] and not s.done[1] and s.pos==p)
end)
test("stable ties use quest ID",function()
    assert(C.Plan({quest(2),quest(1)},state(),1)[1].id==1)
end)
test("missing coordinates and empty packs do not crash",function()
    local q=quest(1); q.start=nil
    assert(#C.Plan({q},state(),1)==0 and #C.Plan({},state(),1)==0)
end)
test("starter pack identifiers are unique and bounded",function()
    local ids={}
    for _,q in ipairs(Q.Pack.quests) do
        assert(not ids[q.id]); ids[q.id]=true
        for _,key in ipairs({"start","objective","finish"}) do local pos=q[key];if pos then assert(pos.x>0 and pos.x<1 and pos.y>0 and pos.y<1) end end
    end
    assert(#Q.Pack.quests>=50)
end)
test("gear profiles distinguish intellect and strength",function()
    local stats={ITEM_MOD_INTELLECT_SHORT=10}
    assert(Q.Gear.Score(stats,"caster")>Q.Gear.Score(stats,"melee"))
end)
test("no item API is unknown gear, not an upgrade",function()
    local score,known=Q.Gear.Evaluate({123},"melee")
    assert(score==0 and known==false)
end)
test("provider operates without optional database",function()
    local s=state(); s.classID=1; s.raceID=4
    local q=Q.Provider.Quests(s,{rewards={},profile="melee"})
    assert(#q==#Q.Pack.quests and not q[1].xpObserved and q[1].metadata:find("Unverified"))
end)
test("observed XP is used only at matching level",function()
    local db={rewards={[456]={xp=999,level=5,items={}}},profile="melee"}
    assert(Q.Provider.Quests(state(),db)[1].xp==999)
    local s=state(); s.level=6
    assert(Q.Provider.Quests(s,db)[1].xp~=999)
end)
test("zero requirement fields do not disable a quest",function()
    QuestDB={Get=function(id,key)
        if key=="name" then return "DB quest" end
        if key=="requiredLevel" then return 1 end
        if key=="requiredClasses" or key=="requiredRaces" or key=="requiredMaxLevel" or key=="parentQuest" or key=="requiredSpell" or key=="requiredSpecialization" then return 0 end
    end}
    local q=Q.Provider.Quests(state(),{rewards={},profile="melee"})[1]
    assert(not q.disabled and q.name=="DB quest")
    QuestDB=nil
end)
test("uncached reward items remain unknown",function()
    GetItemInfo=function() return nil end
    GetItemStats=function() return {} end
    IsUsableItem=function() return true end
    local score,known=Q.Gear.Evaluate({123},"melee")
    assert(score==0 and not known)
end)
test("equipment comparisons detect an actual stat upgrade",function()
    UnitLevel=function() return 5 end
    GetItemInfo=function() return "Test item",nil,nil,nil,1,nil,nil,nil,"INVTYPE_CHEST" end
    GetItemStats=function(id) return {ITEM_MOD_STRENGTH_SHORT=id==123 and 10 or 5} end
    GetInventoryItemLink=function() return "old" end
    local score,known=Q.Gear.Evaluate({123},"melee")
    assert(score==1 and known)
    IsUsableItem=function() return false end
    assert(Q.Gear.Evaluate({123},"melee")==0)
    IsUsableItem=function() return true end
end)

-- Runtime smoke test with game-independent UI stubs. This is not an in-game test.
local scripts={}
CreateFrame=function() return {SetScript=function(_,name,fn) scripts[name]=fn end,RegisterEvent=function() end} end
SlashCmdList={}
UnitClass=function() return "Warrior","WARRIOR",1 end
UnitRace=function() return "Night Elf","NightElf",4 end
UnitLevel=function() return 5 end
UnitFactionGroup=function() return "Alliance","Alliance" end
C_Map={GetBestMapForUnit=function() return 1438 end,GetPlayerMapPosition=function() return p end}
C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
    GetInfo=function() return {questID=456,title="Nature"} end,
    IsComplete=function() return false end,
    IsQuestFlaggedCompleted=function() return false end,
    GetQuestObjectives=function() return {{numFulfilled=3,numRequired=6}} end}
load("Runtime")
Q.UI={Create=function() end,Render=function() end}
test("runtime initializes and samples modern quest objectives",function()
    scripts.OnEvent(nil,"ADDON_LOADED","QuestWeaver")
    local s=Q.Runtime.Snapshot()
    assert(s.log[456].progress==.5 and not s.log[456].complete and Q.db.mode=="balanced")
end)
test("runtime plans in zone and suppresses wrong-zone routes",function()
    Q.Runtime.Refresh(); assert(#Q.route>0)
    C_Map.GetBestMapForUnit=function() return 1 end
    Q.Runtime.Refresh(); assert(#Q.route==0)
    C_Map.GetBestMapForUnit=function() return 1438 end
end)
test("turn-in event records completion without character identity",function()
    scripts.OnEvent(nil,"QUEST_TURNED_IN",456)
    assert(Q.db.completed[456] and not Q.db.characterName)
end)
test("slash settings validate and clamp values",function()
    SlashCmdList.QUESTWEAVER("budget 999"); assert(Q.db.budget==30)
    SlashCmdList.QUESTWEAVER("budget -3"); assert(Q.db.budget==0)
    SlashCmdList.QUESTWEAVER("profile tank"); assert(Q.db.profile=="tank")
    SlashCmdList.QUESTWEAVER("skip 916"); assert(Q.db.skip[916])
    SlashCmdList.QUESTWEAVER("restore"); assert(not Q.db.skip[916])
end)
test("legacy quest log fallback preserves complete state",function()
    C_QuestLog=nil
    GetNumQuestLogEntries=function() return 1 end
    GetQuestLogTitle=function() return "Nature",2,nil,false,false,1,nil,456 end
    assert(Q.Runtime.Snapshot().log[456].complete)
end)

test("all addon source files compile as Lua",function()
    for _,name in ipairs({"Core","Trips","Shadowglen","Teldrassil","Catalogues","Darkshore","Darnassus","Provider","Gear","Navigation","Feedback","Runtime","UI"}) do
        assert(loadfile("QuestWeaver/"..name..".lua"))
    end
end)

assert(loadfile("tests/trips_test.lua"))(Q,test)
assert(loadfile("tests/stability_test.lua"))(Q,test)
assert(loadfile("tests/ui_test.lua"))(Q,test)
assert(loadfile("tests/navigation_test.lua"))(Q,test)
assert(loadfile("tests/locations_test.lua"))(Q,test)
assert(loadfile("tests/runtime_discovery_test.lua"))(Q,test)
assert(loadfile("tests/discovery_planner_test.lua"))(Q,test)
assert(loadfile("tests/nearby_return_test.lua"))(Q,test)
assert(loadfile("tests/coverage_test.lua"))(Q,test)
assert(loadfile("tests/handoffs_test.lua"))(Q,test)
assert(loadfile("tests/shared_return_test.lua"))(Q,test)
assert(loadfile("tests/onroute_pickup_test.lua"))(Q,test)
assert(loadfile("tests/feedback_test.lua"))(Q,test)
assert(loadfile("tests/feedback_ui_test.lua"))(Q,test)
assert(loadfile("tests/npc_offers_test.lua"))(Q,test)
assert(loadfile("tests/multistop_pickup_test.lua"))(Q,test)
assert(loadfile("tests/boundary_test.lua"))(Q,test)
assert(loadfile("tests/field_continuation_test.lua"))(Q,test)
assert(loadfile("tests/detail_offer_test.lua"))(Q,test)
assert(loadfile("tests/outing_context_test.lua"))(Q,test)
assert(loadfile("tests/catalogue_test.lua"))(Q,test)
assert(loadfile("tests/zones_test.lua"))(Q,test)
assert(loadfile("tests/darkshore_test.lua"))(Q,test)
assert(loadfile("tests/darnassus_test.lua"))(Q,test)
print(string.format("%d tests passed",count))
