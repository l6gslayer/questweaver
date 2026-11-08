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
            -- AreaTable IDs differ from UI map IDs. Only use this zone's
            -- coordinate space; never reuse another zone's percentages.
            local area=Q.Pack.areaID or 141
            local pos=spawns and spawns[area] and spawns[area][1]
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
    local ids,seen={},{}
    local function discover(id)
        if type(id)=="number" and id>0 and id<1000000000 and id==math.floor(id) and not known[id] and not seen[id] then
            ids[#ids+1]=id;seen[id]=true
        end
    end
    for id in pairs(state.log) do discover(id) end
    for id in pairs(state.itemStarts or {}) do discover(id) end
    for id,offered in pairs(state.offered or {}) do if offered==true then discover(id) end end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local log,item=state.log[id],(state.itemStarts or {})[id]
        local dest=(log and log.location) or (item and item.location)
        local finish=point(read(QuestDB,id,"finishedBy"))
        if not Q.Core.IsMapPoint(finish) then finish=nil end
        if (log and (not state.map or state.map==Q.Pack.mapID) and Q.Core.IsMapPoint(dest))
            or (item and (Q.Core.IsLocal(dest) or Q.Core.IsLocal(finish))) then
            local complete=log and log.complete
            seeds[#seeds+1]={id=id,name=(log and log.title) or (item and item.title) or ("Quest "..id),
                minLevel=1,level=(log and log.level) or state.level,
                xp=(log and log.xp) or 250,xpEstimated=not (log and log.xp),minutes=5,
                start=Q.Core.Copy(state.pos),objective=dest or finish,
                finish=complete and dest or finish,acceptedOnly=log~=nil,
                itemStartID=item and item.itemID,dynamic=true,
                stageOnly=not complete and (item~=nil or not finish),
                note="Discovered nearby quest. Work time is estimated; unknown rewards are not assumed to be gear upgrades."}
        elseif (state.offered or {})[id]==true and not log and not item
            and Q.Core.IsMapPoint(state.pos) and (not state.map or state.map==Q.Pack.mapID) then
            local info=(state.offerDetails or {})[id] or {}
            local title=type(info.title)=="string" and info.title or ("Quest "..id)
            local level=type(info.level)=="number" and info.level>0 and info.level<1000 and info.level or state.level
            local start=Q.Core.Copy(state.pos);start.source=info.source or "Observed NPC offer"
            seeds[#seeds+1]={id=id,name=title,level=level,minLevel=1,xp=250,xpEstimated=true,
                minutes=.15,start=start,offeredOnly=true,dynamic=true,dynamicOffer=true,stageOnly=true,
                note="Confirmed quest offer. Accept manually to reveal objective/reward data; later work and return are not assumed."}
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
            if not q.catalogue or not q.all then
                q.all=read(QuestDB,q.id,"preQuestGroup") or q.all
                q.any=read(QuestDB,q.id,"preQuestSingle") or q.any
            end
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
        else q.metadata=q.catalogue and "Forever catalogue; estimated work/travel"
            or (q.dynamic and "Discovered nearby quest" or "Unverified starter baseline") end
        local log=state.log[q.id]
        local item=(state.itemStarts or {})[q.id]
        if q.catalogue and log and not q.start then q.start=Q.Core.Copy(state.pos) end
        if q.catalogue and not log and (state.offered or {})[q.id]==true then
            -- The actual offer supersedes conservative catalogue gates.
            q.disabled=false;q.all=nil;q.any=nil;q.minLevel=1
            q.start=Q.Core.Copy(state.pos)
        end
        if q.rare and q.opportunityArea and not log and not item and state.level>=(q.opportunityMinLevel or q.level)
            and not state.done[q.id] and not state.skip[q.id] and Q.Core.Distance(state.pos,q.opportunityArea)<=.06 then
            notices[#notices+1]="Optional rare nearby: "..q.name..". Loot the starter if encountered; do not assume a spawn or guaranteed drop."
        end
        if q.pickupOnly then
            if not log then
                q.pendingAction="PICK UP";q.stageOnly=true;q.minutes=.15
                q.pendingLabel="Check availability: "..q.name
                if (state.offered or {})[q.id] then
                    q.start=Q.Core.Copy(state.pos);q.start.source="Observed quest offer"
                    q.pendingLabel="Accept "..q.name.." (offered now)"
                end
            else q.stageOnly=not q.finish end
        end
        local confirmedOutside=not Q.Core.IsLocal(state.pos) and Q.Core.IsMapPoint(state.pos)
            and (not state.map or state.map==Q.Pack.mapID)
            and (state.offered or {})[q.id]==true and not log and not item
        if confirmedOutside then
            -- An actual open offer is valid outside authored coverage too.
            -- It authorizes only this manual pickup, never the seed's future
            -- objective/recipient or a speculative continuation through it.
            q.dynamicOffer=true;q.offeredOnly=true;q.acceptedOnly=nil;q.ownedOnly=nil
            q.itemStartID=nil;q.objective=nil;q.finish=nil;q.tasks=nil
            q.stageOnly=true;q.minutes=.15
        end
        if q.dynamicOffer and (state.offered or {})[q.id]==true then
            -- The client is offering this quest now. Inherited optional database
            -- restrictions must not replace that availability evidence.
            q.disabled=false;q.all=nil;q.any=nil;q.minLevel=1
            q.objective=nil;q.finish=nil;q.tasks=nil
            local detail=(state.offerDetails or {})[q.id] or {}
            q.name=type(detail.title)=="string" and detail.title or seed.name
            q.level=type(detail.level)=="number" and detail.level>0 and detail.level<1000 and detail.level or seed.level
            q.start=Q.Core.Copy(state.pos);q.start.source=detail.source or "Observed NPC offer"
        end
        if q.requiredRaceID and state.raceID~=q.requiredRaceID then q.disabled=true end
        if q.requiredClassID and state.classID~=q.requiredClassID then q.disabled=true end
        if q.offeredOnly then
            if not log then
                q.pendingAction="PICK UP"
                q.pendingLabel="Accept "..q.name..(q.start and q.start.source=="Observed quest detail"
                    and " (open quest offer)" or " (offered by NPC)")
                q.stageOnly=true; q.minutes=.15
            elseif log.complete then q.objective=q.finish and Q.Core.Copy(q.finish) or nil end
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
            if not (log and Q.Core.IsMapPoint(q.finish) or Q.Core.IsLocal(q.finish)) then q.finish=nil end
            q.stageOnly=q.pendingAction~=nil or (not (log and log.complete) and (item~=nil or not q.finish))
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
        if q.catalogue and log and log.complete and q.finish then
            q.stageOnly=false;q.objective=Q.Core.Copy(q.finish)
        end
        if q.ownedOnly and log and log.complete and q.finish then
            q.stageOnly=false; q.objective=Q.Core.Copy(q.finish)
        end
        if log and not log.failed and (q.offeredOnly or q.ownedOnly or q.catalogue) and not q.objective then
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
        -- Outside legacy coverage, allow explicit catalogue pickups as well as
        -- accepted work/current offers. Uncatalogued opportunities stay bounded.
        if not Q.Core.IsLocal(state.pos) and not confirmedOutside and not q.catalogue then q.acceptedOnly=true end
        if q.catalogue and not log and ((state.map and state.map~=Q.Pack.mapID) or not Q.Core.IsMapPoint(state.pos)) then
            q.disabled=true
        end
        result[#result+1]=q
    end
    return result,notices
end
