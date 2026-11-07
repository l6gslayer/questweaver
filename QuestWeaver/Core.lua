local _, Q = ...
Q.Core = {}
local C = Q.Core

function C.Copy(t)
    local r = {}
    for k, v in pairs(t or {}) do r[k] = type(v) == "table" and C.Copy(v) or v end
    return r
end

-- All discovered destinations must share the starter map's coordinate space.
function C.IsLocal(pos)
    return type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number"
        and pos.x>=.50 and pos.x<=.65 and pos.y>=.23 and pos.y<=.50
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
    if q.acceptedOnly then return false end
    if q.ownedOnly and not (s.itemStarts and s.itemStarts[q.id]) then return false end
    if q.offeredOnly and not (s.offered and s.offered[q.id]) then return false end
    if q.disabled or (q.minLevel or 1) > s.level then return false end
    for _, id in ipairs(q.all or {}) do if not s.done[id] then return false end end
    if q.any and #q.any > 0 then
        local found = false
        for _, id in ipairs(q.any) do if s.done[id] then found = true end end
        if not found then return false end
    end
    return true
end
