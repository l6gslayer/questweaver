local _, Q = ...
Q.UI={}
local U=Q.UI
-- Presentation identity is separate from the unchanged planner/capture version.
U.BUILD="v0.2.0 | UI dev 1"
local function safe(text) return tostring(text or ""):gsub("|","||") end
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
local function label(parent,font,color)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    if t.GetFont and t.SetFont then
        local path,size,flags=t:GetFont()
        if path and size and size<13 then t:SetFont(path,13,flags) end
    end
    if t.SetTextColor then
        local c=color or { .94,.94,.90 }; t:SetTextColor(unpack(c))
    end
    return t
end
local function tip(widget,text)
    widget:SetScript("OnEnter",function(self)
        if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(type(text)=="function" and text() or text,nil,nil,nil,nil,true); GameTooltip:Show() end
    end)
    widget:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
local function button(parent,text,width,callback,help)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,28); b:SetText(text); b:SetScript("OnClick",callback)
    if help then tip(b,help) end
    return b
end
local function panel(f)
    if f.SetBackdrop then
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        f:SetBackdropColor(.045,.052,.06,.98); f:SetBackdropBorderColor(.32,.35,.38,1)
    end
end
local function at(widget,parent,x,y,w,h)
    widget:ClearAllPoints(); widget:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    if w then widget:SetWidth(w) end
    if h then widget:SetHeight(h) end
end
local function measured(t) return math.max(16,t:GetStringHeight()) end
local function scroll(parent)
    local s=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    local child=CreateFrame("Frame",nil,s); child:SetHeight(1); s:SetScrollChild(child); s.contentChild=child
    s:EnableMouse(true)
    if s.EnableMouseWheel then
        s:EnableMouseWheel(true)
        s:SetScript("OnMouseWheel",function(self,delta)
            local maximum=math.max(0,self.contentChild:GetHeight()-self:GetHeight())
            self:SetVerticalScroll(math.max(0,math.min(maximum,(self:GetVerticalScroll() or 0)-delta*36)))
        end)
    end
    return s,child
end
local function scrollContent(s,child,body,text,width,key)
    child:SetWidth(width); body:SetWidth(width); body:SetText(text)
    child:SetHeight(math.max(1,body:GetStringHeight()+8))
    if s.SetVerticalScroll then
        local maximum=math.max(0,child:GetHeight()-s:GetHeight())
        s:SetVerticalScroll(s.contentKey~=key and 0 or math.min(maximum,s:GetVerticalScroll() or 0))
    end
    s.contentKey=key
end
function U.Instruction(step)
    if not step then return "No next action" end
    if #step.members==1 then
        local m=step.members[1]; return step.action..": "..safe(m.label or m.quest.name)
    end
    if step.action=="ACCEPT ITEM" then return "Accept quests from items in your bags" end
    if step.action=="LOOT ITEM" then return "Collect nearby quest-starting drops" end
    if step.action=="PICK UP" then return "Collect nearby quests" end
    if step.action=="TURN IN" then return "Turn in nearby quests" end
    return "Work nearby objectives"
end
function U.MemberText(m)
    local name=safe(m.quest.name)
    local text=(m.label and m.label~=m.quest.name) and (name.."\n  "..safe(m.label)) or name
    if m.action=="DO" then
        local log=Q.state and Q.state.log and Q.state.log[m.id]
        if log then
            local task=Q.Trips.Tasks(m.quest)[m.task or 1]
            if task then
                local progress,known=Q.Trips.Progress(m.quest,task,log)
                text=text..(known and string.format(" (%.0f%%)",progress*100) or " (check quest log)")
            end
        end
    end
    if m.quest.dynamic and m.quest.stageOnly and m.action=="DO" then text=text.."\n  Current stage; return location not known yet." end
    return text
end
function U.SavePosition()
    local f=U.frame; local x,y=f:GetLeft(),f:GetTop()
    local scale=f.GetScale and f:GetScale() or 1
    if finite(x) and finite(y) and UIParent:GetWidth()>0 and UIParent:GetHeight()>0 then
        Q.db.position={x=x*scale/UIParent:GetWidth(),y=y*scale/UIParent:GetHeight(),normalized=true}
    end
