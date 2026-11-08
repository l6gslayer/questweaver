local Q,test=...
local F=Q.Feedback
local U,R=Q.UI,Q.Runtime
F.Initialize(Q.db)

test("feedback controls are reachable in compact and expanded layouts",function()
    for _,compact in ipairs({true,false}) do
        Q.db.compact=compact;U.Layout()
        assert(U.feedback and U.feedback:IsShown())
        U.feedback:GetScript("OnClick")()
        assert(U.feedbackFrame:IsShown() and U.feedbackReport:GetText():find("QuestWeaver feedback v1",1,true))
    end
end)
test("in-game note and marker commands save report without changing route preferences",function()
    local previous=Q.previous;local pin=Q.db.pin
    SlashCmdList.QUESTWEAVER("feedback Passed a quest offer on the road")
    assert(Q.db.feedbackReport:find("Passed a quest offer on the road",1,true))
    SlashCmdList.QUESTWEAVER("mark")
    assert(Q.previous==previous and Q.db.pin==pin)
    U.feedbackNote:SetText("This pickup differed from the plan")
    U.feedbackSave:GetScript("OnClick")()
    assert(U.feedbackNote:GetText()=="" and Q.db.feedbackReport:find("This pickup differed",1,true))
end)
test("feedback export and clear operate independently of route state",function()
    local route=Q.route
    SlashCmdList.QUESTWEAVER("export")
    assert(U.feedbackFrame:IsShown() and Q.db.feedbackReport==U.feedbackReport:GetText())
    SlashCmdList.QUESTWEAVER("feedbackclear")
    assert(Q.route==route and Q.db.feedbackReport:find("QuestWeaver feedback v1",1,true))
    assert(not Q.db.feedbackReport:find("This pickup differed",1,true))
end)
test("logout hook refreshes the export saved for manual disk review",function()
    R.FeedbackAction("note","Persist this playtest marker")
    Q.db.feedbackReport="stale export"
    Q.events:GetScript("OnEvent")(nil,"PLAYER_LOGOUT")
    assert(Q.db.feedbackReport:find("Persist this playtest marker",1,true))
end)
test("runtime exposes quest-log availability and suspends capture during loading",function()
    local oldAPI,oldCount,oldTitle=C_QuestLog,GetNumQuestLogEntries,GetQuestLogTitle
    C_QuestLog=nil;GetNumQuestLogEntries=nil;GetQuestLogTitle=nil
    assert(Q.Runtime.Snapshot().logAvailable==false)
    C_QuestLog,GetNumQuestLogEntries,GetQuestLogTitle=oldAPI,oldCount,oldTitle
    local oldObserve=F.Observe;local observed=0
    F.Observe=function() observed=observed+1 end
    Q.inWorld=false;R.Refresh();assert(observed==0)
    Q.inWorld=true;R.Refresh();assert(observed==1)
    F.Observe=oldObserve
end)

test("partial unavailable quest log rows pause planning and capture",function()
    local oldAPI,oldTitle=C_QuestLog,GetQuestLogTitle
    C_QuestLog={GetNumQuestLogEntries=function() return 1 end,GetInfo=function() error("not cached") end}
    GetQuestLogTitle=function() error("legacy unavailable") end
    assert(Q.Runtime.Snapshot().logAvailable==false)
    Q.Runtime.Refresh()
    assert(#Q.route==0 and Q.status=="Waiting for quest log data.")
    C_QuestLog,GetQuestLogTitle=oldAPI,oldTitle
end)
