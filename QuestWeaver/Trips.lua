local _, Q = ...
local C=Q.Core
Q.Trips={}
local T=Q.Trips

function T.Tasks(q)
    return q.tasks or {{label=q.name,target=q.objective,minutes=q.minutes or 5}}
end

function T.Progress(q,task,log)
    if not log then return 0,false end
    if log.complete then return 1,true end
    if q.tasks then
        -- Text matching is conservative: a changed/localized objective remains
        -- unresolved rather than silently completing the wrong objective.
        for _,row in ipairs(log.objectives or {}) do
            if task.match and row.text and row.text:lower():find(task.match:lower(),1,true) then
                if row.finished then return 1,true end
                return math.min(1,(row.numFulfilled or 0)/math.max(1,row.numRequired or 1)),true
            end
        end
        return 0,false
    end
    return math.max(0,math.min(1,log.progress or 0)),log.progress~=nil and log.progressKnown~=false
end

local function usable(q,s)
    return C.Eligible(q,s) and not (s.log[q.id] and s.log[q.id].failed)
        and q.start and q.finish and q.objective
end

local function keyFor(ids)
    local sorted={}
    for _,id in ipairs(ids) do sorted[#sorted+1]=id end
    table.sort(sorted)
    return table.concat(sorted,",")
end

-- Build a precedence-constrained walk through pickup, objective and return
-- nodes. Travel is paid per leg; shared-source combat is paid once per group.
function T.Build(selected,s)
    local nodes,ids={},{}
    for _,q in ipairs(selected) do
        ids[#ids+1]=q.id
        local log=s.log[q.id]
        if not log then nodes[#nodes+1]={id=q.id,quest=q,action="PICK UP",target=q.start,key=q.id..":pickup",minutes=.15} end
        if not (log and log.complete) then
            local taskCount=0
            for index,task in ipairs(T.Tasks(q)) do
                local progress=T.Progress(q,task,log)
                if progress<1 and task.target then
                    nodes[#nodes+1]={id=q.id,quest=q,action="DO",target=task.target,
                        key=q.id..":task:"..index,task=index,label=task.label,
                        combatKey=task.combatKey,minutes=(task.minutes or q.minutes or 5)*(1-progress)}
                    taskCount=taskCount+1
                end
            end
            if taskCount==0 then
                nodes[#nodes+1]={id=q.id,quest=q,action="DO",target=q.objective,
                    key=q.id..":verify",label="Check remaining requirements: "..q.name,minutes=.5}
            end
        end
        nodes[#nodes+1]={id=q.id,quest=q,action="TURN IN",target=q.finish,key=q.id..":return",minutes=.15}
    end
    local accepted,finished={},{}
    for _,q in ipairs(selected) do if s.log[q.id] then accepted[q.id]=true end end
    local steps,position,total,walking={},s.pos,0,0
    while #nodes>0 do
        local best,bestCost
        for i,node in ipairs(nodes) do
            local ready=node.action=="PICK UP" or accepted[node.id]
            if node.action=="PICK UP" then
                for _,id in ipairs(node.quest.all or {}) do if not s.done[id] and not finished[id] then ready=false end end
                local any=node.quest.any
                if any and #any>0 then
                    local found=false
                    for _,id in ipairs(any) do if s.done[id] or finished[id] then found=true end end
                    ready=ready and found
                end
            end
            if node.action=="TURN IN" then
                for _,other in ipairs(nodes) do if other.id==node.id and other.action~="TURN IN" then ready=false end end
            end
            if ready then
                local cost=C.Travel(position,node.target)
                -- Collect useful nearby pickups before departing the hub.
                if node.action=="PICK UP" and C.Distance(position,node.target)<=.025 then cost=cost-.3 end
                -- Hysteresis within a trip avoids small position changes
                -- repeatedly reversing the current instruction.
                if s.previous and s.previous.nextKey==node.key then cost=cost-.3 end
                if not best or cost<bestCost or (cost==bestCost and node.key<nodes[best].key) then best,bestCost=i,cost end
            end
        end
        if not best then return nil end
        local node=table.remove(nodes,best)
        local travel=C.Travel(position,node.target)
        walking=walking+travel; total=total+travel+node.minutes; position=node.target
        if node.action=="PICK UP" then accepted[node.id]=true end
        if node.action=="TURN IN" then finished[node.id]=true end
        local prev=steps[#steps]
        -- Batch only genuinely adjacent steps. Never regroup across a turn-in
        -- or an intervening pickup that changes availability.
        if prev and prev.action==node.action and C.Distance(prev.target,node.target)<=.02 then
            prev.members[#prev.members+1]=node
            if node.action=="DO" and node.combatKey then
                local already=prev.combat[node.combatKey] or 0
                total=total-math.min(already,node.minutes)
                prev.combat[node.combatKey]=math.max(already,node.minutes)
            end
            prev.lastTarget=node.target
        else
            prev={action=node.action,target=node.target,lastTarget=node.target,id=node.id,
                name=node.quest.name,key=node.key,members={node},combat={}}
            if node.combatKey then prev.combat[node.combatKey]=node.minutes end
            steps[#steps+1]=prev
        end
    end
    local xp,risk,gear=0,0,0
    for _,q in ipairs(selected) do
        xp=xp+(q.xp or 100)
        risk=math.max(risk,math.max(0,(q.level or 1)-s.level-1)*.6+(q.risk or 0))
        gear=math.max(gear,q.gear or 0)
    end
    local trip={steps=steps,quests=selected,ids=ids,key=keyFor(ids),minutes=math.max(.2,total),walking=walking,
        xp=xp,risk=risk,gear=gear,completed=finished,urgent=selected[1] and selected[1].timed or false}
    trip.score=xp/trip.minutes/(1+risk)
    return trip
end

local function slotsOK(selected,s)
    if not s.freeSlots then return true end
    local needed=0
    for _,q in ipairs(selected) do if not s.log[q.id] then needed=needed+1 end end
    -- Conservatively require room for all planned pickups up front.
    return needed<=s.freeSlots
end

local function contains(trip,id)
    for _,q in ipairs(trip.quests) do if q.id==id then return true end end
    return false
end

local function chainGear(trip,quests,s)
    local best,extra=trip.gear,0
    local function visit(id,position,cost,depth,seen)
        if depth==0 or seen[id] then return end
        seen=C.Copy(seen); seen[id]=true
        for _,child in ipairs(quests) do
            local depends,ready=false,true
            for _,pre in ipairs(child.all or {}) do
                if pre==id then depends=true elseif not s.done[pre] and not contains(trip,pre) then ready=false end
            end
            if child.any and #child.any>0 then ready=false end
            if depends and ready and not child.disabled and not s.skip[child.id] and not s.done[child.id]
                and not contains(trip,child.id) and (child.minLevel or 1)<=s.level then
                local nextCost=cost+C.Travel(position,child.start)+C.Travel(child.start,child.objective)
                    +(child.minutes or 5)+C.Travel(child.objective,child.finish)+.3
                if (child.gear or 0)>best then best,extra=child.gear,nextCost end
                visit(child.id,child.finish,nextCost,depth-1,seen)
            end
        end
    end
    local endPoint=trip.steps[#trip.steps].lastTarget
    for _,q in ipairs(trip.quests) do visit(q.id,endPoint,0,3,{}) end
    return best,extra
end

function T.Choose(quests,s)
    local available,urgent={},nil
    for _,q in ipairs(quests) do
        if usable(q,s) then
            if q.timed and s.log[q.id] then
                if not urgent or q.id<urgent.id then urgent=q end
            else available[#available+1]=q end
        end
    end
    -- Accepted timed deliveries outrank elective batching. Never add detours.
    if urgent then
        local trip=T.Build({urgent},s); trip.urgent=true
        return trip
    end
    -- Consider nearby chain unlocks as insertions too. A child cannot form a
    -- trip alone: Build enforces its prerequisite turn-ins before pickup.
    -- Batch the reachability passes so one pass means one prerequisite depth.
    local possible=C.Copy(s)
    for _=1,3 do
        local newly={}
        for _,q in ipairs(quests) do
            if usable(q,possible) then newly[q.id]=true end
        end
        for id in pairs(newly) do possible.done[id]=true; possible.log[id]=nil end
        for _,q in ipairs(quests) do
            if usable(q,possible) then
                local found=false
                for _,known in ipairs(available) do if known.id==q.id then found=true end end
                if not found then available[#available+1]=q end
            end
        end
    end
    table.sort(available,function(a,b) return a.id<b.id end)
    local candidates={}
    for _,anchor in ipairs(available) do
        if slotsOK({anchor},s) then
            local chosen={anchor}
            local current=T.Build(chosen,s)
            if current then
                candidates[#candidates+1]=current
                -- Bounded insertion: evaluate the marginal effect of each
                -- additional quest on the whole walk, not its solo score.
                for _=1,3 do
                    local addition
                    for _,other in ipairs(available) do
                        if not contains(current,other.id) and not other.timed and not anchor.timed then
                            local proposed=C.Copy(chosen); proposed[#proposed+1]=other
                            if slotsOK(proposed,s) then
                local trip=T.Build(proposed,s)
                                if trip and trip.score>=current.score and (not addition or trip.score>addition.score) then addition=trip end
                            end
                        end
                    end
                    if not addition then break end
                    current=addition; chosen=current.quests; candidates[#candidates+1]=current
                end
            end
        end
    end
    local fastest
    for _,trip in ipairs(candidates) do if not fastest or trip.score>fastest.score then fastest=trip end end
    if not fastest then return nil end
    local best,bestScore,previous=fastest,-math.huge,nil
    for _,trip in ipairs(candidates) do
        local score=trip.score
        local gear,extra=chainGear(trip,quests,s)
        trip.gear=gear; trip.gearExtra=extra
        if s.mode~="xp" and gear>=.1 and math.max(0,trip.minutes+extra-fastest.minutes)<=(s.budget or 10) then
            score=score*(1+math.min(gear,1)*(s.mode=="gear" and 3 or 1.5)); trip.gearDetour=true
        end
        if s.pin and contains(trip,s.pin) then score=score*1000 end
        trip.priority=score
        if score>bestScore then best,bestScore=trip,score end
        if s.previous and trip.key==s.previous.tripKey then previous=trip end
    end
    if previous and previous.priority>=bestScore*.85 and (not s.pin or contains(previous,s.pin)) then best=previous end
    return best
end

function T.Plan(quests,state,limit)
    local s=C.Copy(state)
    s.done=s.done or {}; s.skip=s.skip or {}; s.log=s.log or {}
    local route,trips={},{}
    -- Forecast at most three complete trips, unlocking chains only on returns.
    for index=1,3 do
        local trip=T.Choose(quests,s)
        if not trip then break end
        trip.index=index; trips[#trips+1]=trip
        for _,step in ipairs(trip.steps) do
            step.trip=index; step.tripKey=trip.key
            if #route<(limit or 24) then route[#route+1]=step end
        end
        for _,q in ipairs(trip.quests) do
            if s.log[q.id] and s.freeSlots then s.freeSlots=s.freeSlots+1 end
            s.done[q.id]=true; s.log[q.id]=nil
        end
        s.pos=trip.steps[#trip.steps].lastTarget; s.previous=nil
    end
    return route,trips
end