end
function U.Place()
    local f,pos=U.frame,Q.db.position
    f:ClearAllPoints()
    local scale=f.GetScale and f:GetScale() or 1
    local w,h=UIParent:GetWidth()/scale,UIParent:GetHeight()/scale
    if type(pos)=="table" and finite(pos.x) and finite(pos.y) then
        local x,y=pos.x,pos.y
        if pos.normalized then x=x*w; y=y*h end
        x=math.max(0,math.min(math.max(0,w-f:GetWidth()),x)); y=math.max(math.min(f:GetHeight(),h),math.min(h,y))
        f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x,y)
    else f:SetPoint("CENTER",UIParent,"CENTER",0,0) end
end
local function fitFrame()
    local wanted=finite(Q.db.uiScale) and math.max(.8,math.min(1.3,Q.db.uiScale)) or 1
    local scale=math.max(.1,math.min(wanted,(UIParent:GetWidth()-16)/U.frame:GetWidth(),(UIParent:GetHeight()-16)/U.frame:GetHeight()))
    U.effectiveScale=scale
    if U.frame.SetScale then U.frame:SetScale(scale) end
    U.Place()
end
function U.ResetPosition() Q.db.position=nil; U.Place(); U.SavePosition() end
function U.SetScale(value)
    if not finite(value) then value=1 end
    U.SavePosition(); Q.db.uiScale=math.max(.8,math.min(1.3,value)); U.Render()
end
function U.Layout()
    if not U.frame then return end
    local compact=Q.db.compact
    local width=compact and 400 or 520
    local wanted=finite(Q.db.uiScale) and math.max(.8,math.min(1.3,Q.db.uiScale)) or 1
    -- UIParent dimensions already account for the player's global UI scale.
    local scale=math.min(wanted,(UIParent:GetWidth()-16)/width,(UIParent:GetHeight()-16)/(compact and 420 or 680))
    scale=math.max(.1,scale)
    U.effectiveScale=scale
    if U.frame.SetScale then U.frame:SetScale(scale) end
    U.frame:SetSize(width,compact and 330 or 680)
    U.width=width
    U.toggle:SetText(compact and "Details" or "Compact")
    U.scale:SetText(string.format("Size: %.0f%%",wanted*100))
    for _,widget in ipairs({U.summary,U.mode,U.skip,U.restore,U.scroll,U.footer}) do widget:SetShown(not compact) end
    U.Place()
