local _,Q=...
-- City coordinates are map1457 percentages, never map1438 percentages.
-- Public player sightings / cache links and limits: DARNASSUS_CATALOGUE.md.
local function pos(x,y) return {x=x/100,y=y/100,source="Catalogue city NPC; check availability"} end
local rellian=pos(38.4,21.4)
local fandral=pos(34.8,8.9)
local aquinne=pos(29.1,45.6)
local amoora=pos(36.4,86.1)
local quests={}
local function add(id,name,level,minLevel,xp,start,finish,all,options)
    local q={id=id,name=name,level=level,minLevel=minLevel,xp=xp,xpEstimated=true,
        catalogue=true,pickupOnly=true,minutes=5,start=start,finish=finish,all=all,
        note="City catalogue: check availability. Live current-stage locations override reference positions."}
    for k,v in pairs(options or {}) do q[k]=v end
    quests[#quests+1]=q;return q
end
local function incoming(id,name,level,minLevel,xp,recipient)
    local q=add(id,name,level,minLevel,xp,recipient,recipient,nil,
        {acceptedOnly=true,pickupOnly=false,objectiveMap=1457,returnMap=1457,minutes=.15})
    q.objective=recipient
end
-- These quests are accepted outside the city: never suggest city acceptance.
incoming(922,"Rellian Greenspyre",7,4,315,rellian)
incoming(935,"Crown of the Earth",11,1,1100,fandral)
incoming(940,"Teldrassil",11,6,220,fandral)
incoming(98391,"The Sisterhood of Elune",10,5,85,aquinne)
-- Work in Teldrassil, return here; forest positions are not copied onto city.
add(923,"Tumors",9,4,975,rellian,rellian,{922},{objectiveMap=1438,returnMap=1457})
add(2498,"Return to Denalan",9,4,80,rellian,nil,{923},{objectiveMap=1438,returnMap=1438})
local temple=add(2519,"The Temple of the Moon",10,5,85,aquinne,amoora,{98391},
    {pickupOnly=false,objectiveMap=1457,returnMap=1457,minutes=.15})
temple.objective=amoora
add(2518,"Tears of the Moon",12,5,1150,amoora,amoora,{2519},
    {objectiveMap=1438,returnMap=1457,prerequisiteEvidence="Series may use a skippable breadcrumb; actual offer overrides"})
add(2520,"Sathrah's Sacrifice",12,5,910,amoora,amoora,{2518},
    {objectiveMap=1457,returnMap=1457,note="Temple action: follow the quest instructions. No exact fountain interaction point is guessed."})
add(952,"Grove of the Ancients",17,6,1250,fandral,nil,{940},{objectiveMap=1439,returnMap=1439})
add(98067,"Eyes of the Sentinels",11,1,660,nil,nil,nil,
    {offeredOnly=true,unresolved="Current giver/return locations not recorded"})
Q.Catalogues.Register({mapID=1457,areaID=1657,name="Darnassus",faction="Alliance",
    bounds={minX=0,maxX=1,minY=0,maxY=1},catalogueVersion=1,quests=quests})
