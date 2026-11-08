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
        and q.start and (q.objective or q.pendingAction) and (q.finish or q.stageOnly)
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
        if q.pendingAction then
            nodes[#nodes+1]={id=q.id,quest=q,action=q.pendingAction,target=q.start,
                key=q.id..":"..q.pendingAction,label=q.pendingLabel,
                minutes=q.pendingAction=="ACCEPT ITEM" and .15 or (q.minutes or 2)}
        else
            if not log then nodes[#nodes+1]={id=q.id,quest=q,action="PICK UP",target=q.start,key=q.id..":pickup",minutes=.15,
                label=q.onRoutePickup and (q.name..(q.pickupObserved and "" or " (check availability)")) or nil} end
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
            if q.finish then nodes[#nodes+1]={id=q.id,quest=q,action="TURN IN",target=q.finish,key=q.id..":return",minutes=.15} end
        end
    end
    local accepted,finished={},{}
    for _,q in ipairs(selected) do if s.log[q.id] then accepted[q.id]=true end end
    local steps,position,total,walking={},s.pos,0,0
    while #nodes>0 do
        local best,bestCost
        for i,node in ipairs(nodes) do
            local ready=node.action=="PICK UP" or node.action=="LOOT ITEM" or node.action=="ACCEPT ITEM" or accepted[node.id]
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
                -- A bounded continuation may finish already grouped field work
                -- before departing even when that companion's return is unknown.
                if node.quest.fieldContinuation then
                    for _,other in ipairs(nodes) do
                        if other.action=="DO" and other.quest.fieldCompanion then ready=false end
                    end
                end
                for _,other in ipairs(nodes) do if other.id==node.id and other.action~="TURN IN" then ready=false end end
                -- Accepted independent work near this quest's objective shares
                -- the return phase. Do not greedily visit the hub between its
                -- objectives, or let previous-step stickiness force that visit.
                -- Only snapshot-accepted quests participate, so a prerequisite
                -- turn-in can never be blocked by its still-locked child.
                local log=s.log[node.id]
                local immediate=log and log.complete and s.pos and C.Distance(s.pos,node.target)<=.008
                if log and not immediate and not node.quest.timed and not node.quest.stageOnly and not node.quest.pendingAction then
                    local area=log.complete and s.pos or node.quest.objective
                    for _,other in ipairs(nodes) do
                        local otherLog=s.log[other.id]
                        if other.id~=node.id and other.action=="DO" and otherLog and accepted[other.id]
                            and not other.quest.timed and not other.quest.stageOnly and not other.quest.pendingAction
                            and area and other.quest.finish and C.Distance(node.target,other.quest.finish)<=.02
                            and C.Distance(area,other.target)<=.06 then ready=false end
                    end
                end
            end
            -- An optional on-route pickup must be visited before the selected
            -- leg that would pass it. The candidate was eligible in the real
            -- snapshot, so this edge never waits on a projected prerequisite.
            for _,other in ipairs(nodes) do
                if other.action=="PICK UP" and other.quest.onRouteBefore==node.key then ready=false end
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
    local xp,scoreXP,risk,gear=0,0,0,0
    local stageOnly=false
    -- Reserve the known return journey for drop opportunities even though a
    -- return cannot be instructed until the player actually accepts the quest.
    -- Unknown returns get a conservative allowance, not an invented waypoint.
    local reserved=0
    for _,q in ipairs(selected) do
        if q.stageOnly then
            stageOnly=true
            reserved=math.max(reserved,q.finish and C.Travel(position,q.finish) or 3)
        end
        xp=xp+(q.xp or 100)
        -- Half credit is a conservative ranking heuristic for unresolved
        -- stages, not a measured drop probability or promised reward.
        scoreXP=scoreXP+(q.xp or 100)*(q.stageOnly and .5 or 1)
        risk=math.max(risk,math.max(0,(q.level or 1)-s.level-1)*.6+(q.risk or 0))
        gear=math.max(gear,q.gear or 0)
    end
    total=total+reserved
    local trip={stageOnly=stageOnly,reserved=reserved,steps=steps,quests=selected,ids=ids,key=keyFor(ids),minutes=math.max(.2,total),walking=walking,
        xp=xp,risk=risk,gear=gear,completed=finished,urgent=selected[1] and selected[1].timed or false}
    trip.score=scoreXP/trip.minutes/(1+risk)
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
                if pre==id then depends=true elseif not s.done[pre] and not trip.completed[pre] then ready=false end
            end
            if child.any and #child.any>0 then ready=false end
            if depends and ready and not child.stageOnly and not child.acceptedOnly
                and child.start and child.objective and child.finish and not child.disabled and not s.skip[child.id] and not s.done[child.id]
                and not contains(trip,child.id) and (child.minLevel or 1)<=s.level then
                local nextCost=cost+C.Travel(position,child.start)+C.Travel(child.start,child.objective)
                    +(child.minutes or 5)+C.Travel(child.objective,child.finish)+.3
                if (child.gear or 0)>best then best,extra=child.gear,nextCost end
                visit(child.id,child.finish,nextCost,depth-1,seen)
            end
        end
    end
    local endPoint=trip.steps[#trip.steps].lastTarget
    for _,q in ipairs(trip.quests) do if not q.stageOnly then visit(q.id,endPoint,0,3,{}) end end
    return best,extra
end

-- Once a useful trip is chosen, consider already-accepted companions by
-- combined-versus-separate completion cost rather than instantaneous XP/min.
-- Near-complete quests otherwise become impossible to batch with slower work.
local function batchCompanions(best,available,s,fastest)
    if best.stageOnly or best.urgent or best.nearbyReturns then return best end
    for _,q in ipairs(best.quests) do if q.timed then return best end end
    local anchors=C.Copy(best.quests)
    local addedWork=0
    for _=1,3 do
        if #best.quests>=4 then break end
        local addition,saving,chosenWork
        for _,q in ipairs(available) do
            local log=s.log[q.id]
            if log and not log.complete and not log.failed and usable(q,s) and not contains(best,q.id)
                and not q.timed and not q.pendingAction and not q.stageOnly and q.finish and q.objective
                and ((q.xp or 0)>0 or (q.gearKnown and (q.gear or 0)>=.1)) then
                local work,near,unfinished=0,false,false
                for _,anchor in ipairs(anchors) do
                    local anchorLog=s.log[anchor.id]
                    if anchorLog and not anchor.stageOnly and not anchor.pendingAction and anchor.finish
                        and C.Distance(q.finish,anchor.finish)<=.02 then
                        local area=anchorLog.complete and s.pos or anchor.objective
                        local fits=area~=nil
                        for _,task in ipairs(T.Tasks(q)) do
                            local progress=T.Progress(q,task,log)
                            if progress<1 and (not task.target or not area or C.Distance(area,task.target)>.06) then fits=false end
                        end
                        if fits then near=true end
                    end
                end
                for _,task in ipairs(T.Tasks(q)) do
                    local progress=T.Progress(q,task,log)
                    if progress<1 then unfinished=true end
                    work=work+(task.minutes or q.minutes or 5)*(1-progress)
                end
                -- A six-minute total companion-work allowance bounds delayed
                -- reward collection. No new higher-risk combat is introduced.
                if near and unfinished and addedWork+work<=6 then
                    local selected=C.Copy(best.quests); selected[#selected+1]=q
                    if slotsOK(selected,s) then
                        local combined=T.Build(selected,s)
                        local separateState=C.Copy(s)
                        separateState.pos=best.steps[#best.steps].lastTarget; separateState.previous=nil
                        local separate=T.Build({q},separateState)
                        local budgetOK=not best.gearDetour or (combined and combined.minutes+(best.gearExtra or 0)-fastest.minutes<=(s.budget or 10))
                        local saved=combined and separate and best.minutes+separate.minutes-combined.minutes or 0
                        if combined and separate and budgetOK and combined.risk<=best.risk and saved>.01
                            and combined.walking+.000001<best.walking+separate.walking
                            and (not addition or saved>saving or (saved==saving and q.id<addition.quests[#addition.quests].id)) then
                            addition,saving,chosenWork=combined,saved,work
                        end
                    end
                end
            end
        end
        if not addition then break end
        addition.batchedReturn=true
        addition.batchSavings=(best.batchSavings or 0)+saving
        addition.gear=math.max(addition.gear,best.gear)
        addition.gearExtra=best.gearExtra; addition.gearDetour=best.gearDetour
        addition.priority=addition.score*(best.score>0 and best.priority/best.score or 1)
        best=addition; addedWork=addedWork+chosenWork
    end
    return best
end

-- Geometric proximity to an already selected route, not terrain pathfinding.
local function segmentDistance(point,a,b)
    local dx,dy=b.x-a.x,b.y-a.y
    local length=dx*dx+dy*dy
    local t=length>0 and ((point.x-a.x)*dx+(point.y-a.y)*dy)/length or 0
    t=math.max(0,math.min(1,t))
    return C.Distance(point,{x=a.x+t*dx,y=a.y+t*dy})
end

-- Low-work pickups along the chosen outing can be useful even when their
-- marginal XP/minute would lose a solo-score contest. Preserve the chosen
-- destination/pin and bound actual added walking, work and quest-log capacity.
local function pickupsAlongRoute(best,quests,s,fastest)
    if best.urgent or best.nearbyReturns or best.stageOnly then return best end
    for _,q in ipairs(best.quests) do if q.timed then return best end end
    local baselineMinutes,baselineWalking=best.minutes,best.walking
    for _=1,3 do
        if #best.quests>=4 then break end
        local addition,extraCost,selectedID
        for _,q in ipairs(quests) do
            if not s.log[q.id] and not contains(best,q.id) and usable(q,s)
                and not q.pendingAction and not q.stageOnly and not q.timed
                and q.start and q.objective and q.finish
                and C.IsLocal(q.start) and C.IsLocal(q.objective) and C.IsLocal(q.finish)
                and ((q.xp or 0)>0 or (q.gearKnown and (q.gear or 0)>=.1)) then
                local work=0
                for _,task in ipairs(T.Tasks(q)) do work=work+(task.minutes or q.minutes or 5) end
                local before,finishNear,position=nil,false,s.pos
                for _,step in ipairs(best.steps) do
                    for _,member in ipairs(step.members) do
                        if not before and position and (C.Distance(s.pos,q.start)<=.012
                            or segmentDistance(q.start,position,member.target)<=.012) then before=member.key end
                        if (member.action=="DO" or member.action=="TURN IN")
                            and C.Distance(q.finish,member.target)<=.03 then finishNear=true end
                        position=member.target
                    end
                end
                if before and finishNear and work<=1 then
                    local selected=C.Copy(best.quests)
                    local candidate=C.Copy(q)
                    candidate.onRoutePickup=true; candidate.onRouteBefore=before
                    candidate.pickupObserved=s.offered and s.offered[q.id]==true or false
                    selected[#selected+1]=candidate
                    if slotsOK(selected,s) then
                        local combined=T.Build(selected,s)
                        local extra=combined and combined.minutes-baselineMinutes or math.huge
                        local budgetOK=not best.gearDetour or (combined and combined.minutes+(best.gearExtra or 0)-fastest.minutes<=(s.budget or 10))
                        if combined and budgetOK and combined.risk<=best.risk
                            and combined.walking-baselineWalking<=.5 and extra<=1.5
                            and (not addition or extra<extraCost or (extra==extraCost and q.id<selectedID)) then
                            addition,extraCost,selectedID=combined,extra,q.id
                        end
                    end
                end
            end
        end
        if not addition then break end
        addition.onRoutePickups=true
        addition.pickupExtraMinutes=extraCost
        addition.gear=math.max(addition.gear,best.gear)
        addition.gearExtra=best.gearExtra; addition.gearDetour=best.gearDetour
        addition.batchedReturn=best.batchedReturn; addition.batchSavings=best.batchSavings
        addition.priority=addition.score*(best.score>0 and best.priority/best.score or 1)
        best=addition
    end
    return best
end

-- Numeric, bounded outing context survives a singleton replan and UI reload.
-- Only actually accepted quests sharing current objective work can establish it.
function T.RetainOuting(old,s,route)
    if s.map~=Q.Pack.mapID or not C.IsMapPoint(s.pos) or s.logAvailable==false then return nil end
    local function retain(value)
        if type(value)~="table" or value.map~=s.map or not C.IsMapPoint(value.center)
            or C.Distance(s.pos,value.center)>.12 then return nil end
        local ids,seen={},{}
        for i,id in ipairs(type(value.ids)=="table" and value.ids or {}) do
            if i>4 then break end
            if type(id)=="number" and id>0 and id<1000000000 and id==math.floor(id)
                and not seen[id] and s.log[id] and not s.log[id].failed
                and not (s.done or {})[id] and not (s.skip or {})[id] then
                ids[#ids+1]=id;seen[id]=true
            end
        end
        if #ids<2 then return nil end
        return {map=s.map,center={x=value.center.x,y=value.center.y},ids=ids}
    end
    local first=route and route[1]
    if first and first.action=="DO" and C.IsMapPoint(first.target) then
        local ids={}
        for _,member in ipairs(first.members or {}) do
            local log=s.log[member.id]
            if log and not log.complete then ids[#ids+1]=member.id end
        end
        if #ids>=2 then
            local current=retain({map=s.map,center=first.target,ids=ids})
            if current then return current end
        end
    end
    return retain(old)
end

-- Retained field outings allow up to six estimated work minutes before an
-- elective return; legacy previous-trip evidence keeps its tighter limit. Unknown recipients cannot satisfy shared-return matching;
-- this policy uses prior accepted grouping and present work proximity instead.
-- It never projects completion/chain unlocks for a companion with no recipient.
local function continueFieldWork(available,s)
    local outing=T.RetainOuting(s.outing,s)
    if not outing and (not s.previous or type(s.previous.tripKey)~="string" or not s.pos) then return nil end
    local prior={}
    if outing then
        for _,id in ipairs(outing.ids) do prior[id]=true end
    else
        for id in s.previous.tripKey:gmatch("%d+") do prior[tonumber(id)]=true end
    end
    local workLimit,range=outing and 6 or 2,outing and .06 or .04
    if s.pin and not prior[s.pin] then return nil end
    local returns,companions={},{}
    local work=0
    for _,q in ipairs(available) do
        local log=s.log[q.id]
        if prior[q.id] and log and not log.failed and not q.timed and not q.pendingAction then
            if log.complete and q.finish and not q.stageOnly then
                returns[#returns+1]=q
            elseif not log.complete and (outing or (q.stageOnly and not q.finish)) and log.progressKnown~=false
                and type(log.progress)=="number" and log.progress>=(outing and 0 or .5) and log.progress<1
                and (q.level or 1)<=s.level+1 and (q.risk or 0)<=0 then
                local fits=true
                local remaining=0
                for _,task in ipairs(T.Tasks(q)) do
                    local progress,known=T.Progress(q,task,log)
                    if not known or (progress<1 and (not task.target or C.Distance(s.pos,task.target)>range)) then fits=false end
                    remaining=remaining+(task.minutes or q.minutes or 5)*(1-progress)
                end
                if fits and remaining>0 and work+remaining<=workLimit then
                    local copy=C.Copy(q);copy.fieldCompanion=true;copy.fieldContinuation=true
                    companions[#companions+1]=copy;work=work+remaining
                end
            end
        end
    end
    if #returns==0 or #companions==0 or #returns+#companions>4 then return nil end
    local selected={}
    for _,q in ipairs(returns) do local copy=C.Copy(q);copy.fieldContinuation=true;selected[#selected+1]=copy end
    for _,q in ipairs(companions) do selected[#selected+1]=q end
    -- A pin within the prior trip must remain in this actual continuation.
    if s.pin then
        local found=false;for _,q in ipairs(selected) do if q.id==s.pin then found=true end end
        if not found then return nil end
    end
    local trip=T.Build(selected,s)
    if trip then trip.fieldContinuation=true end
    return trip
end

-- Revalidate the previous bounded outing independently of greedy insertion.
-- A still-useful group may no longer be rediscovered by score-improving steps.
local function rebuildPrevious(quests,s)
    local key=s.previous and s.previous.tripKey
    if type(key)~="string" or #key>64 then return nil end
    local selected,seen,parts={},{},{}
    local byID={}; for _,q in ipairs(quests) do byID[q.id]=q end
    for token in key:gmatch("[^,]+") do
        if not token:match("^%d+$") then return nil end
        local id=tonumber(token)
        if not id or id<=0 or id>=1000000000 or seen[id] or not byID[id] then return nil end
        selected[#selected+1]=byID[id];seen[id]=true;parts[#parts+1]=token
        if #selected>4 then return nil end
    end
    if #selected==0 or table.concat(parts,",")~=key or not slotsOK(selected,s) then return nil end
    -- Project prerequisites only through currently usable, resolved members of
    -- this same group. An unknown stage never manufactures a chain unlock.
    local projected=C.Copy(s);local admitted,count={},0
    for _=1,#selected do
        local changed=false
        for _,q in ipairs(selected) do
            if #selected>1 and q.timed then return nil end
            if not admitted[q.id] and usable(q,projected) then
                admitted[q.id]=true;count=count+1;changed=true
                if not q.stageOnly then projected.done[q.id]=true;projected.log[q.id]=nil end
            end
        end
        if not changed then break end
    end
    if count~=#selected then return nil end
    local trip=T.Build(selected,s)
    return trip and trip.key==key and trip or nil
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
    -- Cash in observed completed quests beside the player before scoring an
    -- elective departure. Whole-trip XP/gear scores, pickup bonuses, pins and
    -- previous-route hysteresis must not send the player away from this stop.
    -- This small geometric radius is proximity evidence, not NPC interaction
    -- range or proof that a quest is complete; completion comes from the log.
    local nearby={}
    for _,q in ipairs(available) do
        local log=s.log[q.id]
        if log and log.complete and not q.stageOnly and not q.pendingAction
            and q.finish and s.pos and C.Distance(s.pos,q.finish)<=.008 then
            nearby[#nearby+1]=q
        end
    end
    if #nearby>0 then
        table.sort(nearby,function(a,b)
            local da,db=C.Distance(s.pos,a.finish),C.Distance(s.pos,b.finish)
            if da~=db then return da<db end
            return a.id<b.id
        end)
        while #nearby>4 do table.remove(nearby) end
        local returnState=C.Copy(s); returnState.previous=nil
        local trip=T.Build(nearby,returnState)
        trip.nearbyReturns=true
        return trip
    end
    local continued=continueFieldWork(available,s)
    if continued then return continued end
    -- Consider nearby chain unlocks as insertions too. A child cannot form a
    -- trip alone: Build enforces its prerequisite turn-ins before pickup.
    -- Batch the reachability passes so one pass means one prerequisite depth.
    local possible=C.Copy(s)
    for _=1,3 do
        local newly={}
        for _,q in ipairs(quests) do
            if usable(q,possible) and not q.stageOnly then newly[q.id]=true end
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
    -- Discovery can expose a full quest log. Bound expensive insertion work
    -- to sixteen candidates; score every candidate cheaply before shortlisting.
    -- Pins are retained, and accepted timed deliveries were handled above.
    if #available>16 then
        local rank={}
        for _,q in ipairs(available) do
            local log=s.log[q.id]
            local complete=log and log.complete
            local target=complete and q.finish or (q.pendingAction and q.start or q.objective)
            local cost=C.Travel(s.pos,log and target or q.start)
            if not log and not q.pendingAction then cost=cost+C.Travel(q.start,q.objective) end
            if not complete then
                cost=cost+(q.pendingAction=="ACCEPT ITEM" and .15 or (q.minutes or 5)*(1-(log and log.progress or 0)))
                cost=cost+(q.finish and C.Travel(target,q.finish) or 3)
            end
            local score=(q.xp or 100)*(q.stageOnly and .5 or 1)/math.max(.2,cost)
            if s.mode~="xp" then score=score*(1+math.min(q.gear or 0,1)*1.5) end
            rank[q.id]=score
        end
        table.sort(available,function(a,b)
            if a.id==s.pin or b.id==s.pin then return a.id==s.pin and b.id~=s.pin end
            if rank[a.id]~=rank[b.id] then return rank[a.id]>rank[b.id] end
            return a.id<b.id
        end)
        -- Preserve prerequisite closure: a projected child cannot consume a
        -- shortlist slot until its required returns are retained too.
        local shortlist,retained,projected={},{},C.Copy(s)
        for _=1,16 do
            local nextQuest
            for _,q in ipairs(available) do
                if not retained[q.id] and C.Eligible(q,projected) then nextQuest=q; break end
            end
            if not nextQuest then break end
            shortlist[#shortlist+1]=nextQuest; retained[nextQuest.id]=true
            if not nextQuest.stageOnly then
                projected.done[nextQuest.id]=true; projected.log[nextQuest.id]=nil
            end
        end
        available=shortlist
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
    local retained=rebuildPrevious(quests,s)
    if retained then
        -- Prefer a fresh rebuild over an incidental duplicate. It reflects the
        -- current log, capacity and metadata, not saved coordinates or scores.
        for i=#candidates,1,-1 do if candidates[i].key==retained.key then table.remove(candidates,i) end end
        candidates[#candidates+1]=retained
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
    best=batchCompanions(best,available,s,fastest)
    return pickupsAlongRoute(best,quests,s,fastest)
end

local function forecast(quests,state,limit,initialTrip)
    local s=C.Copy(state)
    s.done=s.done or {}; s.skip=s.skip or {}; s.log=s.log or {}
    local route,trips={},{}
    -- Forecast at most three complete trips, unlocking chains only on returns.
    for index=1,3 do
        local trip=index==1 and initialTrip or nil
        if not trip then trip=T.Choose(quests,s) end
        if not trip then break end
        trip.index=index; trips[#trips+1]=trip
        for _,step in ipairs(trip.steps) do
            step.trip=index; step.tripKey=trip.key
            if #route<(limit or 24) then route[#route+1]=step end
        end
        for _,q in ipairs(trip.quests) do
            if trip.completed[q.id] then
                if s.log[q.id] and s.freeSlots then s.freeSlots=s.freeSlots+1 end
                s.done[q.id]=true; s.log[q.id]=nil
            end
        end
        -- Rebuild from observed bags/log before forecasting past an unresolved
        -- item start or a quest whose eventual return is not yet known.
        if trip.stageOnly then break end
        s.pos=trip.steps[#trip.steps].lastTarget; s.previous=nil
    end
    return route,trips
end

-- Inspect the existing bounded forecast before leaving a pickup behind. Only
-- combine an independent ready-return prefix: those destinations are observed,
-- need no unknown objective work and cannot wait on projected prerequisites.
-- If the prefix plus a pickup cannot fit four quests, keep the original plan.
local function multiStopPickup(quests,state,trips)
    local first=trips[1]
    if not first or first.urgent or first.nearbyReturns or first.stageOnly then return nil end
    local selected,seen={},{}
    for prefix,trip in ipairs(trips) do
        if trip.urgent or trip.nearbyReturns or trip.stageOnly or trip.gearDetour then break end
        for _,q in ipairs(trip.quests) do
            local log=state.log and state.log[q.id]
            if not log or not log.complete or log.failed or q.timed or q.pendingAction or q.stageOnly then return nil end
            if not seen[q.id] then selected[#selected+1]=q;seen[q.id]=true end
        end
        -- Reserve at least one slot for the pickup, not a fifth quest.
        if #selected>=4 then break end
        if prefix>=2 then
            local base=T.Build(selected,state)
            if not base then return nil end
            base.priority=base.score
            local combined=pickupsAlongRoute(base,quests,state,base)
            if combined.onRoutePickups then
                combined.multiStopPickups=true;combined.lookaheadTrips=prefix
                return combined
            end
        end
    end
end

function T.Plan(quests,state,limit)
    state=C.Copy(state)
    state.done=state.done or {};state.skip=state.skip or {};state.log=state.log or {}
    local route,trips=forecast(quests,state,limit)
    local combined=multiStopPickup(quests,state,trips)
    if combined then
        -- Reforecast the remainder from the combined trip's projected returns;
        -- do not append the old later pickup or double-credit its reward/slot.
        return forecast(quests,state,limit,combined)
    end
    return route,trips
end