end
function U.Create()
    local f=CreateFrame("Frame","QuestWeaverWindow",UIParent,BackdropTemplateMixin and "BackdropTemplate" or nil)
    U.frame=f; panel(f); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(false)
    U.drag=CreateFrame("Frame",nil,f); U.drag:SetPoint("TOPLEFT",12,-8); U.drag:SetPoint("TOPRIGHT",-214,-8); U.drag:SetHeight(30)
    U.drag:EnableMouse(true); U.drag:RegisterForDrag("LeftButton")
    U.drag:SetScript("OnDragStart",function() if not Q.db.locked then f:StartMoving() end end)
    U.drag:SetScript("OnDragStop",function() f:StopMovingOrSizing(); U.SavePosition() end)
    U.title=label(U.drag,"GameFontNormalLarge"); U.title:SetPoint("TOPLEFT",2,-5); U.title:SetText("QuestWeaver")
    U.build=label(f,nil,{.76,.80,.84}); U.zone=label(f)
    U.lock=button(f,"Lock",64,function() Q.db.locked=not Q.db.locked; U.Render() end,"Lock or unlock title dragging. /qw lock or /qw unlock")
    U.lock:SetPoint("TOPRIGHT",-142,-10)
    U.toggle=button(f,"Compact",78,function() U.SavePosition(); Q.db.compact=not Q.db.compact; U.Render() end,"Switch current-action and full-route layouts. /qw minimize or /qw expand")
    U.toggle:SetPoint("TOPRIGHT",-60,-10)
    U.close=button(f,"Hide",48,function() Q.db.hidden=true; f:Hide() end,"Hide the tracker. /qw shows it again; guidance keeps running.")
    U.close:SetPoint("TOPRIGHT",-8,-10)
    U.scale=button(f,"Size: 100%",100,function()
        local value=finite(Q.db.uiScale) and Q.db.uiScale or 1; U.SetScale(value>=1.29 and .8 or value+.1)
    end,"Cycle tracker size from 80% to 130%. Fits the available screen automatically.")
    U.action=label(f,nil,{.95,.78,.43}); U.nextText=label(f,"GameFontNormalLarge")
    U.alert=label(f,nil,{1,.80,.48})
    U.currentScroll,U.currentChild=scroll(f)
    U.current=label(U.currentChild); U.current:SetPoint("TOPLEFT")
    U.currentHint=label(f,nil,{.76,.80,.84})
    U.destination=label(f,nil,{.76,.80,.84})
    U.navStatus=label(f)
    U.way=button(f,"Waypoint",104,function() Q.Runtime.Waypoint() end,"Show the next destination. Without TomTom, try a map pin or print coordinates. /qw way")
    U.auto=button(f,"Auto: On",132,function()
        Q.Navigation.SetAutomatic(not Q.db.autoWaypoint); Q.Runtime.Refresh()
    end,"Automatic TomTom guidance. Your preference is kept if TomTom is unavailable. /qw auto on or off")
    U.feedback=button(f,"Feedback",108,function() Q.Runtime.FeedbackAction("show") end,"Save a local note or mark; select an export for manual review.")
    U.summary=label(f,nil,{.76,.80,.84})
    U.mode=button(f,"Balanced",132,function()
        Q.db.mode=({balanced="xp",xp="gear",gear="balanced"})[Q.db.mode]; Q.previous=nil; Q.Runtime.Refresh()
    end,"Cycle Balanced, Fastest XP and Gear focused. /qw mode balanced, xp or gear")
    U.skip=button(f,"Skip next quest",140,function()
        if Q.route and Q.route[1] then
            local id=Q.route[1].id; Q.db.skip[id]=true
            if Q.db.pin==id then Q.db.pin=nil end
            Q.previous=nil; Q.Runtime.Refresh()
        end
    end,function()
        local step=Q.route and Q.route[1]; local m=step and step.members[1]
        return m and ("Skip only "..safe(m.quest.name)..". Other quests at this stop stay planned; no quest is abandoned.") or "No quest to skip."
    end)
    U.restore=button(f,"Reset choices",124,function() Q.db.skip={}; Q.db.pin=nil; Q.previous=nil; Q.Runtime.Refresh() end,"Restore all skipped quests and clear the pinned quest. This never changes your quest log.")
    U.scroll,U.child=scroll(f); U.body=label(U.child); U.body:SetPoint("TOPLEFT")
    U.footer=label(f,nil,{.76,.80,.84}); U.footer:SetText("Later stops are forecasts. Times and quest XP are estimates.")
    U.Layout(); if Q.db.hidden then f:Hide() end; U.Render()
end
local function closeFeedback()
    U.clearArmed=false; U.feedbackClear:SetText("Clear history"); U.feedbackCancelClear:Hide()
    U.feedbackNote:ClearFocus(); U.feedbackReport:ClearFocus(); U.feedbackFrame:Hide()
