local Q,test=...
local R=Q.Runtime
local globals={"C_Container","GetContainerNumSlots","GetContainerItemQuestInfo","GetContainerItemID",
    "C_Item","GetItemInfo","NUM_BAG_SLOTS","C_QuestLog","GetQuestLogRewardXP","GetQuestLogTitle",
    "GetNumQuestLogEntries","IsQuestFlaggedCompleted"}
local saved={}
for _,name in ipairs(globals) do saved[name]=_G[name]; _G[name]=nil end
local function clear()
    for _,name in ipairs(globals) do _G[name]=nil end
end
local function modern()
    clear()
    NUM_BAG_SLOTS=0
    C_Container={GetContainerNumSlots=function(bag) assert(bag==0); return 1 end,
        GetContainerItemQuestInfo=function() return {isQuestItem=true,questID=90001,isActive=false} end,
        GetContainerItemID=function() return 70001 end}
    C_Item={GetItemInfo=function(id) assert(id==70001); return "A quest item" end}
    C_QuestLog={GetTitleForQuestID=function(id) assert(id==90001); return "A dropped quest" end}
end

test("modern bag discovery keeps item and quest titles distinct",function()
    modern()
    local items=R.ItemStarts({})
    assert(items[90001].itemID==70001 and items[90001].name=="A quest item")
    assert(items[90001].title=="A dropped quest" and items[90001].bag==0 and items[90001].slot==1)
end)
test("accepted and active item quests never become duplicate item starts",function()
    modern()
    assert(not R.ItemStarts({[90001]={}})[90001])
    C_Container.GetContainerItemQuestInfo=function() return {questID=90001,isActive=true} end
    assert(next(R.ItemStarts({}))==nil)
end)
test("legacy bag tuple and uncached item names are supported",function()
    clear(); NUM_BAG_SLOTS=0
    GetContainerNumSlots=function() return 2 end
    GetContainerItemQuestInfo=function(bag,slot) return true,90002,slot==2 and 1 or nil end
    GetContainerItemID=function() return 70002 end
    local items=R.ItemStarts({})
    assert(items[90002].itemID==70002 and items[90002].slot==1 and not items[90002].name)
    GetContainerItemQuestInfo=function() return true,90002,1 end
    assert(next(R.ItemStarts({}))==nil)
end)
test("known item metadata supplies quest identity without quest-info API",function()
    clear(); NUM_BAG_SLOTS=0
    local seed={id=90003,itemStartID=70003}; Q.Pack.quests[#Q.Pack.quests+1]=seed
    C_Container={GetContainerNumSlots=function() return 1 end,
        GetContainerItemInfo=function() return {itemID=70003} end}
    local items=R.ItemStarts({})
    table.remove(Q.Pack.quests)
    assert(items[90003].itemID==70003)
end)
test("unrelated quest items, bad ids and unavailable APIs do not create starts",function()
    modern()
    C_Container.GetContainerItemQuestInfo=function() return {isQuestItem=true} end
    assert(next(R.ItemStarts({}))==nil)
    for _,id in ipairs({0,-1,0/0,math.huge,"90001",1.5}) do
        C_Container.GetContainerItemQuestInfo=function() return {questID=id} end
        assert(next(R.ItemStarts({}))==nil)
    end
    C_Container.GetContainerItemQuestInfo=function() error("unsupported") end
    assert(next(R.ItemStarts({}))==nil)
    clear(); assert(next(R.ItemStarts({}))==nil)
end)
test("bag discovery scans carried bags only with bounded slot counts",function()
    clear(); NUM_BAG_SLOTS=4
    local seen,count={},0
    C_Container={GetContainerNumSlots=function(bag) seen[bag]=true; return 2 end,
        GetContainerItemQuestInfo=function() count=count+1; return {} end}
    R.ItemStarts({})
    assert(count==10 and seen[0] and seen[4] and not seen[-1] and not seen[5])
    NUM_BAG_SLOTS=10000;count=0
    C_Container.GetContainerNumSlots=function() return 10000 end
    R.ItemStarts({}); assert(count==1100)
end)
test("snapshot exposes live accepted metadata without fabricating a finish",function()
    modern()
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {questID=90001,title="Accepted local quest",level=6} end,
        GetQuestObjectives=function() return {{numRequired=2,numFulfilled=1}} end,
        GetNextWaypoint=function() return 1438,.58,.35 end}
    GetQuestLogRewardXP=function(id) assert(id==90001); return 475 end
    local s=R.Snapshot()
    assert(s.log[90001].title=="Accepted local quest" and s.log[90001].level==6 and s.log[90001].xp==475)
    assert(s.log[90001].location.x==.58 and not s.log[90001].finish and not s.itemStarts[90001])
end)
test("snapshot suppresses completed item starts and annotates live item locations",function()
    modern()
    C_QuestLog.GetNumQuestLogEntries=function() return 0 end
    C_QuestLog.GetNextWaypoint=function() return 1438,.58,.35 end
    C_QuestLog.IsQuestFlaggedCompleted=function(id) return id==90001 end
    local s=R.Snapshot(); assert(s.done[90001] and not s.itemStarts[90001])
    C_QuestLog.IsQuestFlaggedCompleted=function() return false end
    s=R.Snapshot();assert(s.itemStarts[90001].location.x==.58 and not s.log[90001])
    C_Container.GetContainerNumSlots=function() return 0 end
    assert(next(R.Snapshot().itemStarts)==nil)
end)
test("legacy accepted metadata survives optional reward API failure",function()
    clear()
    GetNumQuestLogEntries=function() return 1 end
    GetQuestLogTitle=function() return "Legacy local quest",4,nil,false,false,1,nil,90005 end
    GetQuestLogRewardXP=function() error("unsupported") end
    local s=R.Snapshot()
    assert(s.log[90005].complete and s.log[90005].title=="Legacy local quest" and s.log[90005].level==4)
    assert(s.log[90005].xp==nil and next(s.itemStarts)==nil)
end)
test("item acceptance never sends a geographic waypoint",function()
    local oldRoute=Q.route
    Q.route={{action="ACCEPT ITEM"}}
    assert(pcall(R.Waypoint))
    Q.route=oldRoute
end)
for _,name in ipairs(globals) do _G[name]=saved[name] end
