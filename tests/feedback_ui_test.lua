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

test("feedback clear requires confirmation and cancel preserves stored observations",function()
    R.FeedbackAction("note","Synthetic retained observation")
    U.ShowFeedback(Q.db.feedbackReport)
    local before=Q.db.feedbackReport
    U.feedbackClear:GetScript("OnClick")()
    assert(Q.db.feedbackReport==before,"arming clear must not destroy stored feedback")
    assert(U.feedbackCancelClear:IsShown(),"confirmation needs an explicit cancel")
    U.feedbackCancelClear:GetScript("OnClick")()
    assert(Q.db.feedbackReport==before and not U.feedbackCancelClear:IsShown())
    U.feedbackClear:GetScript("OnClick")();U.feedbackClear:GetScript("OnClick")()
    assert(not Q.db.feedbackReport:find("Synthetic retained observation",1,true),"confirmed clear must remove observations")
end)

test("feedback closing cancels deletion and releases focus while preserving an unfinished note",function()
    U.ShowFeedback(Q.db.feedbackReport)
    U.feedbackNote:SetText("Synthetic unfinished draft");U.feedbackNote:SetFocus();U.feedbackReport:SetFocus()
    local before=Q.db.feedbackReport
    U.feedbackClear:GetScript("OnClick")()
    U.feedbackClose:GetScript("OnClick")()
    assert(not U.feedbackFrame:IsShown() and not U.feedbackNote:HasFocus() and not U.feedbackReport:HasFocus())
    assert(Q.db.feedbackReport==before and U.feedbackNote:GetText()=="Synthetic unfinished draft")
    U.ShowFeedback(Q.db.feedbackReport)
    assert(not U.feedbackCancelClear:IsShown(),"reopening must not retain armed deletion")
    U.feedbackNote:SetText("")
end)

test("feedback save acknowledges locally and report display edits never rewrite persisted export",function()
    U.ShowFeedback(Q.db.feedbackReport)
    U.feedbackNote:SetText("Synthetic Unicode note café – 你好")
    U.feedbackSave:GetScript("OnClick")()
    assert(U.feedbackNote:GetText()=="" and Q.db.feedbackReport:find("Synthetic Unicode note",1,true))
    assert(U.feedbackStatus:GetText():lower():find("saved",1,true) or U.feedbackStatus:GetText():lower():find("recorded",1,true))
    local saved=Q.db.feedbackReport
    U.feedbackReport:SetText("Display-only edit")
    assert(Q.db.feedbackReport==saved)
    U.feedbackClose:GetScript("OnClick")();U.ShowFeedback(Q.db.feedbackReport)
    assert(U.feedbackReport:GetText()==saved,"reopen regenerates the authoritative export")
end)

test("long feedback export scrolls to its actual report content and clamps at both ends",function()
    local saved=Q.db.feedbackReport
    local report="Synthetic export heading\n"..string.rep("Synthetic export row with Unicode café and no real player data.\n",200).."Synthetic final export row"
    U.ShowFeedback(report)
    assert(U.feedbackReport:GetHeight()>U.feedbackScroll:GetHeight())
    local wheel=U.feedbackScroll:GetScript("OnMouseWheel")
    assert(wheel and U.feedbackScroll.mouseWheel)
    wheel(U.feedbackScroll,-10000)
    assert(U.feedbackScroll:GetVerticalScroll()>0,"wheel must scroll the report edit child, not the replaced placeholder")
    assert(U.feedbackScroll:GetVerticalScroll()<=U.feedbackScroll:GetVerticalScrollRange())
    wheel(U.feedbackScroll,10000);assert(U.feedbackScroll:GetVerticalScroll()==0)
    assert(Q.db.feedbackReport==saved,"reading a synthetic export must not rewrite saved observations")
    U.ShowFeedback(saved)
end)

test("open feedback refits while the tracker is hidden without navigation updates",function()
    local oldW,oldH=UIParent:GetWidth(),UIParent:GetHeight()
    U.ShowFeedback(Q.db.feedbackReport)
    U.frame:Hide()
    UIParent:SetSize(800,420)
    U.feedbackFrame:GetScript("OnUpdate")(U.feedbackFrame,1.1)
    assert(U.feedbackFrame:GetHeight()*U.feedbackFrame:GetScale()<=420)
    assert(U.feedbackFrame:GetWidth()*U.feedbackFrame:GetScale()<=800)
    UIParent:SetSize(oldW,oldH)
    U.feedbackFrame:GetScript("OnUpdate")(U.feedbackFrame,1.1)
    U.feedbackClose:GetScript("OnClick")()
end)