end
function U.ShowFeedback(report)
    if not U.feedbackFrame then
        local f=CreateFrame("Frame","QuestWeaverFeedback",UIParent,BackdropTemplateMixin and "BackdropTemplate" or nil)
        U.feedbackFrame=f; f:SetSize(620,530); f:SetPoint("CENTER"); f:EnableMouse(true); f:SetClampedToScreen(true); f:SetMovable(true); panel(f)
        U.feedbackDrag=CreateFrame("Frame",nil,f); U.feedbackDrag:SetPoint("TOPLEFT",12,-8); U.feedbackDrag:SetPoint("TOPRIGHT",-96,-8); U.feedbackDrag:SetHeight(30)
        U.feedbackDrag:EnableMouse(true); U.feedbackDrag:RegisterForDrag("LeftButton")
        U.feedbackDrag:SetScript("OnDragStart",function() f:StartMoving() end)
        U.feedbackDrag:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
        local title=label(U.feedbackDrag,"GameFontNormalLarge"); title:SetPoint("TOPLEFT",4,-6); title:SetText("Playtest feedback")
        local help=label(f); at(help,f,16,48,586); help:SetText("Saved locally. Notes appear in exports; review them before sharing.\nAfter playing, reload or log out to save feedback for later review.")
        local noteLabel=label(f,"GameFontNormal"); at(noteLabel,f,16,96,580); noteLabel:SetText("Your note (optional; keep it brief)")
        U.feedbackNote=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); at(U.feedbackNote,f,22,120,574,28)
        U.feedbackNote:SetAutoFocus(false); U.feedbackNote:SetMaxLetters(240)
        U.feedbackNote:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        U.feedbackSave=button(f,"Save note / mark",148,function()
            local note=U.feedbackNote:GetText(); Q.Runtime.FeedbackAction("note",note); U.feedbackNote:SetText(""); U.feedbackNote:ClearFocus()
            U.feedbackStatus:SetText(note:match("%S") and "Note saved locally." or "Moment marked locally."); U.ShowFeedback(Q.db.feedbackReport)
        end); at(U.feedbackSave,f,16,160)
        U.feedbackStatus=label(f); at(U.feedbackStatus,f,180,165,420); U.feedbackStatus:SetText("A blank note marks this moment.")
        U.feedbackClear=button(f,"Clear history",128,function()
            if not U.clearArmed then
                U.clearArmed=true; U.feedbackClear:SetText("Confirm clear"); U.feedbackCancelClear:Show(); U.feedbackStatus:SetText("Clear all local feedback? Confirm or cancel.")
            else
                Q.Runtime.FeedbackAction("clear"); U.clearArmed=false; U.feedbackClear:SetText("Clear history"); U.feedbackCancelClear:Hide()
                U.feedbackStatus:SetText("Local feedback cleared."); U.ShowFeedback(Q.db.feedbackReport)
            end
        end); at(U.feedbackClear,f,310,202)
        U.feedbackCancelClear=button(f,"Cancel",80,function()
            U.clearArmed=false; U.feedbackClear:SetText("Clear history"); U.feedbackCancelClear:Hide(); U.feedbackStatus:SetText("History kept.")
        end); at(U.feedbackCancelClear,f,446,202); U.feedbackCancelClear:Hide()
        U.feedbackClose=button(f,"Close",72,closeFeedback); U.feedbackClose:SetPoint("TOPRIGHT",-16,-10)
        local copy=button(f,"Select report",128,function() U.feedbackReport:SetFocus(); U.feedbackReport:HighlightText() end); at(copy,f,16,202); U.feedbackCopy=copy
        local hint=label(f,nil,{.76,.80,.84}); at(hint,f,16,242,580); hint:SetText("EXPORT  -  Select report, then use your usual copy shortcut.")
        U.feedbackScroll=scroll(f); U.feedbackScroll:SetPoint("TOPLEFT",16,-272); U.feedbackScroll:SetPoint("BOTTOMRIGHT",-36,16)
        local edit=CreateFrame("EditBox",nil,U.feedbackScroll); U.feedbackReport=edit
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal or GameFontHighlight); edit:SetWidth(560)
        edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        U.feedbackScroll:SetScrollChild(edit); U.feedbackScroll.contentChild=edit
        -- Export is a selectable display; edits are discarded immediately.
        edit:SetScript("OnTextChanged",function(self,userInput)
            if userInput and not U.restoringReport then U.restoringReport=true; self:SetText(U.reportText or ""); U.restoringReport=false end
        end)
        U.feedbackMeasure=label(f); U.feedbackMeasure:SetWidth(560); U.feedbackMeasure:Hide()
        f:SetScript("OnUpdate",function(self,elapsed)
            self.fitElapsed=(self.fitElapsed or 0)+elapsed
            if self.fitElapsed<1 then return end
            self.fitElapsed=0
            local w,h=UIParent:GetWidth(),UIParent:GetHeight()
            if self.fitWidth~=w or self.fitHeight~=h then
                self.fitWidth=w; self.fitHeight=h
                if self.SetScale then self:SetScale(math.max(.1,math.min(1,(w-16)/620,(h-16)/530))) end
            end
        end)
        f:SetScript("OnHide",function() U.feedbackNote:ClearFocus(); U.feedbackReport:ClearFocus(); U.clearArmed=false; U.feedbackClear:SetText("Clear history"); U.feedbackCancelClear:Hide() end)
    end
    if U.feedbackFrame.SetScale then U.feedbackFrame:SetScale(math.max(.1,math.min(1,(UIParent:GetWidth()-16)/620,(UIParent:GetHeight()-16)/530))) end
    U.reportText=report or "No feedback yet."
    U.feedbackReport:SetText(U.reportText); U.feedbackMeasure:SetText(safe(U.reportText))
    U.feedbackReport:SetHeight(math.max(240,U.feedbackMeasure:GetStringHeight()+32))
    if U.feedbackScroll.SetVerticalScroll then U.feedbackScroll:SetVerticalScroll(0) end
    U.feedbackFrame:Show()
