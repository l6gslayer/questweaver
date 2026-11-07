local _, Q = ...
Q.Gear={}
local G=Q.Gear
G.profiles={
    melee={ITEM_MOD_STRENGTH_SHORT=2,ITEM_MOD_AGILITY_SHORT=1.5,ITEM_MOD_STAMINA_SHORT=.5,ITEM_MOD_ATTACK_POWER_SHORT=1},
    ranged={ITEM_MOD_AGILITY_SHORT=2,ITEM_MOD_STAMINA_SHORT=.5,ITEM_MOD_ATTACK_POWER_SHORT=1},
    caster={ITEM_MOD_INTELLECT_SHORT=2,ITEM_MOD_SPIRIT_SHORT=1,ITEM_MOD_STAMINA_SHORT=.5,ITEM_MOD_SPELL_POWER_SHORT=2},
    healer={ITEM_MOD_INTELLECT_SHORT=2,ITEM_MOD_SPIRIT_SHORT=1.5,ITEM_MOD_STAMINA_SHORT=.5,ITEM_MOD_SPELL_POWER_SHORT=2},
    tank={ITEM_MOD_STAMINA_SHORT=2,ITEM_MOD_STRENGTH_SHORT=1,ITEM_MOD_AGILITY_SHORT=.5,RESISTANCE0_NAME=.03},
}
local slots={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},
    INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},
    INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16},
    INVTYPE_2HWEAPON={16,17},INVTYPE_WEAPONMAINHAND={16},INVTYPE_WEAPONOFFHAND={17},
    INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18}}

function G.Score(stats,profile)
    local score=0
    for key,weight in pairs(G.profiles[profile] or G.profiles.melee) do score=score+(stats[key] or 0)*weight end
    return score
end
local function itemInfo(id)
    local name,_,_,_,minLevel,_,_,_,equip=GetItemInfo(id)
    if not name then
        if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        return
    end
    return equip,minLevel
end
function G.Evaluate(items,profile)
    if not GetItemInfo or not GetItemStats or not IsUsableItem then return 0,false end
    local best,known=0,true
    for _,id in ipairs(items or {}) do
        local equip,level=itemInfo(id)
        if not equip then known=false
        elseif slots[equip] and (level or 0)<=UnitLevel("player") then
            local usable=IsUsableItem(id)
            if usable then
                local stats=GetItemStats(id)
                local score=G.Score(stats or {},profile)
                local baseline,missing=nil,stats==nil
                for _,slot in ipairs(slots[equip]) do
                    local old=GetInventoryItemLink("player",slot)
                    local oldStats=old and GetItemStats(old)
                    if old and not oldStats then missing=true end
                    local value=old and G.Score(oldStats or {},profile) or 0
                    if equip=="INVTYPE_2HWEAPON" then baseline=(baseline or 0)+value
                    else baseline=baseline and math.min(baseline,value) or value end
                end
                -- Replacing a two-hander with one weapon needs a full loadout comparison.
                local main=GetInventoryItemLink("player",16)
                local mainEquip=main and itemInfo(main)
                local unsupported=mainEquip=="INVTYPE_2HWEAPON" and (equip=="INVTYPE_WEAPON" or equip=="INVTYPE_WEAPONMAINHAND" or equip=="INVTYPE_WEAPONOFFHAND" or equip=="INVTYPE_SHIELD" or equip=="INVTYPE_HOLDABLE")
                if unsupported or missing then known=false
                else best=math.max(best,(score-(baseline or 0))/math.max(10,baseline or 0)) end
            end
        end
    end
    return best,known
end

function G.Capture(db)
    if not GetQuestID then return end
    local id=GetQuestID()
    if not id or id==0 then return end
    local items,missing={},false
    for _,kind in ipairs({"choice","reward"}) do
        local count=kind=="choice" and (GetNumQuestChoices and GetNumQuestChoices() or 0) or (GetNumQuestRewards and GetNumQuestRewards() or 0)
        for i=1,count do
            local link=GetQuestItemLink and GetQuestItemLink(kind,i)
            local item=link and tonumber(link:match("item:(%d+)"))
            if item then items[#items+1]=item else missing=true end
        end
    end
    -- Only quest IDs and reward IDs/XP are stored; never names or account identifiers.
    local old=db.rewards[id]
    db.rewards[id]={items=missing and old and old.items or items, incomplete=missing,
        xp=GetRewardXP and GetRewardXP() or nil,level=UnitLevel("player")}
end
