local _,Q=...
Q.Catalogues={packs={}}
local Z=Q.Catalogues

function Z.Register(pack)
    assert(type(pack)=="table" and type(pack.mapID)=="number" and type(pack.areaID)=="number"
        and type(pack.name)=="string" and type(pack.quests)=="table","Invalid zone catalogue")
    assert(not Z.packs[pack.mapID],"Duplicate zone catalogue")
    local seen={}
    for _,q in ipairs(pack.quests) do
        assert(type(q.id)=="number" and not seen[q.id],"Duplicate quest in zone catalogue")
        seen[q.id]=true
    end
    Z.packs[pack.mapID]=pack
    return pack
end

function Z.Select(map)
    local pack=Z.packs[map]
    if pack then Q.Pack=pack end
    -- Retain the last pack during loading, but never claim unsupported coverage.
    return pack
end

Q.Pack.areaID=141
Q.Pack.faction="Alliance"
Z.Register(Q.Pack)
