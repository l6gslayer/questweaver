local _, Q = ...
Q.UI={}
local U=Q.UI
local function label(parent,size)
    local t=parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlightSmall")
    t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    return t
end
function U.Create()
    local f=CreateFrame("Frame","QuestWeaverWindow",UIParent,BackdropTemplateMixin and "BackdropTemplate" or nil)
    U.frame=f
    f:SetSize(460,600); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    if Q.db.position then f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",Q.db.position.x,Q.db.position.y)
    else f:SetPoint("CENTER",UIParent,"CENTER",280,0) end
    if f.SetBackdrop then
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=false,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
        f:SetBackdropColor(.035,.055,.065,.96); f:SetBackdropBorderColor(.25,.65,.48,1)
    end
    local title=label(f,"GameFontNormalLarge"); title:SetPoint("TOPLEFT",18,-17); title:SetText("QuestWeaver | Shadowglen")
    local drag=CreateFrame("Frame",nil,f); drag:SetPoint("TOPLEFT"); drag:SetPoint("TOPRIGHT"); drag:SetHeight(42); drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() if Q.unlocked then f:StartMoving() end end)
    drag:SetScript("OnDragStop",function() f:StopMovingOrSizing(); Q.db.position={x=f:GetLeft(),y=f:GetTop()} end)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3)
    close:SetScript("OnClick",function() Q.db.hidden=true; f:Hide() end)
    U.summary=label(f); U.summary:SetPoint("TOPLEFT",18,-46); U.summary:SetWidth(424)
    local function button(text,x,width,callback)
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); b:SetSize(width,24); b:SetPoint("TOPLEFT",x,-82); b:SetText(text); b:SetScript("OnClick",callback); return b
    end
    U.mode=button("Balanced",18,120,function()
        Q.db.mode=({balanced="xp",xp="gear",gear="balanced"})[Q.db.mode]; Q.Runtime.Refresh()
    end)
    button("Waypoint",146,90,function() Q.Runtime.Waypoint() end)
    button("Skip next",244,90,function() if Q.route and Q.route[1] then Q.db.skip[Q.route[1].id]=true; Q.Runtime.Refresh() end end)
    button("Restore",342,100,function() Q.db.skip={}; Q.db.pin=nil; Q.Runtime.Refresh() end)
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-122); scroll:SetPoint("BOTTOMRIGHT",-36,76)
    local child=CreateFrame("Frame",nil,scroll); child:SetWidth(398); child:SetHeight(1); scroll:SetScrollChild(child)
    U.body=label(child); U.body:SetPoint("TOPLEFT"); U.body:SetWidth(398)
    U.child=child
    local footer=label(f); footer:SetPoint("BOTTOMLEFT",18,14); footer:SetWidth(424)
    footer:SetText("Alpha: times, XP and objective locations are estimates.\n/qw help for profiles, detour budget and pinning.\nNo automatic accepting, abandoning, equipping or movement.")
    if Q.db.hidden then f:Hide() end
    U.Render()
end
function U.Render()
    if not U.frame then return end
    U.mode:SetText(({xp="Fastest XP",balanced="Balanced",gear="Gear focused"})[Q.db.mode])
    U.summary:SetText(string.format("%s profile | gear detour up to %.0f min\n%s",Q.db.profile,Q.db.budget,QuestDB and "QuestieDB metadata available; objectives use starter pack" or "Starter baseline; Forever locations need verification"))
    local lines={"|cff8ae8b1"..(Q.status or "Reading quest progress...").."|r"}
    for i,step in ipairs(Q.route or {}) do
        lines[#lines+1]=string.format("\n|cffffd36a%d. %s: %s|r",i,step.action,step.name)
        lines[#lines+1]=string.format("Quest %d | %.1f, %.1f%s",step.id,step.target.x*100,step.target.y*100,Q.db.pin==step.id and " | PINNED" or "")
        for _,reason in ipairs(step.reasons) do lines[#lines+1]="  "..reason end
        if step.quest.note then lines[#lines+1]="|cffffb08a"..step.quest.note.."|r" end
    end
    U.body:SetText(table.concat(lines,"\n"))
    U.child:SetHeight(math.max(1,U.body:GetStringHeight()+24))
end
