local _,Q=...
-- Independently authored factual catalogue. See SOURCES.md / CATALOGUE.md for
-- per-record evidence, conflicts and omissions. No guide routes are bundled.
local function pos(x,y) return x and {x=x/100,y=y/100,source="Catalogue NPC/object; check availability"} or nil end
local ath=pos(56,57.3)
local tall=pos(55.6,56.9)
local syral=pos(56.1,57.7)
local den=pos(60.9,68.5)
local cor=pos(56.1,61.6)
local zenn=pos(60.4,56.3)
local lyreena=pos(57.6,56.6)
local byancie=pos(55.3,56.8)
local eralya=pos(37.5,36.8)
local arynia=pos(38.3,34.4)
local function add(id,name,level,minLevel,xp,start,finish,all,options)
    local q={id=id,name=name,level=level,minLevel=minLevel,xp=xp or 250,
        xpEstimated=xp==nil,minutes=5,start=start,finish=finish,all=all,
        catalogue=true,pickupOnly=true,sourceID=id,
        note="Catalogue pickup: check availability. Objective work requires the current quest location; work/travel are estimates."}
    for k,v in pairs(options or {}) do q[k]=v end
    Q.Pack.quests[#Q.Pack.quests+1]=q
    return q
end
local function delivery(id,name,level,minLevel,xp,start,finish,all,options)
    local q=add(id,name,level,minLevel,xp,start,finish,all,options)
    q.pickupOnly=false;q.objective=finish;q.minutes=.15
    return q
end
-- Ordinary Dolanaar / Starbreeze / Lake Al'Ameth chains. Static facts never
-- substitute a guessed objective point for the client's current location.
delivery(475,"A Troubling Breeze",6,4,270,ath,pos(66.2,58.5))
delivery(476,"Gnarlpine Corruption",6,4,540,pos(66.2,58.5),ath,{475})
add(483,"The Relics of Wakening",9,4,780,ath,ath,{476})
add(486,"Ursal the Mauler",12,1,nil,ath,ath,{483},{offeredOnly=true,unresolved="Current requirements not independently established"})
add(487,"The Road to Darnassus",8,5,700,pos(55.5,58.5),pos(55.5,58.5),nil,
    {navigationNote="Questgiver patrols: map point is an estimate"})
add(488,"Zenn's Bidding",5,4,450,pos(60.5,56.3),zenn)
add(489,"Seek Redemption!",7,4,630,syral,zenn,{488},
    {prerequisiteEvidence="Conservative: quest text refers to previous help for Zenn"})
delivery(997,"Denalan's Earth",5,4,225,syral,den)
add(918,"Timberling Seeds",7,4,630,den,den,{997},
    {prerequisiteEvidence="Conservative community gate; actual offer overrides"})
add(919,"Timberling Sprouts",7,4,790,den,den,{997},
    {prerequisiteEvidence="Conservative community gate; actual offer overrides"})
-- Rellian is in Darnassus: city coordinates are NOT Teldrassil coordinates.
add(922,"Rellian Greenspyre",7,4,315,den,nil,{918},{destinationMap=1457,objectiveMap=1457,returnMap=1457})
add(923,"Tumors",9,1,nil,nil,nil,{922},{offeredOnly=true,destinationMap=1457,
    unresolved="City pickup and requirements need client confirmation"})
delivery(2498,"Return to Denalan",9,4,80,nil,den,{923},{offeredOnly=true})
add(2499,"Oakenscowl",9,4,980,den,den,{2498},{prerequisiteEvidence="Previous quest recorded; minimum level is conservative"})
add(2438,"The Emerald Dreamcatcher",6,1,405,tall,tall)
add(2459,"Ferocitas the Dream Eater",8,1,880,tall,tall,{2438})
add(932,"Twisted Hatred",8,4,700,tall,tall)
add(98403,"Twisted Hatred",12,4,910,tall,tall,{932},
    {offeredOnly=true,risk=2,elite=true,note="Elite quest. Confirm the offer and assess your group; no safe solo work estimate is claimed."})
-- Ban'ethil giver positions are not established in the current cache records.
add(2541,"The Sleeping Druid",8,3,700,nil,nil,nil,{offeredOnly=true})
add(2561,"Druid of the Claw",10,3,1050,nil,nil,{2541},{offeredOnly=true})
add(99053,"Escaping Ban'ethil",10,4,840,nil,nil,nil,
    {offeredOnly=true,risk=1,note="Escort: accept manually only when ready; no automatic movement or safe terrain route."})
-- Crown / Oracle progression retains Forever's added intermediary quests.
add(929,"Crown of the Earth",5,1,335,cor,cor,{928})
add(933,"Crown of the Earth",9,1,780,cor,cor,{929})
add(7383,"Crown of the Earth",11,1,nil,cor,cor,{933},{offeredOnly=true})
add(935,"Crown of the Earth",11,1,nil,cor,nil,{7383},{offeredOnly=true,objectiveMap=1457,returnMap=1457})
add(937,"The Enchanted Glade",11,1,nil,arynia,arynia,nil,{offeredOnly=true})
add(938,"Mist",12,1,nil,nil,arynia,nil,{offeredOnly=true,unresolved="Escort availability and exact start not established"})
add(98392,"Darkness in the Glade",12,6,910,arynia,arynia,{937},
    {prerequisiteEvidence="Forever quest series records the added step after 937"})
add(98398,"The Oracle Tree",12,6,90,arynia,pos(37,34.1),{98392})
add(940,"Teldrassil",11,1,nil,pos(37,34.1),nil,{98398},
    {offeredOnly=true,destinationMap=1457,objectiveMap=1457,returnMap=1457,unresolved="Confirm current city handoff and minimum level"})
-- Forever additions: locations have distinct cache / community provenance.
add(87288,"Soft Saber Pelts",7,4,630,pos(55.5,57.2),pos(55.5,57.2))
add(490,"Bounty: Gnarlpine Furbolg",8,1,nil,pos(40.5,50.7),pos(40.5,50.7),nil,
    {offeredOnly=true,unresolved="Availability and requirements need confirmation"})
add(99046,"The Lost Runner",9,4,80,pos(56,59.5),eralya)
add(99047,"Not Dead Yet",9,4,80,eralya,byancie,{99046})
add(99050,"The Great Tree Provides",10,4,840,byancie,byancie,{99047})
add(98391,"The Sisterhood of Elune",10,5,85,pos(55.5,56.7),nil,nil,
    {offeredOnly=true,destinationMap=1457,objectiveMap=1457,returnMap=1457,unresolved="Confirm current handoff availability"})
add(99073,"Easing Suffering",10,4,85,byancie,eralya,nil,
    {offeredOnly=true,unresolved="No explicit previous quest established; use actual offer"})
-- True bag starter: rare availability is not modeled as a guaranteed farm.
local heart=delivery(927,"The Moss-twined Heart",12,5,455,nil,den,nil,
    {itemStartID=5179,ownedOnly=true,dropNPCID=3535,rare=true})
heart.note="Optional rare Blackmoss the Fetid may drop the starter. Use it manually if found; no guaranteed drop or camping stop."
heart.opportunityArea=pos(43,33);heart.opportunityMinLevel=10
add(941,"Planting the Heart",12,9,910,den,pos(60.8,68.6),{927})
-- Objects supply the fruit/frond; neither supplied item starts a bag quest.
delivery(930,"The Glowing Fruit",10,4,840,pos(42.61,76.19),den,{918,919},
    {objectStartID=6751,prerequisiteEvidence="Conservative: sources disagree between 918 and 918+919"})
delivery(931,"The Shimmering Frond",10,4,840,pos(34.7,28.8),den,{918,919},
    {objectStartID=6752,prerequisiteEvidence="Conservative: sources disagree between 918 and 918+919"})
add(2399,"The Sprouted Fronds",10,4,85,pos(60.75,68.56),pos(60.75,68.56),{931},
    {objectStartID=7510,note="Temporary object: check whether the fronds are present; not a farmable starter."})
-- Camping variants can have profession/exclusive-region gates not yet modeled.
-- Keep their identity/hand-offs in the catalogue but require an actual offer.
add(96630,"The Adventurer",6,4,410,pos(59.1,39.5),lyreena,nil,
    {offeredOnly=true,unresolved="Regional exclusivity not established"})
add(96606,"The Great Outdoors",6,4,nil,lyreena,lyreena,nil,
    {offeredOnly=true,unresolved="Regional exclusivity and base XP conflict"})
for _,row in ipairs({{96634,"Cooking"},{97938,"Alchemy"},{97939,"Blacksmithing"},
    {97940,"Enchanting"},{97941,"Engineering"},{97942,"First Aid"},{97943,"Fishing"},
    {97944,"Herbalism"},{97946,"Leatherworking"},{97948,"Mining"},{97949,"Skinning"},{97950,"Tailoring"}}) do
    add(row[1],"Camping 101: "..row[2],6,4,270,lyreena,nil,nil,
        {offeredOnly=true,professionConditional=true,unresolved="Profession skill and regional availability require current offer"})
end
Q.Pack.name="Teldrassil"
Q.Pack.catalogueVersion=1
