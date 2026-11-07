local _, Q = ...
Q.Core = {}
local C = Q.Core

function C.Copy(t)
    local r = {}
    for k, v in pairs(t or {}) do r[k] = type(v) == "table" and C.Copy(v) or v end
    return r
end

function C.Distance(a, b)
    if not a or not b then return 0 end
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
end

function C.Travel(a, b)
    -- Conservative geometric estimate; not a terrain/pathfinding service.
    return C.Distance(a,b) * 3000 / 7 / 60 * 1.5
end

function C.Eligible(q, s)
    if s.done[q.id] or s.skip[q.id] then return false end
    if s.log[q.id] then return true end
    if q.disabled or (q.minLevel or 1) > s.level then return false end
    for _, id in ipairs(q.all or {}) do if not s.done[id] then return false end end
    if q.any and #q.any > 0 then
        local found = false
        for _, id in ipairs(q.any) do if s.done[id] then found = true end end
        if not found then return false end
    end
    return true
end

local function candidate(q, s, quests)
    if not C.Eligible(q,s) then return end
    local log = s.log[q.id]
    if log and log.failed then return end
    local action = not log and "PICK UP" or (log.complete and "TURN IN" or "DO")
    local target
    if action == "PICK UP" then target=q.start
    elseif action == "TURN IN" then target=q.finish
    else target=q.objective end
    if not target then return end
    local travel = C.Travel(s.pos,target)
    local work = (q.minutes or 5) * (1 - (log and log.progress or 0))
    local total = travel
    if action == "PICK UP" then total = total + .15 + C.Travel(q.start,q.objective) + work + C.Travel(q.objective,q.finish)
    elseif action == "DO" then total = total + work + C.Travel(q.objective,q.finish) end
    total = math.max(.2,total + .15)
    local xp = q.xp or 100
    local score = xp / total
    local reasons = {string.format("~%.1f min to reward; %s XP %d",total,q.xpObserved and "observed" or "estimated",xp)}
    if action=="DO" and log.text and log.text~="" then reasons[#reasons+1]=log.text end
    local overlap = 0
    if action == "DO" then
        for _, other in ipairs(quests) do
            local ol = s.log[other.id]
            if other.id ~= q.id and ol and not ol.complete and not ol.failed and not s.skip[other.id]
                and C.Distance(q.objective,other.objective) < .035 then overlap = overlap + 1 end
        end
    end
    if overlap > 0 then
        score = score * (1 + math.min(overlap,2)*.25)
        reasons[#reasons+1] = "Nearby objectives overlap with "..overlap.." accepted quest(s)"
    end
    -- Small bounded lookahead, not credit for XP already earned.
    local unlocks = 0
    for _, other in ipairs(quests) do
        if not s.done[other.id] and not s.skip[other.id] then
            for _, id in ipairs(other.all or {}) do if id == q.id then unlocks = unlocks + 1 end end
        end
    end
    if unlocks > 0 then score=score*1.1; reasons[#reasons+1]="Unlocks a later quest in this pack" end
    local improvement = q.gear or 0
    local gearMinutes=total
    -- Limited chain lookahead: include the future work before crediting a
    -- learned downstream reward. Never assume a reward exists without data.
    local function downstream(id,position,minutes,depth,visited)
        if depth==0 or visited[id] then return end
        visited=C.Copy(visited); visited[id]=true
        for _,child in ipairs(quests) do
            local depends,otherReady=false,true
            for _,pre in ipairs(child.all or {}) do
                if pre==id then depends=true elseif not s.done[pre] then otherReady=false end
            end
            if child.any and #child.any>0 then
                local ready=false
                for _,pre in ipairs(child.any) do if s.done[pre] then ready=true end end
                otherReady=otherReady and ready
            end
            if depends and otherReady and not child.disabled and not s.done[child.id] and not s.skip[child.id]
                and (child.minLevel or 1)<=s.level then
                local cost=minutes+C.Travel(position,child.start)+C.Travel(child.start,child.objective)
                    +(child.minutes or 5)+C.Travel(child.objective,child.finish)+.3
                if (child.gear or 0)>improvement then
                    improvement=child.gear; gearMinutes=cost
                    reasons[#reasons+1]="Leads toward a learned reward from "..child.name
                end
                downstream(child.id,child.finish,cost,depth-1,visited)
            end
        end
    end
    downstream(q.id,q.finish,total,3,{})
    local danger = math.max(0,(q.level or 1)-s.level-1)
    score = score / (1 + danger*.6 + (q.risk or 0))
    if danger > 0 then reasons[#reasons+1]="Above your level: expect slower combat" end
    if improvement > 0 then
        reasons[#reasons+1]=string.format("Potential reward: +%.0f%% stat score (not DPS)",improvement*100)
    else
        reasons[#reasons+1]=q.gearKnown and "No scored reward upgrade" or "Reward gear not yet known"
    end
    return {id=q.id, name=q.name, action=action, target=target, minutes=total, gearMinutes=gearMinutes,
        score=score, gear=improvement, reasons=reasons, quest=q}
end

function C.Plan(quests, state, limit)
    local s = C.Copy(state)
    s.skip=s.skip or {}; s.done=s.done or {}; s.log=s.log or {}
    local route = {}
    for _=1,limit or 12 do
        local choices, fastest = {}, nil
        for _, q in ipairs(quests) do
            local c = candidate(q,s,quests)
            if c then
                choices[#choices+1]=c
                if not fastest or c.score > fastest.score or (c.score==fastest.score and c.id<fastest.id) then fastest=c end
            end
        end
        if not fastest then break end
        local best, bestScore = fastest, -math.huge
        for _, c in ipairs(choices) do
            local score = c.score
            local detour=math.max(0,c.gearMinutes-fastest.minutes)
            if s.mode ~= "xp" and c.gear >= .1 and detour <= (s.budget or 10) then
                score=score*(1+math.min(c.gear,1)*(s.mode=="gear" and 3 or 1.5))
                c.reasons[#c.reasons+1]=string.format("Gear detour within your %.0f min allowance",s.budget or 10)
            end
            if s.pin == c.id then score=math.huge end
            if score > bestScore or (score==bestScore and c.id<best.id) then best,bestScore=c,score end
        end
        route[#route+1]=best
        s.pos=best.target
        if best.action=="PICK UP" then s.log[best.id]={progress=0}
        elseif best.action=="DO" then s.log[best.id]={complete=true,progress=1}
        else s.log[best.id]=nil; s.done[best.id]=true; if s.pin==best.id then s.pin=nil end end
    end
    return route
end
