local Q,test=...
-- Layout/state simulation only. These stubs do not render the actual game UI.
local methods={}
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width or 500 end
function methods:GetHeight() return self.height or 640 end
function methods:GetLeft() return self.left or 400 end
function methods:GetTop() return self.top or 800 end
function methods:SetPoint(point,parent,relative,x,y)
    self.anchor={point,parent,relative,x,y}
    if point=="TOPLEFT" and type(parent)=="table" and relative=="BOTTOMLEFT" then self.left=x; self.top=y end
    if point=="CENTER" then self.left=400; self.top=800 end
end
function methods:ClearAllPoints() self.anchor=nil end
function methods:SetText(text) self.text=text end
function methods:GetStringHeight()
    local n=0
    for line in ((self.text or "").."\n"):gmatch("(.-)\n") do n=n+math.max(1,math.ceil(#line*6/self:GetWidth())) end
    return n*12
end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:EnableMouse(value) self.mouse=value end
function methods:SetShown(value) self.shown=value end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetEnabled(value) self.enabled=value end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
for _,name in ipairs({"SetJustifyH","SetJustifyV","SetClampedToScreen","SetMovable","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","RegisterForDrag","RegisterEvent","SetScrollChild"}) do
    methods[name]=function() end
end
local function frame() return setmetatable({scripts={},shown=true},{__index=methods}) end
function methods:CreateFontString() return frame() end
CreateFrame=frame
UIParent=frame(); UIParent:SetSize(1200,900)
assert(loadfile("QuestWeaver/UI.lua"))("QuestWeaver",Q)
local U=Q.UI
Q.db={mode="balanced",profile="melee",budget=10,skip={},rewards={},completed={},locked=false,compact=false}
Q.route={}; Q.trips={}; Q.state={log={}}
U.Create()

test("expanded tracker starts movable with visible lock/minimize controls",function()
    assert(U.frame:GetWidth()==500 and U.drag.mouse and U.lock.text=="Lock" and U.toggle.text=="-")
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
    assert(Q.db.compact and U.frame:GetWidth()==360 and U.frame:GetLeft()==170 and U.frame:GetTop()==780)
    assert(not U.scroll.shown and not U.mode.shown and not U.footer.shown and U.toggle.text=="+")
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
    assert(U.frame:GetLeft()<=700 and U.frame:GetTop()>=640)
    U.ResetPosition(); assert(Q.db.position.normalized and U.frame:GetLeft()==400)
end)
test("compact content groups quests and displays live progress",function()
    local a={id=916,name="Webwood Venom",objective={x=.57,y=.32},minutes=6}
    local b={id=3521,name="Antidote",objective=a.objective,minutes=6}
    local step={id=916,action="DO",target=a.objective,members={
        {id=916,quest=a,action="DO",task=1}, {id=3521,quest=b,action="DO",task=1}}}
    Q.route={step}; Q.state={log={[916]={progress=.5},[3521]={progress=.25}}}
    Q.db.compact=true; U.Layout(); U.Render()
    assert(U.nextText.text=="Work nearby objectives")
    assert(U.current.text:find("50%%") and U.current.text:find("25%%") and U.current.text:find("2 quests"))
    assert(U.frame:GetHeight()<=340 and U.way.enabled)
end)
test("empty or out-of-zone compact tracker stays useful",function()
    Q.route={}; Q.status="Travel to Shadowglen"; U.Render()
    assert(U.current.text==Q.status and not U.way.enabled and U.toggle.text=="+")
end)
test("compact mode and lock preference survive simulated reload",function()
    Q.db.locked=true; Q.db.compact=true; Q.db.hidden=true
    QuestWeaverDB=Q.db
    assert(loadfile("QuestWeaver/Runtime.lua"))("QuestWeaver",Q)
    Q.events:GetScript("OnEvent")(nil,"ADDON_LOADED","QuestWeaver")
    assert(Q.db.schema==2 and Q.db.compact and Q.db.locked and not U.frame:IsShown())
    assert(U.frame:GetWidth()==360 and not U.drag.mouse)
end)
test("slash controls change layout, lock and reset position",function()
    SlashCmdList.QUESTWEAVER("expand"); assert(not Q.db.compact and U.scroll.shown)
    SlashCmdList.QUESTWEAVER("minimize"); assert(Q.db.compact and not U.scroll.shown)
    SlashCmdList.QUESTWEAVER("unlock"); assert(not Q.db.locked)
    SlashCmdList.QUESTWEAVER("lock"); assert(Q.db.locked)
    SlashCmdList.QUESTWEAVER("resetposition"); assert(Q.db.position.normalized)
end)
