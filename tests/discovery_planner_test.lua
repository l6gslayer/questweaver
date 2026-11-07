local Q,test=...
local C,T,P=Q.Core,Q.Trips,Q.Provider
local savedDB,savedNpc=QuestDB,NpcDB
QuestDB=nil;NpcDB=nil
local home={x=.578,y=.417}
local cave={x=.566,y=.263}
local function state()
    return {level=5,pos=home,done={},log={},skip={},itemStarts={},mode="xp",budget=10}
end
local function provider(s) return P.Quests(s,{rewards={},profile="melee"}) end
local function find(qs,id) for _,q in ipairs(qs) do if q.id==id then return q end end end
local function member(route,id,action)
    for i,step in ipairs(route) do for _,m in ipairs(step.members) do if m.id==id and (not action or m.action==action) then return m,i end end end
end
local function only(qs,...)
    local out={}; for _,id in ipairs({...}) do local q=find(qs,id); if q then out[#out+1]=q end end; return out
end

test("Fang is a gated cave opportunity with no imaginary completion",function()
    local s=state(); local fang=find(provider(s),97236)
    assert(fang.itemStartID==277190 and not C.Eligible(fang,s))
    s.log[917]={}; fang=find(provider(s),97236)
    assert(C.Eligible(fang,s) and fang.pendingAction=="LOOT ITEM")
    local trip=T.Build({fang},s)
    assert(#trip.steps==1 and trip.steps[1].action=="LOOT ITEM" and not trip.completed[97236])
    assert(trip.stageOnly and trip.reserved>0 and not member(trip.steps,97236,"TURN IN"))
    s.log[917]=nil;s.pos=cave
    assert(C.Eligible(find(provider(s),97236),s))
end)
test("egg outing accounts for Fang with shared return travel",function()
    local s=state();s.log[917]={};s.pos=cave
    local qs=only(provider(s),917,97236)
    local trip=T.Choose(qs,s)
    assert(#trip.quests==2 and member(trip.steps,97236,"LOOT ITEM"))
    local eggSolo=T.Build({find(qs,917)},s)
    local fangSolo=T.Build({find(qs,97236)},s)
    assert(trip.minutes<eggSolo.minutes+fangSolo.minutes)
    assert(not trip.completed[97236] and trip.completed[917])
end)
test("bag Fang prompts manual acceptance without a TomTom destination",function()
    local s=state();s.itemStarts[97236]={itemID=277190,name="Fang of Githyiss"}
    local qs,notices=provider(s);local fang=find(qs,97236)
    local route,trips=T.Plan({fang},s)
    assert(#route==1 and #trips==1 and route[1].action=="ACCEPT ITEM" and #notices==1)
    assert(not Q.Navigation.Destination(route[1]))
    assert(not trips[1].completed[97236] and not s.done[97236])
    s.freeSlots=0;assert(#T.Plan({fang},s)==0)
    assert(#select(2,provider(s))==1)
end)
test("accepted Fang bypasses loot gate and batches Aldrassil returns",function()
    local s=state();s.log[97236]={complete=true,location=home};s.log[917]={complete=true,location=home}
    local qs=only(provider(s),917,97236)
    assert(not find(qs,97236).pendingAction and not find(qs,97236).stageOnly)
    local route=T.Plan(qs,s)
    assert(route[1].action=="TURN IN" and #route[1].members==2)
    assert(not member(route,97236,"LOOT ITEM") and not member(route,97236,"ACCEPT ITEM"))
    s.done[97236]=true;assert(not member(T.Plan(qs,s),97236))
    s.done[97236]=nil;s.skip[97236]=true;assert(not member(T.Plan(qs,s),97236))
end)
test("accepted Fang without client coordinates targets the delivery NPC",function()
    local s=state();s.log[97236]={}
    local fang=find(provider(s),97236)
    assert(fang.objective.x==home.x and fang.objective.y==home.y and not fang.disabled)
    assert(T.Plan({fang},s)[1].action=="DO")
end)
test("nearby accepted quest adds current stage without fabricated return or unlock",function()
    local s=state();s.log[90001]={title="Nearby errand",level=5,xp=300,progress=.5,location=cave}
    local q=find(provider(s),90001)
    assert(q and q.dynamic and q.acceptedOnly and q.xp==300 and not q.finish)
    local route,trips=T.Plan({q},s)
    assert(#route==1 and route[1].action=="DO" and trips[1].stageOnly and not trips[1].completed[90001])
    assert(trips[1].reserved==3 and not member(route,90001,"TURN IN"))
    local child={id=90002,name="Locked follow-up",minLevel=1,level=5,xp=10000,minutes=.1,
        all={90001},start=cave,objective=cave,finish=home,gear=1}
    assert(not member(T.Plan({q,child},s),90002))
end)
test("newly complete discovered quest becomes an observed local return",function()
    local s=state();s.log[90001]={title="Nearby errand",xp=300,complete=true,location=home}
    local q=find(provider(s),90001)
    assert(q.finish.x==home.x and not q.stageOnly)
    assert(T.Plan({q},s)[1].action=="TURN IN")
    s.log[90001]=nil;assert(not find(provider(s),90001))
end)
test("discovered quests reject remote and unavailable coordinates and deduplicate seeds",function()
    local s=state()
    s.log[90001]={title="Remote",location={x=.2,y=.2}}
    s.log[90002]={title="Unknown"}
    s.log[917]={location=cave}
    local qs,notices=provider(s)
    assert(not find(qs,90001) and not find(qs,90002) and #notices==1)
    local count=0;for _,q in ipairs(qs) do if q.id==917 then count=count+1 end end
    assert(count==1)
    s.log[90003]={location={x=0/0,y=.3}};assert(not find(provider(s),90003))
end)
test("local item start joins trip only with locality evidence and remains manual",function()
    local s=state();s.itemStarts[90001]={name="Local item",title="Local quest",location=cave}
    s.itemStarts[90002]={name="Unlocated item"}
    local qs,notices=provider(s);local q=find(qs,90001)
    assert(q and q.pendingAction=="ACCEPT ITEM" and q.xpEstimated and not q.gearKnown)
    assert(not find(qs,90002) and #notices==2)
    assert(T.Plan({q},s)[1].action=="ACCEPT ITEM")
    s.itemStarts={};assert(not find(provider(s),90001))
end)
test("database local return supports accepted work without assuming remote returns",function()
    QuestDB={Get=function(id,key)
        if key=="name" then return "DB quest" end
        if key=="finishedBy" then return {{123}} end
    end}
    NpcDB={Get=function() return {[141]={{57.8,41.7}}} end}
    local s=state();s.log[90001]={location=cave,xp=300}
    local q=find(provider(s),90001)
    assert(q.finish and not q.stageOnly and member(T.Plan({q},s),90001,"TURN IN"))
    NpcDB.Get=function() return {[141]={{20,20}}} end
    q=find(provider(s),90001);assert(not q.finish and q.stageOnly)
    QuestDB=nil;NpcDB=nil
end)
test("failed discovered quests do not route and unknown XP stays explicit",function()
    local s=state();s.log[90001]={location=cave,failed=true}
    local q=find(provider(s),90001)
    assert(q.xpEstimated and q.xp==250 and #T.Plan({q},s)==0)
end)
test("item and stage actions render in compact and expanded layouts",function()
    local oldRoute,oldState,oldNotices,oldTrips=Q.route,Q.state,Q.notices,Q.trips
    local s=state();s.itemStarts[97236]={itemID=277190,name="Fang of Githyiss"}
    local qs,notices=provider(s)
    Q.route,Q.trips=T.Plan(only(qs,97236),s);Q.state=s;Q.notices=notices
    Q.db.compact=true;Q.UI.Render()
    assert(not Q.UI.way.enabled and Q.UI.current.text:find("Use the item yourself",1,true))
    Q.db.compact=false;Q.UI.Render()
    assert(Q.UI.body.text:find("ACCEPT ITEM",1,true) and not Q.UI.body.text:find("58.0, 44.0",1,true))
    Q.route,Q.state,Q.notices,Q.trips=oldRoute,oldState,oldNotices,oldTrips
end)
test("large shortlist retains real prerequisites before projected children",function()
    local s=state();local qs={}
    for i=1,17 do
        qs[#qs+1]={id=91000+i,name="Anchor",minLevel=1,level=5,xp=1,minutes=2,start=home,objective=cave,finish=home}
        qs[#qs+1]={id=92000+i,name="Child",minLevel=1,level=5,xp=10000,minutes=.1,all={91000+i},start=home,objective=home,finish=home}
    end
    local route=T.Plan(qs,s)
    assert(#route>0)
    for _,step in ipairs(route) do
        for _,m in ipairs(step.members) do
            if m.action=="PICK UP" and m.id>92000 then
                local _,pre=member(route,m.id-1000,"TURN IN")
                local _,child=member(route,m.id,"PICK UP")
                assert(pre and pre<child)
            end
        end
    end
end)
test("pending item cannot contribute an AND prerequisite to gear lookahead",function()
    local s=state();s.log[91001]={complete=true}
    local root={id=91001,name="Ready",minLevel=1,level=5,xp=100,minutes=1,start=home,objective=home,finish=home}
    local pending={id=91002,name="Pending",minLevel=1,level=5,xp=450,minutes=.15,start=home,objective=home,finish=home,
        pendingAction="ACCEPT ITEM",stageOnly=true}
    local child={id=91003,name="Locked gear",minLevel=1,level=5,xp=100,minutes=1,start=home,objective=home,finish=home,
        all={91001,91002},gear=10}
    s.mode="gear"
    local trip=T.Choose({root,pending,child},s)
    assert(trip.gear==0 and not member(trip.steps,91003))
end)
test("expanded accepted log remains bounded and deterministic",function()
    local s=state()
    for id=90001,90040 do
        s.log[id]={title="Local quest "..id,xp=100+(id%10)*10,level=5,
            location={x=.56+(id%5)*.01,y=.30+(id%7)*.02}}
    end
    local qs=provider(s);local start=os.clock()
    local a=T.Plan(qs,s); local elapsed=os.clock()-start
    local b=T.Plan(qs,s)
    s.pin=90040
    assert(member(T.Plan(qs,s),90040))
    assert(#a<=24 and #b==#a and a[1].key==b[1].key and elapsed<.5)
    print(string.format("BENCHMARK 40 accepted local quests: %.3f sec",elapsed))
end)
QuestDB=savedDB;NpcDB=savedNpc
