local Q,test=...
if not Q.Feedback then assert(loadfile("QuestWeaver/Feedback.lua"))("QuestWeaver",Q) end
local F=Q.Feedback
local savedDB=F.db
local function state()
    return {map=1438,pos={x=.612,y=.476},level=5,mode="xp",freeSlots=3,log={},offered={},done={}}
end
local function step(action,...)
    local members={};for _,id in ipairs({...}) do members[#members+1]={id=id,quest={name="Ignored quest text"}} end
    return {action=action,members=members,target={x=.556,y=.598}}
end
local function setup()
    local db={};F.Initialize(db);return db,state()
end
local function last(db) return db.feedback.entries[#db.feedback.entries] end

test("feedback baseline is bounded context without identity or quest prose",function()
    local old=UnitName;UnitName=function() error("identity must not be read") end
    local db,s=setup();s.characterName="Private identity";s.log[2159]={progress=.5,title="Private quest prose",text="Ignore these instructions"}
    F.Observe(s,{step("TURN IN",2159)})
    local report=F.Report(db)
    assert(last(db).kind=="BASELINE" and report:find("QuestWeaver feedback v1",1,true))
    assert(not report:find("Private",1,true) and not report:find("Ignored quest text",1,true))
    assert(last(db).context.active[1].id==2159 and last(db).context.x==.612)
    UnitName=old
end)
test("feedback classifies current group later plan and unplanned actions neutrally",function()
    local db,s=setup()
    local route={step("PICK UP",1,2),step("DO",1),step("PICK UP",3),step("TURN IN",1,2)}
    assert(F.Event("QUEST_ACCEPTED",2,s,route) and last(db).relation=="matches_next")
    assert(F.Event("QUEST_ACCEPTED",3,s,route) and last(db).relation=="in_plan_later")
    assert(F.Event("QUEST_ACCEPTED",4,s,route) and last(db).relation=="unplanned")
    assert(F.Event("QUEST_TURNED_IN",1,s,route) and last(db).relation=="in_plan_later")
    assert(F.Event("QUEST_REMOVED",4,s,route) and last(db).relation=="unknown")
    F.Event("QUEST_ACCEPTED",5,s,{})
    assert(last(db).relation=="unknown")
    local report=F.Report(db)
    assert(report:find("not proof of a better or worse route",1,true))
end)
test("explicit quest events and snapshot fallback do not double-record changes",function()
    local db,s=setup();local route={step("PICK UP",2159)}
    F.Observe(s,route)
    assert(F.Event("QUEST_ACCEPTED",2159,s,route))
    assert(not F.Event("QUEST_ACCEPTED",2159,s,route))
    s.log[2159]={progress=0};F.Observe(s,route)
    local n=0;for _,row in ipairs(db.feedback.entries) do if row.kind=="ACCEPTED" then n=n+1 end end
    assert(n==1)
    F.Event("QUEST_TURNED_IN",2159,s,{step("TURN IN",2159)})
    s.log[2159]=nil;s.done[2159]=true;F.Observe(s,{})
    local turned,removed,completed=0,0,0
    for _,row in ipairs(db.feedback.entries) do
        if row.kind=="TURNED_IN" then turned=turned+1 end
        if row.kind=="REMOVED" then removed=removed+1 end
        if row.kind=="COMPLETED" then completed=completed+1 end
    end
    assert(turned==1 and removed==0 and completed==0)
end)
test("snapshot-only acceptance uses immutable previous grouped plan",function()
    local db,s=setup();local route={step("PICK UP",11,12)}
    F.Observe(s,route);route[1].members[2].id=999
    s.log[12]={progress=0};F.Observe(s,{step("DO",12)})
    local found
    for _,row in ipairs(db.feedback.entries) do if row.kind=="ACCEPTED" then found=row end end
    assert(found and found.questID==12 and found.relation=="matches_next")
end)
test("progress route and offer capture avoids per-second duplicate spam",function()
    local db,s=setup();s.log[1]={progress=0};local route={step("DO",1)}
    F.Observe(s,route)
    for _=1,20 do F.Observe(s,route) end
    assert(#db.feedback.entries==1)
    for i=1,6 do s.log[1].progress=i/100;F.Observe(s,route) end
    local progress=0;for _,row in ipairs(db.feedback.entries) do if row.kind=="PROGRESS" then progress=progress+1 end end
    assert(progress==1)
    s.log[1].complete=true;F.Observe(s,route);assert(last(db).kind=="READY")
    s.offered[2159]=true;F.Observe(s,route);assert(last(db).kind=="OFFERED")
    local before=#db.feedback.entries;F.Observe(s,route);assert(#db.feedback.entries==before)
    F.Observe(s,{step("TURN IN",1)});assert(last(db).kind=="PLAN")
end)
test("notes and markers are sanitized bounded explicit user data",function()
    local db,s=setup()
    F.Mark("|cffffffffA note|r\nnext\tline "..string.rep("x",400),s,{})
    assert(last(db).kind=="NOTE" and #last(db).note<=240 and not last(db).note:find("\n",1,true))
    assert(not last(db).note:find("|",1,true))
    F.Mark("",s,{});assert(last(db).kind=="MARK" and not last(db).note)
    assert(F.Report(db):find("User note:",1,true))
end)
test("feedback ring preserves newest events and monotonic sequence across reload",function()
    local db,s=setup()
    for i=1,320 do F.Mark("marker "..i,s,{}) end
    assert(#db.feedback.entries==300 and db.feedback.entries[1].seq==21 and last(db).seq==320)
    local oldSession=db.feedback.session
    F.Initialize(db);F.Mark("after reload",s,{})
    assert(#db.feedback.entries==300 and last(db).seq==321 and db.feedback.session==oldSession+1)
    F.Clear(db);assert(#db.feedback.entries==0 and not db.feedbackReport)
end)
test("malformed saved capture is rebuilt from allowlisted fields only",function()
    local db={feedback={session="bad",nextSeq=-3,character="Private identity",entries={
        false,{kind="INVALID",note="bad"},{seq=2,kind="NOTE",session=1,note="hello",private="Private identity",
            context={map=1438,x=.5,y=.4,character="Private identity",active={{id=1,title="private",progress=.5}},plan={{action="DO",ids={1},x=.5,y=.4}}}}}}}
    F.Initialize(db)
    assert(#db.feedback.entries==1 and db.feedback.nextSeq==3 and not db.feedback.character)
    assert(not db.feedback.entries[1].private and not db.feedback.entries[1].context.character)
    assert(not F.Report(db):find("Private identity",1,true))
    F.Initialize({feedback="bad"});assert(F.Mark("hello",state(),{}))
    F.Initialize(nil);assert(not F.Mark("no db",state(),{}))
end)
test("full grouped member set is retained even with repeated task members",function()
    local db,s=setup();local route={step("PICK UP",1,1,1,2,3,4)}
    F.Event("QUEST_ACCEPTED",4,s,route)
    assert(last(db).relation=="matches_next" and #last(db).context.plan[1].ids==4)
end)
test("maximum bounded capture exports below half a megabyte",function()
    local db,s=setup();local route={}
    for i=1,40 do s.log[900000000+i]={progress=.123} end
    for i=1,8 do route[i]=step("TURN IN",900000001,900000002,900000003,900000004) end
    for i=1,310 do F.Mark(string.rep("x",240),s,route) end
    assert(#db.feedback.entries==300 and #F.Report(db)<500000)
end)
test("loading suspension resets baseline without inventing removals",function()
    local db,s=setup();s.log[1]={progress=.5}
    F.Observe(s,{step("DO",1)})
    F.Suspend();F.Observe(state(),{})
    for _,row in ipairs(db.feedback.entries) do assert(row.kind~="REMOVED" and row.kind~="ACCEPTED") end
    s.logAvailable=false;F.Observe(s,{})
    s.logAvailable=true;F.Observe(s,{})
    assert(last(db).kind=="BASELINE")
end)
test("ready deviations and replay fields retain numeric state only",function()
    local db,s=setup();s.classID=1;s.raceID=4;s.pin=1;s.budget=10
    s.log[1]={progress=.5,xp=250,location={x=.55,y=.44}};s.log[2]={progress=.5}
    F.Observe(s,{step("DO",1),step("DO",2)})
    s.log[2].complete=true;F.Observe(s,{step("DO",1),step("TURN IN",2)})
    local ready
    for _,row in ipairs(db.feedback.entries) do if row.kind=="READY" then ready=row end end
    assert(ready and ready.relation=="in_plan_later" and ready.context.classID==1 and ready.context.pin==1)
    assert(ready.context.plan[2].action=="DO")
    assert(ready.context.active[1].xp==250 and ready.context.active[1].location.x==.55)
end)
test("manual notes remain valid UTF-8 at their byte boundary",function()
    local db,s=setup()
    F.Mark(string.rep("é",200),s,{})
    assert(last(db).note==string.rep("é",120))
    F.Mark("x"..string.rep("🌙",100),s,{})
    assert(last(db).note=="x"..string.rep("🌙",59))
    F.Mark("bad"..string.char(255).."data",s,{})
    assert(last(db).note=="bad?data")
end)
test("accepted event dedup survives several stale quest-log snapshots",function()
    local db,s=setup();local route={step("PICK UP",2159)}
    F.Observe(s,route);F.Event("QUEST_ACCEPTED",2159,s,route)
    for _=1,4 do F.Observe(s,route) end
    assert(not F.Event("QUEST_ACCEPTED",2159,s,route))
    s.log[2159]={progress=0};F.Observe(s,{step("DO",2159)})
    local n=0;for _,row in ipairs(db.feedback.entries) do if row.kind=="ACCEPTED" then n=n+1 end end
    assert(n==1 and not F.pending["ACCEPTED:2159"])
end)
test("turn-in and removal event dedup survive delayed disappearance",function()
    for _,kind in ipairs({"QUEST_TURNED_IN","QUEST_REMOVED"}) do
        local db,s=setup();s.log[2159]={complete=true}
        local route={step("TURN IN",2159)}
        F.Observe(s,route);F.Event(kind,2159,s,route)
        for _=1,4 do F.Observe(s,route) end
        s.log[2159]=nil;s.done[2159]=kind=="QUEST_TURNED_IN"
        F.Observe(s,{})
        local turned,removed,completed=0,0,0
        for _,row in ipairs(db.feedback.entries) do
            if row.kind=="TURNED_IN" then turned=turned+1 end
            if row.kind=="REMOVED" then removed=removed+1 end
            if row.kind=="COMPLETED" then completed=completed+1 end
        end
        assert(completed==0 and (kind=="QUEST_TURNED_IN" and turned==1 and removed==0 or kind=="QUEST_REMOVED" and turned==0 and removed==1))
        assert(next(F.pending)==nil)
    end
end)
test("unmatched event dedup expires and its dictionary remains bounded",function()
    local db,s=setup();F.Observe(s,{})
    for id=1,150 do F.Event("QUEST_ACCEPTED",id,s,{}) end
    local count=0;for _ in pairs(F.pending) do count=count+1 end
    assert(count==128 and not F.pending["ACCEPTED:1"])
    for _=1,21 do F.Observe(s,{}) end
    assert(next(F.pending)==nil)
    assert(F.Event("QUEST_ACCEPTED",150,s,{}))
end)
test("clearing capture preserves monotonic review identifiers",function()
    local db,s=setup();F.Mark("first",s,{})
    local seq,session=last(db).seq,last(db).session
    db.feedbackReport="old report";F.Clear(db)
    assert(#db.feedback.entries==0 and not db.feedbackReport)
    F.Mark("after clear",s,{})
    assert(last(db).seq>seq and last(db).session>session)
end)

-- Attribution fixtures are synthetic. No private quest logs or gameplay routes.
local function withTime(fn)
    local saved=GetTime
    local now=100
    GetTime=function() return now end
    local ok,err=pcall(fn,function(value) now=value end)
    GetTime=saved
    assert(ok,err)
end
local function findEvent(db,kind,id)
    for i=#db.feedback.entries,1,-1 do
        local row=db.feedback.entries[i]
        if row.kind==kind and row.questID==id then return row end
    end
end

test("recent pickup attribution survives dialogue closure without claiming a current match",function()
    withTime(function(setTime)
        local db,s=setup()
        F.Observe(s,{step("PICK UP",101,102),step("PICK UP",103)})
        setTime(102);F.Observe(s,{step("DO",999)})
        setTime(104);assert(F.Event("QUEST_ACCEPTED",102,s,{step("DO",999)}))
        local row=last(db)
        assert(row.relation=="recently_recommended" and row.recommendation.age==4)
        assert(row.recommendation.relation=="matches_next" and row.recommendation.context.plan[1].ids[2]==102)
        assert(row.context.plan[1].action=="DO" and row.context.plan[1].ids[1]==999)
        assert(not F.recentPickups[102],"consume the historical pickup once accepted")
        local report=F.Report(db)
        assert(report:find("relation=recently_recommended",1,true) and report:find("Recent recommendation: age=4.0s",1,true))
        F.Initialize(db)
        assert(findEvent(db,"ACCEPTED",102).recommendation.context.plan[1].ids[2]==102)
    end)
end)

test("snapshot acceptance uses recent pickup evidence with immutable numeric source context",function()
    withTime(function(setTime)
        local db,s=setup();local route={step("DO",999),step("PICK UP",104)}
        F.Observe(s,route)
        route[2].members[1].id=888;s.pos.x=.7
        setTime(102);F.Observe(s,{})
        setTime(105);s.log[104]={progress=0};F.Observe(s,{step("DO",104)})
        local row=findEvent(db,"ACCEPTED",104)
        assert(row and row.relation=="recently_recommended" and row.recommendation.relation=="in_plan_later")
        assert(row.recommendation.context.plan[2].ids[1]==104 and row.recommendation.context.x==.612)
        assert(row.context.x==.7 and not row.recommendation.context.characterName)
        local count=0;for _,r in ipairs(db.feedback.entries) do if r.kind=="ACCEPTED" and r.questID==104 then count=count+1 end end
        assert(count==1)
    end)
end)

test("current pickup relations take priority over recent recommendations",function()
    withTime(function(setTime)
        local db,s=setup();F.Observe(s,{step("PICK UP",105,106)})
        setTime(101)
        F.Event("QUEST_ACCEPTED",105,s,{step("DO",999),step("PICK UP",105)})
        assert(last(db).relation=="in_plan_later" and not last(db).recommendation)
        F.Event("QUEST_ACCEPTED",106,s,{step("PICK UP",106)})
        assert(last(db).relation=="matches_next" and not last(db).recommendation)
    end)
end)

test("offered-only unrelated expired skipped and completed quests do not inherit recommendation credit",function()
    withTime(function(setTime)
        local db,s=setup();s.offered[107]=true
        F.Observe(s,{step("PICK UP",108,109,110)})
        setTime(101);F.Event("QUEST_ACCEPTED",107,s,{step("DO",999)})
        assert(last(db).relation=="unplanned" and not last(db).recommendation)
        s.skip={[108]=true};F.Event("QUEST_ACCEPTED",108,s,{})
        assert(last(db).relation=="unknown" and not last(db).recommendation)
        s.done[109]=true;F.Event("QUEST_ACCEPTED",109,s,{})
        assert(last(db).relation=="unknown" and not last(db).recommendation)
        setTime(111);F.Event("QUEST_ACCEPTED",110,s,{step("DO",999)})
        assert(last(db).relation=="unplanned" and not last(db).recommendation)
        F.Event("QUEST_ACCEPTED",111,s,{step("DO",999)})
        assert(last(db).relation=="unplanned" and not last(db).recommendation)
    end)
end)

test("recent pickup history resets at map loading clear reload and clock boundaries",function()
    withTime(function(setTime)
        for _,boundary in ipairs({"map","loading","clear","reload","clock","unavailable"}) do
            setTime(100);local db,s=setup();F.Observe(s,{step("PICK UP",112)})
            if boundary=="map" then s.map=1457;F.Observe(s,{});s.map=1438
            elseif boundary=="loading" then F.Suspend()
            elseif boundary=="clear" then F.Clear(db)
            elseif boundary=="reload" then F.Initialize(db)
            elseif boundary=="clock" then setTime(99);F.Observe(s,{})
            else local old=GetTime;GetTime=nil;F.Observe(s,{});GetTime=old end
            setTime(101);F.Event("QUEST_ACCEPTED",112,s,{step("DO",999)})
            assert(last(db).relation=="unplanned" and not last(db).recommendation,boundary)
        end
    end)
end)

test("recent pickup history is bounded and unavailable log rows cannot supply stale attribution",function()
    withTime(function(setTime)
        local db,s=setup()
        for batch=0,4 do
            local route={}
            for i=1,8 do route[i]=step("PICK UP",1000+batch*32+(i-1)*4+1,1000+batch*32+(i-1)*4+2,1000+batch*32+(i-1)*4+3,1000+batch*32+i*4) end
            F.Observe(s,route)
        end
        local count=0;for _ in pairs(F.recentPickups) do count=count+1 end
        assert(count==128 and not F.recentPickups[1001] and F.recentPickups[1160])
        setTime(101);s.logAvailable=false;F.Observe(s,{})
        s.logAvailable=true;F.Event("QUEST_ACCEPTED",1160,s,{step("DO",999)})
        assert(last(db).relation=="unplanned" and not last(db).recommendation)
    end)
end)

test("stale recommendation credit expires by observation count even while the clock is stationary",function()
    withTime(function()
        local db,s=setup();F.Observe(s,{step("PICK UP",114)})
        for _=1,21 do F.Observe(s,{step("DO",999)}) end
        F.Event("QUEST_ACCEPTED",114,s,{step("DO",999)})
        assert(last(db).relation=="unplanned" and not last(db).recommendation)
    end)
end)

test("recent pickup evidence sanitizes old records and leaves prior builds and sequence intact",function()
    withTime(function(setTime)
        local db,s=setup();F.Mark("synthetic older entry",s,{})
        db.feedback.entries[1].build="0.2.0-route-feedback-8"
        local oldSeq=db.feedback.entries[1].seq
        F.Observe(s,{step("PICK UP",113)})
        setTime(102);F.Observe(s,{});F.Event("QUEST_ACCEPTED",113,s,{})
        local row=last(db);row.recommendation.private="Not retained";row.recommendation.context.characterName="Not retained"
        local seq,session=row.seq,db.feedback.session
        F.Initialize(db)
        assert(db.feedback.entries[1].build=="0.2.0-route-feedback-8" and db.feedback.entries[1].seq==oldSeq)
        local kept=findEvent(db,"ACCEPTED",113)
        assert(kept.relation=="recently_recommended" and not kept.recommendation.private and not kept.recommendation.context.characterName)
        F.Mark("synthetic new entry",s,{})
        assert(last(db).seq>seq and db.feedback.session>session and last(db).build=="0.2.0-route-feedback-9")
    end)
end)

test("recent attribution covers later visible steps beyond the eight-step report context",function()
    withTime(function(setTime)
        for _,index in ipairs({9,24}) do
            setTime(100);local db,s=setup();local route={}
            for i=1,24 do route[i]=step("DO",2000+i) end
            route[index]=step("PICK UP",3000+index)
            F.Observe(s,route);setTime(101);F.Observe(s,{step("DO",999)})
            setTime(102);F.Event("QUEST_ACCEPTED",3000+index,s,{step("DO",999)})
            local row=last(db)
            assert(row.relation=="recently_recommended" and row.recommendation.planIndex==index)
            assert(row.recommendation.relation=="in_plan_later" and row.recommendation.context.plan[1].ids[1]==3000+index)
            assert(row.context.plan[1].ids[1]==999 and F.Report(db):find("sourceStep="..index,1,true))
            F.Initialize(db)
            assert(findEvent(db,"ACCEPTED",3000+index).recommendation.planIndex==index)
        end
    end)
end)

test("recent recommendation evidence keeps full-entry exports bounded and newest data retained",function()
    withTime(function(setTime)
        local db,s=setup()
        for id=1,40 do s.log[id]={progress=.25,xp=1000,location={x=.5,y=.6},destinationMap=1438} end
        for batch=1,100 do
            setTime(100+batch)
            local route={}
            for index=1,8 do
                local id=10000+batch*32+index*4
                route[index]=step("PICK UP",id,id+1,id+2,id+3)
            end
            F.Observe(s,route);F.Observe(s,{step("DO",1)})
            for index=1,8 do F.Event("QUEST_ACCEPTED",10000+batch*32+index*4,s,{step("DO",1)}) end
        end
        local report=F.Report(db)
        local exported=tonumber(report:match("Entries: exported=(%d+)"))
        assert(#db.feedback.entries==300 and #report<500000 and exported>0 and exported<=300)
        assert(last(db).relation=="recently_recommended" and report:find("Event "..last(db).seq.." ",1,true))
        assert(#last(db).context.active==40 and #last(db).recommendation.context.active==0 and #last(db).recommendation.context.offered==0,
            "source evidence must not duplicate the event's large quest snapshot")
        assert(report:find("Recent plan:",1,true) and not report:find("Ignored quest text",1,true))
    end)
end)

if savedDB then F.Initialize(savedDB) else F.Initialize(nil) end
