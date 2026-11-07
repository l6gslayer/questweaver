local _, Q = ...
Q.Provider={}
local P=Q.Provider

local function read(db,id,key)
    if not db or type(db.Get)~="function" then return nil end
    local ok,value=pcall(db.Get,id,key)
    if ok then return value end
end
local function point(givers)
    for group,db in ipairs({NpcDB or false,ObjectDB or false}) do
        for _,id in ipairs((givers or {})[group] or {}) do
            local spawns=read(db,id,"spawns")
            -- AreaTable 141 is Teldrassil; do not mix subzone coordinate spaces.
            local pos=spawns and spawns[141] and spawns[141][1]
            if pos and pos[1]>0 and pos[2]>0 then return {x=pos[1]/100,y=pos[2]/100} end
        end
    end
end
local function restricted(mask,index)
    if not mask or mask==0 then return false end
    if not index or not bit or not bit.band then return true end
    return bit.band(mask,2^(index-1))==0
end

function P.Quests(state,db)
    local result={}
    for _,seed in ipairs(Q.Pack.quests) do
        local q=Q.Core.Copy(seed)
        local name=read(QuestDB,q.id,"name")
        if name then
            q.name=name
            q.minLevel=read(QuestDB,q.id,"requiredLevel") or q.minLevel
            local level=read(QuestDB,q.id,"questLevel")
            if level and level>0 then q.level=level end
            q.all=read(QuestDB,q.id,"preQuestGroup")
            q.any=read(QuestDB,q.id,"preQuestSingle")
            q.start=point(read(QuestDB,q.id,"startedBy")) or q.start
            q.finish=point(read(QuestDB,q.id,"finishedBy")) or q.finish
            q.metadata="QuestieDB + starter objective estimates"
            q.disabled=restricted(read(QuestDB,q.id,"requiredClasses"),state.classID)
                or restricted(read(QuestDB,q.id,"requiredRaces"),state.raceID)
            -- This pack contains only simple starter chains; refuse unsupported
            -- special gates rather than guessing that a quest is available.
            for _,key in ipairs({"requiredSkill","requiredMinRep","requiredMaxRep","requiredRanks"}) do
                if read(QuestDB,q.id,key) then q.disabled=true end
            end
            for _,key in ipairs({"requiredSpell","requiredSpecialization","parentQuest"}) do
                local v=read(QuestDB,q.id,key)
                if v and v~=0 then q.disabled=true end
            end
            local max=read(QuestDB,q.id,"requiredMaxLevel")
            if max and max>0 and state.level>max then q.disabled=true end
            for _,id in ipairs(read(QuestDB,q.id,"exclusiveTo") or {}) do
                if state.done[id] or state.log[id] then q.disabled=true end
            end
        else q.metadata="Unverified Classic starter baseline" end
        local log=state.log[q.id]
        if log and not log.failed and log.location then
            if log.complete then
                q.finish=Q.Core.Copy(log.location)
            else
                q.objective=Q.Core.Copy(log.location)
                -- The client supplies one current quest destination. It does
                -- not identify which static gathering task owns that point.
                -- Use a single live-stage action, not duplicate task pins.
                q.tasks=nil
            end
        end
        local observed=db.rewards[q.id]
        if observed and observed.level==state.level and observed.xp and observed.xp>0 then
            q.xp=observed.xp; q.xpObserved=true
        end
        -- Approximate grey-quest reduction, explicitly remains an estimate.
        if not q.xpObserved then
            local delta=state.level-q.level
            q.xp=math.floor(q.xp*(delta<=5 and 1 or math.max(.1,1-(delta-5)*.2)))
        end
        if observed then
            q.gear,q.gearKnown=Q.Gear.Evaluate(observed.items,db.profile)
            if observed.incomplete then q.gearKnown=false end
        end
        result[#result+1]=q
    end
    return result
end
