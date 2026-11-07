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
    local result,notices,seeds,known={},{},{},{}
    for _,seed in ipairs(Q.Pack.quests) do seeds[#seeds+1]=seed; known[seed.id]=true end
    local ids={}
    for id in pairs(state.log) do if not known[id] then ids[#ids+1]=id end end
    for id in pairs(state.itemStarts or {}) do
        if not known[id] and not state.log[id] then ids[#ids+1]=id end
    end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local log,item=state.log[id],(state.itemStarts or {})[id]
        local dest=(log and log.location) or (item and item.location)
        local finish=point(read(QuestDB,id,"finishedBy"))
        if not Q.Core.IsLocal(finish) then finish=nil end
        if (log and Q.Core.IsLocal(dest)) or (item and (Q.Core.IsLocal(dest) or finish)) then
            local complete=log and log.complete
            seeds[#seeds+1]={id=id,name=(log and log.title) or (item and item.title) or ("Quest "..id),
                minLevel=1,level=(log and log.level) or state.level,
                xp=(log and log.xp) or 250,xpEstimated=not (log and log.xp),minutes=5,
                start=Q.Core.Copy(state.pos),objective=dest or finish,
                finish=complete and dest or finish,acceptedOnly=log~=nil,
                itemStartID=item and item.itemID,dynamic=true,
                stageOnly=not complete and (item~=nil or not finish),
                note="Discovered nearby quest. Work time is estimated; unknown rewards are not assumed to be gear upgrades."}
        elseif item and not state.done[id] and not state.skip[id] then
            notices[#notices+1]="Bag quest: use "..(item.name or ("item for quest "..id)).." to inspect/accept; local destination unknown."
        elseif log and not log.failed and not log.location and not state.skip[id] then
            notices[#notices+1]="Quest "..id..": location unavailable; check quest log."
        end
    end
    for _,seed in ipairs(seeds) do
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
        else q.metadata=q.dynamic and "Discovered nearby quest" or "Unverified starter baseline" end
        local log=state.log[q.id]
        local item=(state.itemStarts or {})[q.id]
        if q.requiredRaceID and state.raceID~=q.requiredRaceID then q.disabled=true end
        if q.requiredClassID and state.classID~=q.requiredClassID then q.disabled=true end
        if q.offeredOnly then
            if not log then
                q.pendingAction="PICK UP"; q.pendingLabel="Accept "..q.name.." (offered by NPC)"
                q.stageOnly=true; q.minutes=.15
            elseif log.complete then q.objective=Q.Core.Copy(q.finish) end
        end
        if (q.itemStartID or item) and not log then
            q.stageOnly=true
            if item then
                q.pendingAction="ACCEPT ITEM"; q.start=Q.Core.Copy(state.pos)
                q.itemName=item.name or (q.itemStartID and ("item "..q.itemStartID)) or ("bag "..(item.bag or "?").." slot "..(item.slot or "?"))
                q.pendingLabel="Use "..q.itemName.." in bags; accept "..q.name
                if not state.skip[q.id] and not state.done[q.id] then notices[#notices+1]=q.pendingLabel end
            else
                q.pendingAction="LOOT ITEM"
                q.pendingLabel="Loot quest starter: "..q.name
                if q.ownedOnly then q.disabled=true end
                -- This is an outing opportunity, not a prerequisite claim.
                q.disabled=q.disabled or (not state.log[q.dropCompanion]
                    and Q.Core.Distance(state.pos,q.start)>.025)
            end
        end
        if q.ownedOnly and log then q.stageOnly=not q.finish end
        if q.id==97236 and log then q.minutes=.15 end
        if q.dynamic then
            if not Q.Core.IsLocal(q.finish) then q.finish=nil end
            q.stageOnly=not (log and log.complete) and (item~=nil or not q.finish)
        end
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
        if q.ownedOnly and log and log.complete and q.finish then
            q.stageOnly=false; q.objective=Q.Core.Copy(q.finish)
        end
        if log and not log.failed and (q.offeredOnly or q.ownedOnly) and not q.objective then
            notices[#notices+1]=q.name..": current destination unavailable; check quest log."
        end
        local observed=db.rewards[q.id]
        if observed and observed.level==state.level and observed.xp and observed.xp>0 then
            q.xp=observed.xp; q.xpObserved=true; q.xpEstimated=false
        end
        if log and type(log.xp)=="number" and log.xp>=0 then
            q.xp=log.xp; q.xpObserved=true; q.xpEstimated=false
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
    return result,notices
end