end
local actionNames={DO="Work nearby objectives",["PICK UP"]="Collect nearby quests",["TURN IN"]="Turn in nearby quests",["ACCEPT ITEM"]="Accept a quest from your bags",["LOOT ITEM"]="Look for a quest-starting drop"}
local function emptyTitle()
    if Q.inWorld==false then return "Loading - guidance paused" end
    local status=Q.status or ""
    if status:find("Waiting",1,true) then return "Waiting for quest information" end
    if status:find("No catalogue",1,true) then return "Guidance unavailable here" end
    return "No next action"
end
function U.Render()
    if not U.frame then return end
    U.Layout()
    if U.feedbackFrame and U.feedbackFrame:IsShown() and U.feedbackFrame.SetScale then
        U.feedbackFrame:SetScale(math.max(.1,math.min(1,(UIParent:GetWidth()-16)/620,(UIParent:GetHeight()-16)/530)))
    end
    local step=Q.route and Q.route[1]; local width=U.width; local inner=width-32
    U.build:SetText(U.BUILD); at(U.build,U.frame,16,44,inner,18)
    U.zone:SetText(safe(Q.Pack.name)); at(U.zone,U.frame,16,66,inner-112)
    U.zone:SetHeight(measured(U.zone))
    at(U.scale,U.frame,width-116,62)
    U.lock:SetText(Q.db.locked and "Unlock" or "Lock"); U.drag:EnableMouse(not Q.db.locked)
    U.mode:SetText(({xp="Fastest XP",balanced="Balanced",gear="Gear focused"})[Q.db.mode] or "Balanced")
    U.auto:SetText(Q.Navigation.Available() and (Q.db.autoWaypoint and "Auto: On" or "Auto: Off") or "Auto: unavailable")
    local header=math.max(102,66+measured(U.zone)+14)
    U.action:SetShown(not Q.db.compact)
    U.action:SetText(step and "NEXT ACTION" or "PLAN STATUS"); at(U.action,U.frame,16,header,inner,18)
    local headline=Q.db.compact and math.max(94,66+measured(U.zone)+12) or header+24
    U.nextText:SetText(step and (actionNames[step.action] or "Next step") or emptyTitle()); at(U.nextText,U.frame,16,headline,inner)
    local y=headline+measured(U.nextText)+10
    local trip=step and Q.trips and Q.trips[1]
    U.alert:SetText(trip and trip.urgent and "Timed quest - avoid detours" or "")
    at(U.alert,U.frame,16,y,inner,trip and trip.urgent and 18 or 1)
    if trip and trip.urgent then y=y+26 end
    local lines={}
    if step then
        for _,m in ipairs(step.members) do lines[#lines+1]=U.MemberText(m) end
        if #step.members>1 then
            local ids={}; local count=0
            for _,m in ipairs(step.members) do if not ids[m.id] then ids[m.id]=true; count=count+1 end end
            lines[#lines+1]=count..(count==1 and " quest" or " quests").." at this stop; waypoint leads to the first task."
        end
        local destination=Q.Navigation.Destination(step)
        if destination and destination.hint then lines[#lines+1]=safe(destination.hint) end
    else lines[1]=safe(Q.status or "Reading quest progress...") end
    for _,notice in ipairs(Q.notices or {}) do lines[#lines+1]=safe(notice) end
    local text=table.concat(lines,"\n\n")
    U.current:SetWidth(inner-24); U.current:SetText(text)
    local detailHeight=math.min(Q.db.compact and 116 or 118,math.max(24,U.current:GetStringHeight()+8))
    at(U.currentScroll,U.frame,16,y,inner-20,detailHeight)
    local key=step and (step.key or (step.action..":"..tostring(step.id))) or "empty"
    scrollContent(U.currentScroll,U.currentChild,U.current,text,inner-24,key)
    y=y+detailHeight+8
    local overflow=U.currentChild:GetHeight()>detailHeight
    U.currentHint:SetText(overflow and "Scroll for all tasks and notices" or "")
    at(U.currentHint,U.frame,16,y,inner,overflow and 18 or 1)
    y=y+(overflow and 26 or 4)
    local destination=Q.Navigation.Destination(step)
    local destText=""
    if step and step.action=="ACCEPT ITEM" then destText="Use the item and accept the quest yourself."
    elseif destination then destText=string.format("Destination  %.1f, %.1f\n%s",destination.x*100,destination.y*100,safe(step.target.source or "Starter estimate"))
    elseif step then destText="Location unavailable - check your quest log." end
    U.destination:SetText(destText); at(U.destination,U.frame,16,y,inner)
    y=y+(destText~="" and measured(U.destination)+10 or 0)
    U.navStatus:SetText(U.waypointStatus or (not Q.Navigation.Available() and not Q.Navigation.error and "TomTom unavailable - Waypoint uses a map pin or coordinates." or Q.Navigation.Status())); at(U.navStatus,U.frame,16,y,inner)
    y=y+measured(U.navStatus)+12
    U.way:SetEnabled(destination~=nil); U.skip:SetEnabled(step~=nil)
    at(U.way,U.frame,16,y); at(U.auto,U.frame,128,y); at(U.feedback,U.frame,width-124,y)
    y=y+40
    if Q.db.compact then
        U.frame:SetHeight(y); fitFrame(); return
    end
    U.summary:SetText(trip and string.format("THIS TRIP  %d quests | ~%.1f min | ~%d quest XP%s",#trip.quests,trip.minutes,trip.xp,trip.gearDetour and "\nGear upgrade favored within your allowance." or "") or "No current trip. Accept or advance quests to refresh.")
    at(U.summary,U.frame,16,y,inner); y=y+measured(U.summary)+12
    at(U.mode,U.frame,16,y); at(U.skip,U.frame,156,y); at(U.restore,U.frame,304,y); y=y+40
    local body={}; local index=0; local stop=0
    for _,group in ipairs(Q.route or {}) do
        if group.trip~=index then
            index=group.trip; body[#body+1]="|cffffd36a"..(index==1 and "CURRENT TRIP" or "LATER TRIP "..tostring(index)).."|r"
        end
        stop=stop+1
        body[#body+1]="|cffffd36a"..stop..". "..(actionNames[group.action] or "Next step").."|r"
        for _,m in ipairs(group.members) do body[#body+1]=U.MemberText(m) end
        if group.target and finite(group.target.x) and finite(group.target.y) then body[#body+1]=string.format("Destination %.1f, %.1f",group.target.x*100,group.target.y*100) end
        for _,m in ipairs(group.members) do if m.quest.note then body[#body+1]=safe(m.quest.note) end end
    end
    if trip and trip.stageOnly then body[#body+1]="Advance the current quest stage to reveal the rest of this trip." end
    for _,notice in ipairs(Q.notices or {}) do body[#body+1]=safe(notice) end
    if #body==0 then body[1]=safe(Q.status or "Waiting for quest information.") end
    local height=math.max(680,y+152)
    U.frame:SetHeight(height)
    at(U.scroll,U.frame,16,y,inner-20,height-y-48)
    scrollContent(U.scroll,U.child,U.body,table.concat(body,"\n\n"),inner-24,key)
    U.footer:SetText(U.child:GetHeight()>U.scroll:GetHeight() and "Scroll for later stops. Times and quest XP are estimates." or "Later stops are forecasts. Times and quest XP are estimates.")
    at(U.footer,U.frame,16,height-32,inner,28)
    fitFrame()
end
