local Q,test=...
-- Interaction/layout simulation only: approximate metrics, not game rendering.
local methods={}
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width or 500 end
function methods:GetHeight() return self.height or 640 end
function methods:GetLeft() return self.left or 400 end
function methods:GetTop() return self.top or 800 end
function methods:SetPoint(point,parent,relative,x,y)
    self.points=self.points or {}; self.points[point]={point,parent,relative,x,y}
    self.anchor={point,parent,relative,x,y}
    if point=="TOPLEFT" and type(parent)=="table" and relative=="BOTTOMLEFT" then self.left=x; self.top=y end
    if point=="CENTER" then self.left=400; self.top=800 end
end
function methods:ClearAllPoints() self.anchor=nil; self.points={} end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text or "" end
function methods:GetStringHeight()
    local n=0
    -- Deliberately approximate; meaningful overflow fixtures are much longer
    -- than viewport bounds. Native font/localization QA remains a playtest.
    local text=(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    for line in (text.."\n"):gmatch("(.-)\n") do n=n+math.max(1,math.ceil(#line*7/self:GetWidth())) end
    return n*(self.fontSize or 14)
end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:EnableMouse(value) self.mouse=value end
function methods:EnableMouseWheel(value) self.mouseWheel=value end
function methods:SetShown(value) self.shown=value end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:SetEnabled(value) self.enabled=value end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:SetScale(value) self.scale=value end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return self:GetScale()*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(value) self.scrollValue=value end
function methods:GetVerticalScroll() return self.scrollValue or 0 end
function methods:GetVerticalScrollRange() return math.max(0,(self.scrollChild and self.scrollChild:GetHeight() or 0)-self:GetHeight()) end
function methods:SetFontObject(font) self.fontObject=font end
function methods:GetFont() return "synthetic-font",self.fontSize or 14,"" end
function methods:SetFont(path,size,flags) self.fontSize=size end
function methods:SetFocus() self.focused=true end
function methods:ClearFocus() self.focused=false end
function methods:HasFocus() return self.focused==true end
function methods:HighlightText() self.highlighted=true end
for _,name in ipairs({"SetJustifyH","SetJustifyV","SetClampedToScreen","SetMovable","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","RegisterForDrag","RegisterEvent","SetMultiLine","SetAutoFocus","SetMaxLetters","SetTextColor","SetSpacing","SetWordWrap","SetNonSpaceWrap","SetFrameStrata","SetFrameLevel","SetHitRectInsets","SetClipsChildren","SetPropagateMouseClicks","SetPropagateMouseMotion"}) do
    methods[name]=function() end
end
local function frame(_,name,parent) return setmetatable({scripts={},shown=true,parent=parent,name=name},{__index=methods}) end
function methods:CreateFontString() return frame(nil,nil,self) end
CreateFrame=frame
UIParent=frame(); UIParent:SetSize(1200,900)
assert(loadfile("QuestWeaver/UI.lua"))("QuestWeaver",Q)
local U=Q.UI
Q.db={mode="balanced",profile="melee",budget=10,skip={},rewards={},completed={},locked=false,compact=false}
Q.route={}; Q.trips={}; Q.state={log={}}
U.Create()

test("expanded tracker starts movable with visible lock/minimize controls",function()
    assert(U.frame:GetWidth()>0 and U.drag.mouse and U.lock.text=="Lock" and U.toggle.text=="Compact")
    U.drag.scripts.OnDragStart(); assert(U.frame.moving)
    U.drag.scripts.OnDragStop(); assert(not U.frame.moving and Q.db.position.normalized)
end)
test("lock button prevents dragging and persists preference",function()
    U.lock.scripts.OnClick(); assert(Q.db.locked and not U.drag.mouse and U.lock.text=="Unlock")
    U.drag.scripts.OnDragStart(); assert(not U.frame.moving)
    U.lock.scripts.OnClick(); assert(not Q.db.locked and U.drag.mouse)
end)
test("minimize preserves top-left position and shows only current action",function()
    U.frame.left=170; U.frame.top=780
    U.toggle.scripts.OnClick()
    assert(Q.db.compact and U.frame:GetWidth()<520 and U.frame:GetLeft()==170 and U.frame:GetTop()==780)
    assert(not U.scroll.shown and not U.mode.shown and not U.footer.shown and U.toggle.text=="Details")
    assert(U.way.shown and U.drag.mouse)
end)
test("expand restores route controls and position",function()
    U.toggle.scripts.OnClick()
    assert(not Q.db.compact and U.scroll.shown and U.mode.shown and U.frame:GetLeft()==170 and U.frame:GetTop()==780)
end)
test("legacy pixel position migrates to normalized saved position",function()
    Q.db.position={x=120,y=750}; U.Place(); U.SavePosition()
    assert(Q.db.position.normalized and Q.db.position.x==.1 and math.abs(Q.db.position.y-750/900)<.001)
end)
test("offscreen saved positions clamp and reset is reachable",function()
    Q.db.position={x=99999,y=-100}; U.Place()
    assert(U.frame:GetLeft()+U.frame:GetWidth()<=UIParent:GetWidth() and U.frame:GetTop()>=U.frame:GetHeight())
    U.ResetPosition(); assert(Q.db.position.normalized and U.frame:GetLeft()==400)
end)
test("compact content groups quests and displays live progress",function()
    local a={id=916,name="Webwood Venom",objective={x=.57,y=.32},minutes=6}
    local b={id=3521,name="Antidote",objective=a.objective,minutes=6}
    local step={id=916,action="DO",target=a.objective,members={
        {id=916,quest=a,action="DO",task=1}, {id=3521,quest=b,action="DO",task=1}}}
    Q.route={step}; Q.state={log={[916]={progress=.5},[3521]={progress=.25}}}
    Q.db.compact=true; U.Layout(); U.Render()
    assert(U.nextText.text and #U.nextText.text>0)
    assert(U.current.text:find("50%%") and U.current.text:find("25%%") and U.current.text:find("Webwood Venom",1,true) and U.current.text:find("Antidote",1,true))
    assert(U.frame:GetHeight()*U.frame:GetScale()<=UIParent:GetHeight() and U.way.enabled)
end)
test("empty or out-of-zone compact tracker stays useful",function()
    Q.route={}; Q.status="Travel to Shadowglen"; U.Render()
    assert(U.current.text:find(Q.status,1,true) and not U.way.enabled and U.toggle.text=="Details")
end)
test("compact mode and lock preference survive simulated reload",function()
    Q.db.locked=true; Q.db.compact=true; Q.db.hidden=true
    QuestWeaverDB=Q.db
    assert(loadfile("QuestWeaver/Runtime.lua"))("QuestWeaver",Q)
    Q.events:GetScript("OnEvent")(nil,"ADDON_LOADED","QuestWeaver")
    assert(Q.db.schema==3 and Q.db.autoWaypoint and Q.db.compact and Q.db.locked and not U.frame:IsShown())
    assert(U.frame:GetWidth()<520 and not U.drag.mouse)
end)
test("slash controls change layout, lock and reset position",function()
    SlashCmdList.QUESTWEAVER("expand"); assert(not Q.db.compact and U.scroll.shown)
    SlashCmdList.QUESTWEAVER("minimize"); assert(Q.db.compact and not U.scroll.shown)
    SlashCmdList.QUESTWEAVER("unlock"); assert(not Q.db.locked)
    SlashCmdList.QUESTWEAVER("lock"); assert(Q.db.locked)
    SlashCmdList.QUESTWEAVER("resetposition"); assert(Q.db.position.normalized)
end)

local function syntheticStop(key,count)
    local target={x=.52,y=.44,mapID=Q.Pack.mapID,source="WoW objective"}
    local step={key=key,id=916,action="DO",target=target,members={}}
    for i=1,count do
        local quest={id=9000+i,name="Synthetic parent quest "..i.." "..string.rep("Long name ",10),objective=target,minutes=6}
        step.members[i]={id=quest.id,quest=quest,action="DO",label="Distinct objective "..i.." "..string.rep("Long objective ",12),target=target}
    end
    return step
end

test("all long grouped objectives and notices remain reachable through current scroll",function()
    local oldRoute,oldNotices,oldState=Q.route,Q.notices,Q.state
    Q.route={syntheticStop("long-stop",5)};Q.notices={"Synthetic final notice "..string.rep("long notice ",15)};Q.state={log={}}
    for _,compact in ipairs({true,false}) do
        Q.db.compact=compact;U.Layout();U.Render()
        assert(U.current.text:find("Synthetic parent quest 5",1,true),"all grouped parent quests must remain available")
        assert(U.current.text:find("Distinct objective 5",1,true),"task labels must retain parent association")
        assert(U.current.text:find("Synthetic final notice",1,true),"notices must be reachable")
        assert(U.currentChild:GetHeight()>U.currentScroll:GetHeight(),"overflow needs a real scroll extent")
        assert(U.currentScroll.mouseWheel and U.currentScroll:GetScript("OnMouseWheel"),"overflow must accept wheel input")
        U.currentScroll:GetScript("OnMouseWheel")(U.currentScroll,-100)
        assert(U.currentScroll:GetVerticalScroll()>0,"wheel must move into overflowing detail")
        assert(U.currentScroll:GetVerticalScroll()<=U.currentScroll:GetVerticalScrollRange())
    end
    Q.route,Q.notices,Q.state=oldRoute,oldNotices,oldState;U.Render()
end)

test("current scroll preserves stable reading and resets when the next action changes",function()
    local oldRoute,oldNotices=Q.route,Q.notices
    Q.route={syntheticStop("reading-a",4)};Q.notices={};U.Render()
    U.currentScroll:SetVerticalScroll(40);U.Render()
    assert(U.currentScroll:GetVerticalScroll()==40,"unchanged next action should preserve reading position")
    Q.route={syntheticStop("reading-b",4)};U.Render()
    assert(U.currentScroll:GetVerticalScroll()==0,"new next action must begin at the top")
    U.currentScroll:SetVerticalScroll(99999);Q.route={};U.Render()
    assert(U.currentScroll:GetVerticalScroll()<=U.currentScroll:GetVerticalScrollRange(),"shrunk content must clamp old offset")
    Q.route,Q.notices=oldRoute,oldNotices;U.Render()
end)

test("waypoint control rejects invalid and absent destinations without mutating automatic preference",function()
    local oldRoute,oldAuto=Q.route,Q.db.autoWaypoint
    local step=syntheticStop("invalid-location",1);step.target={x=0/0,y=.4};Q.route={step};U.Render()
    assert(not U.way.enabled,"NaN location is not a usable destination")
    step.target={x=2,y=.4};U.Render();assert(not U.way.enabled)
    step.target=nil;U.Render();assert(not U.way.enabled)
    step.target={x=.5,y=.4};step.action="ACCEPT ITEM";U.Render();assert(not U.way.enabled)
    Q.route={};U.Render();assert(not U.way.enabled)
    assert(Q.db.autoWaypoint==oldAuto)
    Q.route=oldRoute;U.Render()
end)

test("missing TomTom describes unavailable guidance while retaining the saved preference",function()
    local oldTomTom,oldAuto=TomTom,Q.db.autoWaypoint
    TomTom=nil;Q.db.autoWaypoint=true;U.Render()
    assert(Q.db.autoWaypoint and U.auto:GetText():lower():find("unavailable",1,true))
    TomTom,Q.db.autoWaypoint=oldTomTom,oldAuto;U.Render()
end)

test("scaled layouts fit constrained screens and malformed saved positions recover",function()
    local oldW,oldH=UIParent:GetWidth(),UIParent:GetHeight()
    local oldScale,oldPosition,oldCompact=Q.db.uiScale,Q.db.position,Q.db.compact
    UIParent:SetSize(800,600)
    for _,compact in ipairs({true,false}) do
        Q.db.compact=compact;Q.db.position={x=0/0,y=math.huge,normalized=true}
        U.SetScale(1.3);U.Layout();U.Render()
        local scale=U.frame:GetScale()
        assert(U.frame:GetWidth()*scale<=800+.01 and U.frame:GetHeight()*scale<=600+.01,"effective frame must fit available screen")
        U.SavePosition()
        assert(Q.db.position.x==Q.db.position.x and Q.db.position.y==Q.db.position.y,"saved coordinates must stay finite")
    end
    U.SetScale(99);assert(Q.db.uiScale<=1.3)
    U.SetScale(-1);assert(Q.db.uiScale>=.8)
    UIParent:SetSize(oldW,oldH);Q.db.uiScale,Q.db.position,Q.db.compact=oldScale,oldPosition,oldCompact;U.Layout();U.Render()
end)

test("waiting and empty plans leave controls usable and never offer an invalid waypoint",function()
    local oldRoute,oldStatus,oldWorld,oldState=Q.route,Q.status,Q.inWorld,Q.state
    Q.route={};Q.inWorld=false;Q.status="Waiting for the world to load.";U.Render()
    assert(not U.way.enabled and U.current:GetText():find("Waiting",1,true))
    Q.inWorld=true;Q.status="No eligible quests remain. Check your quest log.";U.Render()
    assert(not U.way.enabled and U.current:GetText():find("quest log",1,true))
    assert(U.toggle:IsShown() and U.feedback:IsShown() and U.close:IsShown())
    Q.route,Q.status,Q.inWorld,Q.state=oldRoute,oldStatus,oldWorld,oldState;U.Render()
end)

test("size control recovers malformed legacy scale values without losing saved preferences",function()
    local oldScale,oldLocked,oldAuto=Q.db.uiScale,Q.db.locked,Q.db.autoWaypoint
    for _,invalid in ipairs({"invalid",0/0,math.huge,-math.huge}) do
        Q.db.uiScale=invalid;U.scale:GetScript("OnClick")()
        assert(type(Q.db.uiScale)=="number" and Q.db.uiScale==Q.db.uiScale and Q.db.uiScale>=.8 and Q.db.uiScale<=1.3)
        assert(Q.db.locked==oldLocked and Q.db.autoWaypoint==oldAuto)
    end
    Q.db.uiScale=oldScale;U.Render()
end)
