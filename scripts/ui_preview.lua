-- Offline only: execute actual UI code against synthetic frame APIs.
-- Produces geometry/text data; never loads Runtime or SavedVariables.
local output=assert(QW_PREVIEW_OUTPUT,"QW_PREVIEW_OUTPUT required")
local source=QW_PREVIEW_SOURCE or "QuestWeaver/UI.lua"
local nodes={}
local methods={}
local function make(kind,name,parent,template)
 local f=setmetatable({id=#nodes+1,kind=kind,name=name,parent=parent and parent.id,template=template,scripts={},anchors={},shown=true}, {__index=methods})
 nodes[#nodes+1]=f; return f
end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetWidth() return self.w or (self.parent and nodes[self.parent]:GetWidth()) or 400 end
function methods:GetHeight() return self.h or self:GetStringHeight() end
function methods:GetLeft() return 24 end
function methods:GetTop() return nodes[1].h-24 end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetScale() return self.scale or 1 end
function methods:SetScale(v) self.scale=v end
function methods:SetPoint(point,a,b,c,d)
 local rel,rpoint,x,y
 if type(a)=="table" then rel=a.id;rpoint=type(b)=="string" and b or point;x=c or 0;y=d or 0
 else rel=self.parent or 1;rpoint=point;x=a or 0;y=b or 0 end
 self.anchors[#self.anchors+1]={point=point,relative=rel,relativePoint=rpoint,x=x,y=y}
end
function methods:ClearAllPoints() self.anchors={} end
function methods:SetAllPoints(parent) self.anchors={{point="TOPLEFT",relative=(parent or nodes[self.parent]).id,relativePoint="TOPLEFT",x=0,y=0},{point="BOTTOMRIGHT",relative=(parent or nodes[self.parent]).id,relativePoint="BOTTOMRIGHT",x=0,y=0}} end
function methods:SetText(s) self.text=tostring(s or "") end
function methods:GetText() return self.text or "" end
function methods:GetStringHeight()
 local size=self.fontSize or (self.font=="GameFontNormalLarge" and 16 or self.font=="GameFontHighlightSmall" and 12 or 13)
 local text=(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("||","|")
 local rows=0
 for line in (text.."\n"):gmatch("(.-)\n") do rows=rows+math.max(1,math.ceil(#line*size*.48/math.max(1,self:GetWidth()))) end
 return rows*(size+3)
end
function methods:SetFontObject(font) self.font=font end
function methods:GetFont() return "",self.fontSize or 13,"" end
function methods:SetFont(path,size,flags) self.fontSize=size end
function methods:SetTextColor(r,g,b,a) self.color={r,g,b,a or 1} end
function methods:SetBackdropColor(r,g,b,a) self.bg={r,g,b,a or 1} end
function methods:SetBackdropBorderColor(r,g,b,a) self.border={r,g,b,a or 1} end
function methods:SetColorTexture(r,g,b,a) self.bg={r,g,b,a or 1} end
function methods:SetScript(n,fn) self.scripts[n]=fn end
function methods:HookScript(n,fn) self.scripts[n]=fn end
function methods:GetScript(n) return self.scripts[n] end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(v) self.shown=v end
function methods:IsShown() return self.shown end
function methods:SetEnabled(v) self.enabled=v end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetScrollChild(child) self.child=child.id;child.scrollParent=self.id end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:SetJustifyH(v) self.justify=v end
function methods:CreateFontString(name,layer,font) local f=make("FontString",name,self);f.font=font or "GameFontHighlightSmall"; return f end
function methods:CreateTexture(name,layer) return make("Texture",name,self) end
for _,name in ipairs({"SetJustifyV","SetClampedToScreen","SetMovable","SetBackdrop","RegisterForDrag","RegisterEvent","SetMultiLine","SetAutoFocus","SetMaxLetters","HighlightText","SetFocus","ClearFocus","StartMoving","StopMovingOrSizing","SetWordWrap","SetNonSpaceWrap","EnableMouseWheel","SetFrameStrata","SetFrameLevel","SetClipsChildren","SetHitRectInsets","SetTextInsets","SetHyperlinksEnabled","SetMaxBytes","SetCursorPosition","SetNormalFontObject","SetHighlightFontObject","SetDisabledFontObject"}) do methods[name]=function() end end
CreateFrame=make
BackdropTemplateMixin={};GameFontHighlightSmall="GameFontHighlightSmall";GameFontHighlight="GameFontHighlight";GameFontNormal="GameFontNormal";ChatFontNormal="ChatFontNormal"
local function encode(v)
 if type(v)=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[%z\1-\8\11\12\14-\31]','')..'"' end
 if type(v)=="number" or type(v)=="boolean" then return tostring(v) end
 if type(v)~="table" then return "null" end
 local a={};if #v>0 then for _,x in ipairs(v) do a[#a+1]=encode(x) end;return '['..table.concat(a,',')..']' end
 for k,x in pairs(v) do if type(x)~="function" and k~="scripts" then a[#a+1]=encode(k)..":"..encode(x) end end
 return '{'..table.concat(a,',')..'}'
end
local cases={"compact-grouped","expanded-grouped","grouped-pickups","grouped-returns","item-start","long-localized","missing-location","missing-other-location","invalid-target","missing-tomtom","loading","empty","zone-handoff","feedback","single-live","options","small-viewport"}
local all={}
for _,case in ipairs(cases) do
 nodes={}; UIParent=make("Root");UIParent:SetSize(case=="small-viewport" and 800 or 1280,case=="small-viewport" and 600 or 900)
 local Q={db={compact=case~="expanded-grouped" and case~="small-viewport",locked=false,hidden=false,autoWaypoint=true,mode="balanced",profile="melee",budget=10,skip={},feedbackReport="Synthetic playtest note\nNo private game information."},Pack={name="Teldrassil",mapID=1438},state={log={}},notices={}}
 Q.Feedback={BUILD="0.2.0-route-feedback-9"};Q.Runtime={Refresh=function() end,Waypoint=function() end,FeedbackAction=function() end}
 -- Real navigation presentation with a synthetic owner; no game APIs called.
 TomTom=case~="missing-tomtom" and {AddWaypoint=function() return "synthetic-owned-point" end,RemoveWaypoint=function() end} or nil
 assert(loadfile("QuestWeaver/Navigation.lua"))("QuestWeaver",Q)
 Q.Trips={Tasks=function(q) return q.tasks or {{label=q.name}} end,Progress=function(q,t,l) return l.progress or 0,true end}
 local members={}
 for i,name in ipairs({"Woodland Protector","Nature's Call","Iverron's Antidote","A Further Journey"}) do
  local q={id=100+i,name=name,xp=450,minutes=4}
  members[i]={id=q.id,quest=q,action="DO",target={x=.563,y=.456,source="WoW objective"},task=1};Q.state.log[q.id]={progress=i*.2}
 end
 members[3].label="Collect Moonpetal Lilies";members[3].quest.tasks={{label=members[3].label}}
 if case=="long-localized" then members[1].quest.name="Die außerordentlich lange Reise durch die uralten Wälder von Teldrassil";members[2].quest.name="Les protecteurs de la forêt et les mystères des anciens" end
 local step={id=101,action="DO",members=members,target=members[1].target,trip=1,tripKey="synthetic",key="synthetic"}
 Q.route={step,{id=101,action="TURN IN",target=step.target,members={{id=101,quest=members[1].quest,action="TURN IN",target=step.target}},trip=1}}
 Q.trips={{quests={members[1].quest,members[2].quest,members[3].quest,members[4].quest},xp=1800,minutes=12,urgent=false}}
 if case=="grouped-pickups" or case=="grouped-returns" or case=="item-start" then
  local action=case=="grouped-pickups" and "PICK UP" or case=="grouped-returns" and "TURN IN" or "ACCEPT ITEM"
  step.action=action;for _,m in ipairs(members) do m.action=action end
 end
 if case=="single-live" then
  local m=members[1]
  m.quest.name="Forest Watch"
  m.quest.note="Catalogue pickup: check availability. Objective work requires the current quest location; work/travel are estimates."
  step.members={m}
  Q.route={step,{id=m.id,action="TURN IN",target=step.target,members={{id=m.id,quest=m.quest,action="TURN IN",target=step.target}},trip=1}}
  Q.state.log[m.id]={progress=.625,objectives={{text="Forest sentries defeated",numFulfilled=4,numRequired=7,finished=false},{text="Moon charm",numFulfilled=1,numRequired=1,finished=true}}}
  Q.trips[1].quests={m.quest};Q.trips[1].xp=875;Q.trips[1].minutes=4.3
  Q.db.compact=false
 end
 Q.status="Next action is live. Later steps assume you complete this trip."
 if case=="long-localized" then Q.notices={"A long synthetic quest reminder whose details must remain readable when the window is narrow."};Q.trips[1].urgent=true end
 if case=="missing-location" or case=="missing-other-location" then
  Q.notices={"The distant errand: location unavailable. Check the quest log."}
  if case=="missing-location" then Q.route={};Q.trips={};Q.status="No eligible quests remain. Check your level, skips, prerequisites and quest log." end
 end
 if case=="invalid-target" then
  -- Defensive UI case: not a claim that the planner emits invalid locations.
  step.target={x="unavailable"};Q.route={step}
  Q.notices={"The distant errand: location unavailable. Check the quest log."}
 end
 if case=="zone-handoff" then Q.route={};Q.trips={};Q.status="No eligible quests remain. Check your level, skips, prerequisites and quest log.";Q.notices={"A Further Journey: continue in Darkshore. Check the quest log for travel details."} end
 if case=="loading" or case=="empty" then Q.route={};Q.trips={};Q.inWorld=case~="loading";Q.status=case=="loading" and "Waiting for the world to load." or "No eligible quests remain. Check your level, skips, prerequisites and quest log." end
 Q.Navigation.Sync(Q.route[1])
 local ok,err=pcall(function()
  assert(loadfile(source))("QuestWeaver",Q);Q.UI.Create()
  if case=="feedback" then Q.UI.ShowFeedback(Q.db.feedbackReport) end
  if case=="options" and Q.UI.options then Q.UI.options:GetScript("OnClick")() end
 end)
 for key,f in pairs(Q.UI) do if type(f)=="table" and f.id then f.role=key end end
 all[#all+1]={name=case,width=UIParent.w,height=UIParent.h,nodes=nodes,error=not ok and tostring(err) or nil}
end
local file=assert(io.open(output,"w"));file:write(encode(all));file:close()
