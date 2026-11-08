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
if savedDB then F.Initialize(savedDB) else F.Initialize(nil) end
