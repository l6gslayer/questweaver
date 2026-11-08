local _, Q = ...
-- Original starter pack. Coordinates/XP are approximate Classic baselines,
-- deliberately labeled unverified for Forever. QuestieDB can replace metadata.
local hub={x=.588,y=.443}
local tree={x=.599,y=.413}
local function quest(id,name,level,minLevel,xp,minutes,start,objective,finish,all,note)
    return {id=id,name=name,level=level,minLevel=minLevel,xp=xp,minutes=minutes,
        start=start,objective=objective,finish=finish,all=all,note=note}
end
Q.Pack={mapID=1438, name="Shadowglen and Dolanaar",
    bounds={minX=.50,maxX=.65,minY=.23,maxY=.65}, quests={
    quest(456,"The Balance of Nature",2,1,170,4,hub,{x=.594,y=.462},hub),
    quest(457,"The Balance of Nature",3,1,250,6,hub,{x=.579,y=.412},hub,{456}),
    quest(458,"The Woodland Protector",1,1,40,1,{x=.599,y=.425},{x=.578,y=.452},{x=.578,y=.452}),
    quest(459,"The Woodland Protector",3,1,250,6,{x=.578,y=.452},{x=.563,y=.456},{x=.578,y=.452},{458}),
    quest(916,"Webwood Venom",4,3,360,6,{x=.578,y=.417},{x=.575,y=.328},{x=.578,y=.417},nil,
        "Spider territory; combine with antidote gathering if both quests are accepted."),
    quest(97236,"Fang of Githyiss",5,1,450,2,{x=.566,y=.263},{x=.578,y=.417},{x=.578,y=.417},nil,
        "Optional cave drop: kill and loot Githyiss, then use the fang in your bags to accept. Drop availability is not guaranteed."),
    quest(917,"Webwood Egg",5,1,450,5,{x=.578,y=.417},{x=.567,y=.264},{x=.578,y=.417},{916},
        "Inside Shadowthread Cave. Follow the cave entrance; the waypoint is not a safe walking path."),
    quest(920,"Tenaron's Summons",5,1,90,2,{x=.578,y=.417},tree,tree,{917},
        "Tenaron is upstairs in Aldrassil; allow time for the spiral ramp."),
    quest(921,"Crown of the Earth",5,1,450,3,tree,{x=.599,y=.331},tree,{920}),
    quest(4495,"A Good Friend",4,2,90,1,{x=.609,y=.420},{x=.546,y=.329},{x=.546,y=.329}),
    quest(3519,"A Friend in Need",4,2,90,2,{x=.546,y=.329},{x=.609,y=.420},{x=.609,y=.420},{4495}),
    quest(3521,"Iverron's Antidote",4,2,360,6,{x=.609,y=.420},{x=.573,y=.346},{x=.609,y=.420},{3519}),
    quest(3522,"Iverron's Antidote",4,2,360,2,{x=.609,y=.420},{x=.546,y=.329},{x=.546,y=.329},{3521},
        "Delivery to Iverron. Check the quest timer before taking a detour."),
    quest(97977,"Nature's Call",3,1,250,4,{x=.577,y=.451},nil,{x=.577,y=.451},nil,
        "Collect four Gnarlpine Totems. Pickup availability and objective location come from the client; no spawn area is guessed."),
    quest(97979,"The Goddess Provides",1,1,40,1,{x=.592,y=.405},nil,{x=.592,y=.405},nil,
        "Use Elune's Light and Shadowmeld yourself as directed by the quest. Night Elf racial introduction; not priest-only."),
    quest(5842,"Welcome!",1,1,0,.15,hub,nil,nil,nil,
        "Conditional Shadowglen Gift Voucher quest. Only consider an owned voucher or accepted quest; not a farmable drop."),
    quest(3116,"Simple Sigil",1,1,40,.5,{x=.587,y=.443},{x=.596,y=.384},{x=.596,y=.384},nil,
        "Read the supplied sigil yourself, then speak to Alyissia. Pickup availability requires the client's NPC offer."),
    quest(3117,"Etched Sigil",1,1,40,.5,{x=.587,y=.443},{x=.587,y=.405},{x=.587,y=.405},nil,
        "Read the supplied sigil yourself, then speak to Ayanna Everstride in Aldrassil. Pickup availability requires the client's NPC offer."),
    quest(3118,"Encrypted Sigil",1,1,40,.5,{x=.587,y=.443},{x=.596,y=.387},{x=.596,y=.387},nil,
        "Read the supplied sigil yourself, then speak to Frahun Shadewhisper. Pickup availability requires the client's NPC offer."),
    quest(3119,"Hallowed Sigil",1,1,40,.5,{x=.587,y=.443},{x=.592,y=.404},{x=.592,y=.404},nil,
        "Read the supplied sigil yourself, then speak to Shanda in Aldrassil. Pickup availability requires the client's NPC offer."),
    quest(3120,"Verdant Sigil",1,1,40,.5,{x=.587,y=.443},{x=.586,y=.403},{x=.586,y=.403},nil,
        "Read the supplied sigil yourself, then speak to Mardant Strongoak in Aldrassil. Pickup availability requires the client's NPC offer."),
    quest(928,"Crown of the Earth",5,1,225,.15,{x=.591,y=.395},{x=.561,y=.617},{x=.561,y=.617},{921},
        "Collect the Partially Filled Vessel from Tenaron upstairs, then take the road south to Corithras Moonrage at Dolanaar's moonwell."),
    quest(2159,"Dolanaar Delivery",5,1,110,.15,{x=.612,y=.476},{x=.556,y=.598},{x=.556,y=.598},nil,
        "Take Porthannius's supplied delivery to Innkeeper Keldamyr in Dolanaar. Follow the road; coordinates are approximate baselines."),
}}

