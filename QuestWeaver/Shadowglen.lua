local _, Q = ...
-- Original starter pack. Coordinates/XP are approximate Classic baselines,
-- deliberately labeled unverified for Forever. QuestieDB can replace metadata.
local hub={x=.588,y=.443}
local tree={x=.599,y=.413}
local function quest(id,name,level,minLevel,xp,minutes,start,objective,finish,all,note)
    return {id=id,name=name,level=level,minLevel=minLevel,xp=xp,minutes=minutes,
        start=start,objective=objective,finish=finish,all=all,note=note}
end
Q.Pack={mapID=1438, name="Shadowglen", quests={
    quest(456,"The Balance of Nature",2,1,170,4,hub,{x=.594,y=.462},hub),
    quest(457,"The Balance of Nature",3,1,250,6,hub,{x=.579,y=.412},hub,{456}),
    quest(458,"The Woodland Protector",1,1,40,1,{x=.599,y=.425},{x=.578,y=.452},{x=.578,y=.452}),
    quest(459,"The Woodland Protector",3,1,250,6,{x=.578,y=.452},{x=.563,y=.456},{x=.578,y=.452},{458}),
    quest(916,"Webwood Venom",4,3,360,6,{x=.578,y=.417},{x=.575,y=.328},{x=.578,y=.417},nil,
        "Spider territory; combine with antidote gathering if both quests are accepted."),
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
}}

-- Separate gathering areas; tokens reconcile English live objectives. Unknown
-- or localized text stays unresolved until the quest is complete. Locations
-- remain unverified estimates for this alpha.
for _,q in ipairs(Q.Pack.quests) do
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
