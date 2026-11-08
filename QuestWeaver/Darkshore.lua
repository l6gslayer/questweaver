local _,Q=...
-- Independently curated facts; evidence and unknowns in DARKSHORE_CATALOGUE.md.
-- Registering does not change the active zone catalogue.
local quests={}
local function pos(x,y)
    return x and {x=x/100,y=y/100,source="Catalogue NPC/object; check availability"} or nil
end
local function add(id,name,level,minLevel,xp,start,finish,all,options)
    local q={id=id,name=name,level=level,minLevel=minLevel,xp=xp or 250,
        xpEstimated=true,minutes=5,start=start,finish=finish,all=all,
        catalogue=true,pickupOnly=true,sourceID=id,
        note="Check pickup availability. Objective work uses the client's current location; work/travel and catalogue XP remain estimates."}
    for k,v in pairs(options or {}) do q[k]=v end
    quests[#quests+1]=q
    return q
end
local gwennyth=pos(36.6,45.6)
local terenthis=pos(39.3,43.5)
local glynda=pos(37.7,43.4)
local crystal=pos(47.3,48.7)
-- Pickup/return positions explicitly marked seen in Forever by source players.
-- Recorded reward amounts are estimates until the active client supplies XP.
add(983,"Buzzbox 827",10,7,850,pos(37,44.1),pos(36.7,46.3))
add(1001,"Buzzbox 411",12,7,1150,pos(36.7,46.3),pos(42,28.7),{983})
add(984,"How Big a Threat?",14,10,750,terenthis,terenthis)
add(985,"How Big a Threat?",14,10,975,terenthis,terenthis,{984})
add(3524,"Washed Ashore",13,11,675,gwennyth,gwennyth)
add(4681,"Washed Ashore",14,11,975,gwennyth,gwennyth,{3524})
add(4811,"The Red Crystal",14,12,490,glynda,glynda)
add(4813,"The Fragments Within",14,12,975,crystal,glynda,{4812})
-- Known chain identities with incomplete current metadata stay offer-only.
add(4812,"As Water Cascades",14,12,nil,glynda,crystal,{4811},
    {offeredOnly=true,unresolved="Pickup/requirements need current offer confirmation"})
add(1002,"Buzzbox 323",14,1,nil,nil,nil,{1001},
    {offeredOnly=true,unresolved="Current minimum, XP and positions not established"})
add(1003,"Buzzbox 525",16,1,nil,nil,nil,{1002},
    {offeredOnly=true,unresolved="Current minimum, XP and positions not established"})
for _,row in ipairs({{954,12},{955,12},{956,13},{957,13}}) do
    add(row[1],"Bashal'Aran",row[2],1,nil,nil,nil,row[1]~=954 and {row[1]-1} or nil,
        {offeredOnly=true,unresolved="Forever series known; current pickup requirements/positions not established"})
end
-- Game-cache records identify these quests and levels, but publish no giver
-- positions. Do not replace those gaps with unverified Classic coordinates.
add(2118,"Plagued Lands",14,10,980,nil,nil,nil,{offeredOnly=true})
add(2138,"Cleansing of the Infected",16,10,1150,nil,nil,{2118},{offeredOnly=true})
add(2139,"Tharnariun's Hope",18,10,1350,nil,nil,nil,
    {offeredOnly=true,unresolved="Narrative follows bear tasks; no explicit previous gate established"})
add(5713,"One Shot. One Kill.",15,10,1050,nil,nil,nil,
    {offeredOnly=true,risk=1,destinationMap=1440,
        note="Defence event; accept manually when ready. Recipient is in Ashenvale; no foreign map coordinates are guessed."})
add(97894,"Business in Auberdine",17,13,0,nil,nil,nil,
    {offeredOnly=true,unresolved="Starts outside this zone; observe current handoff"})
add(98042,"It's All Fun and Games Until...",17,12,1250,nil,nil,nil,
    {offeredOnly=true,unresolved="Twilight Tome interaction, not a verified bag-item starter"})
add(97926,"Making Do",17,13,630,nil,nil,nil,
    {offeredOnly=true,unresolved="Foreign-zone predecessor Expanding Horizons; current offer required"})
add(2098,"Gyromast's Retrieval",20,14,1550,nil,nil,nil,{offeredOnly=true})
add(2078,"Gyromast's Revenge",20,14,1150,nil,nil,{2098},
    {offeredOnly=true,elite=true,risk=2,note="Elite follow-up: assess group readiness; no safe solo path is claimed."})
add(98013,"Swelling Forces",20,12,1550,nil,nil,nil,{offeredOnly=true})
add(98025,"WANTED: Jai'vhanel",13,10,1150,nil,nil,nil,
    {offeredOnly=true,unresolved="Bounty object position not established in cache"})
-- Owned starters are manual acceptance stages, never guaranteed farming stops.
local globe=add(98028,"Baron Marinous",21,17,1650,nil,pos(43.5,76.3),nil,
    {itemStartID=279275,ownedOnly=true,pickupOnly=false,minutes=.15,rare=true})
globe.objective=globe.finish
globe.note="Use a carried Clouded Water Globe manually. Source/spawn/drop rate is not guaranteed; Onu position is a community reference."
add(968,"The Powers Below",20,10,nil,nil,nil,nil,
    {itemStartID=5352,ownedOnly=true,pickupOnly=false,destinationMap=1455,
        note="Use the carried book manually. The recipient is in Ironforge; wait for a valid current-map projection, not city coordinates."})
Q.Catalogues.Register({mapID=1439,areaID=148,name="Darkshore",faction="Alliance",
    bounds={minX=0,maxX=1,minY=0,maxY=1},catalogueVersion=1,quests=quests})