-- Separate gathering areas; tokens reconcile English live objectives. Unknown
-- or localized text stays unresolved until the quest is complete. Locations
-- remain unverified estimates for this alpha.
for _,q in ipairs(Q.Pack.quests) do
    local introClass=({[3116]=1,[3117]=3,[3118]=4,[3119]=5,[3120]=11})[q.id]
    if introClass then
        q.intro=true; q.requiredClassID=introClass; q.requiredRaceID=4
        -- Source requirement lists mix Forever records and Classic details.
        -- Use an actual NPC offer instead of asserting an unverified gate.
        q.offeredOnly=true
    end
    if q.id==3117 or q.id==3119 or q.id==3120 then
        q.navigationNote="Aldrassil: use the ramps inside"
        q.navigationActions={DO=true,["TURN IN"]=true}
    end
    if q.id==928 or q.id==2159 then
        q.handoff=true
        q.navigationNote="Dolanaar: follow the road south"
        q.navigationActions={DO=true,["TURN IN"]=true}
    end
    if q.id==97977 or q.id==97979 then q.offeredOnly=true end
    if q.id==97979 then q.requiredRaceID=4 end
    if q.id==5842 then q.itemStartID=14648; q.ownedOnly=true end
    if q.id==97236 then
        q.itemStartID=277190; q.dropCompanion=917
        q.navigationNote="Cave: use the entrance"; q.navigationActions={["LOOT ITEM"]=true}
    end
    if q.id==916 then q.tasks={{label="Gather Webwood Venom",match="venom",target=q.objective,minutes=6,combatKey="webwood-spiders"}} end
    if q.id==3521 then q.tasks={
        {label="Gather Hyacinth Mushrooms",match="hyacinth",target={x=.578,y=.397},minutes=2},
        {label="Gather Moonpetal Lilies",match="moonpetal",target={x=.575,y=.373},minutes=2},
        {label="Gather Webwood Ichor",match="ichor",target={x=.575,y=.328},minutes=2,combatKey="webwood-spiders"},
    } end
    if q.id==3522 then q.timed=true end
    if q.id==917 then q.navigationNote="Cave: use the entrance"; q.navigationActions={DO=true} end
    if q.id==920 then q.navigationNote="Upstairs: use the ramp"; q.navigationActions={DO=true,["TURN IN"]=true} end
    if q.id==3522 then q.navigationNote="Timed delivery: avoid detours" end
end
