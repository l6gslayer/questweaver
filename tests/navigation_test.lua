local Q,test=...
local N=Q.Navigation
local function step(id,x)
    local q={id=id or 916,name="Webwood Venom"}
    return {id=q.id,name=q.name,key=q.id..":task:1",action="DO",target={x=x or .575,y=.328},
        members={{id=q.id,quest=q,action="DO",label="Gather venom",task=1}}}
end
local function setup()
    N.current=nil; N.error=nil; Q.db.autoWaypoint=true; Q.inWorld=true
    local spy={added={},removed={},selected={},points={},profile={arrow={autoqueue=false}},other={}}
    function spy:AddWaypoint(map,x,y,options)
        local uid={index=#self.added+1}
        self.added[#self.added+1]={map=map,x=x,y=y,options=options,uid=uid}
        self.points[uid]=true
        if options.crazy then self.active=uid end
        return uid
    end
    function spy:RemoveWaypoint(uid)
        assert(uid~=self.other,"must never delete another user's waypoint")
        self.removed[#self.removed+1]=uid; self.points[uid]=nil
        if self.active==uid then self.active=nil end
    end
    function spy:SetCrazyArrow(uid,distance,title)
        self.selected[#self.selected+1]={uid=uid,distance=distance,title=title}; self.active=uid
    end
    function spy:IsValidWaypoint(uid) return self.points[uid]==true end
    TomTom=spy
    return spy
end

test("automatic TomTom point is temporary, silent and arrow-enabled",function()
    local spy=setup(); N.Sync(step())
    local a=spy.added[1]
    assert(a.map==Q.Pack.mapID and a.x==.575 and a.y==.328)
    assert(a.options.crazy and not a.options.persistent and a.options.silent)
    assert(a.options.source=="QuestWeaver" and a.options.from=="QuestWeaver")
    assert(a.options.cleardistance==0 and a.options.arrivaldistance==10)
    assert(not spy.profile.arrow.autoqueue)
end)
test("unchanged automatic updates do not duplicate or repeatedly retarget",function()
    local spy=setup(); N.Sync(step())
    spy.active=spy.other
    for _=1,10 do N.Sync(step()) end
    assert(#spy.added==1 and #spy.removed==0 and #spy.selected==0 and spy.active==spy.other)
end)
test("next action removes only the owned UID and creates its replacement",function()
    local spy=setup(); N.Sync(step()); local first=N.current.uid
    N.Sync(step(3521,.58))
    assert(#spy.added==2 and #spy.removed==1 and spy.removed[1]==first and N.current.uid~=first)
end)
test("no next action clears our destination once",function()
    local spy=setup(); N.Sync(step()); N.Sync(nil); N.Sync(nil)
    assert(N.current==nil and #spy.removed==1)
end)
test("automatic toggle clears our point without deleting another arrow",function()
    local spy=setup(); N.Sync(step()); spy.active=spy.other
    N.SetAutomatic(false); N.Sync(step(3521))
    assert(not Q.db.autoWaypoint and not N.current and #spy.added==1 and spy.active==spy.other)
end)
test("manual waypoint works with automatic guidance disabled",function()
    local spy=setup(); N.SetAutomatic(false); assert(N.Show(step(),true))
    N.Sync(step()); assert(#spy.added==1 and N.current.manual)
    N.Sync(step(3521)); assert(N.current==nil and #spy.added==1)
end)
test("manual click reselects the existing TomTom arrow",function()
    local spy=setup(); N.Sync(step()); local uid=N.current.uid; spy.active=spy.other
    assert(N.Show(step(),true))
    assert(#spy.added==1 and #spy.selected==1 and spy.active==uid)
end)
test("older TomTom without explicit arrow-selection method recreates on manual click",function()
    local spy=setup(); spy.SetCrazyArrow=nil; N.Sync(step()); N.Show(step(),true)
    assert(#spy.added==2 and #spy.removed==1)
end)
test("an externally removed point is restored only while auto is on",function()
    local spy=setup(); N.Sync(step()); spy.points[N.current.uid]=nil
    N.Sync(step()); assert(#spy.added==2)
    N.SetAutomatic(false); N.Sync(step()); assert(#spy.added==2)
end)
test("missing TomTom leaves the planner usable without automatic native pins",function()
    setup(); TomTom=nil; local native=0
    C_Map.SetUserWaypoint=function() native=native+1 end
    N.Sync(step()); assert(not N.current and native==0 and N.Status():find("not loaded"))
    C_Map.SetUserWaypoint=nil
end)
test("incomplete TomTom API never creates an unremovable point",function()
    local spy=setup(); spy.RemoveWaypoint=nil
    N.Sync(step()); assert(#spy.added==0 and not N.Available())
end)
test("failed cleanup retains the handle and never adds another point",function()
    local spy=setup(); N.Sync(step()); local uid=N.current.uid
    spy.RemoveWaypoint=function() error("temporary cleanup error") end
    N.Sync(step(3521)); assert(N.current.uid==uid and #spy.added==1 and N.error)
end)
test("TomTom creation and arrow-selection errors do not crash capture",function()
    local spy=setup(); spy.AddWaypoint=function() error("temporary add error") end
    assert(not N.Show(step(),true) and N.error and not N.current)
    spy=setup(); N.Sync(step()); spy.SetCrazyArrow=function() error("selection error") end
    assert(not N.Show(step(),true) and N.current and N.error)
end)
test("group waypoint follows the first outstanding member",function()
    local spy=setup(); local s=step(); s.members[2]={id=3521,quest={name="Antidote"},label="Gather ichor"}
    N.Sync(s); assert(spy.added[1].options.title:find("Gather venom") and spy.added[1].options.title:find("nearby"))
    s.id=3521; s.key="3521:task:3"; s.members[1]=s.members[2]; s.members[2]=nil; s.target={x=.58,y=.33}
    N.Sync(s); assert(#spy.added==2 and spy.added[2].options.title:find("Gather ichor"))
end)
test("cave hint belongs to cave work, not the giver pickup or return",function()
    local s=step(917)
    for _,q in ipairs(Q.Pack.quests) do if q.id==917 then s.members[1].quest=q end end
    assert(N.Destination(s).title:find("Cave"))
    s.action="PICK UP"; assert(not N.Destination(s).hint)
    s.action="TURN IN"; assert(not N.Destination(s).hint)
end)
test("invalid coordinate data clears guidance instead of calling TomTom",function()
    local spy=setup(); N.Sync(step()); local s=step(); s.target.x=0/0
    N.Sync(s); assert(N.current==nil and #spy.added==1)
end)
test("automatic navigation refreshes when the tracker is hidden",function()
    local spy=setup(); Q.UI.frame:Hide(); Q.db.hidden=true
    Q.events:GetScript("OnUpdate")(nil,1.1)
    assert(#spy.added==1 and N.current)
end)
test("leaving the supported area clears automatic guidance",function()
    local spy=setup(); Q.Runtime.Refresh(); assert(N.current)
    local old=C_Map.GetBestMapForUnit; C_Map.GetBestMapForUnit=function() return 1 end
    Q.Runtime.Refresh(); assert(not N.current and #spy.removed==1)
    C_Map.GetBestMapForUnit=old
end)
test("loading-world transition clears immediately and cannot recreate until entered",function()
    local spy=setup(); Q.Runtime.Refresh(); assert(N.current)
    Q.events:GetScript("OnEvent")(nil,"PLAYER_LEAVING_WORLD")
    assert(not N.current)
    Q.events:GetScript("OnUpdate")(nil,1.1); assert(not N.current)
    Q.events:GetScript("OnEvent")(nil,"PLAYER_ENTERING_WORLD")
    Q.events:GetScript("OnUpdate")(nil,1.1); assert(N.current)
end)
test("automatic control remains visible in compact mode and responds",function()
    setup(); Q.db.compact=true; Q.UI.Layout(); Q.UI.Render()
    assert(Q.UI.auto.shown and Q.UI.auto.text=="Auto: On" and Q.UI.navStatus.shown)
    Q.UI.auto:GetScript("OnClick")(); assert(not Q.db.autoWaypoint and Q.UI.auto.text=="Auto: Off")
    SlashCmdList.QUESTWEAVER("auto on"); assert(Q.db.autoWaypoint and N.current)
    SlashCmdList.QUESTWEAVER("auto off"); assert(not Q.db.autoWaypoint and not N.current)
end)
test("automatic preference survives reload without resetting other settings",function()
    setup(); Q.db.autoWaypoint=false; Q.db.compact=true; Q.db.locked=true
    QuestWeaverDB=Q.db
    Q.events:GetScript("OnEvent")(nil,"ADDON_LOADED","QuestWeaver")
    assert(not Q.db.autoWaypoint and Q.db.compact and Q.db.locked and Q.db.schema==3)
end)
test("replacing a TomTom instance cleans through its original owner",function()
    local old=setup(); N.Sync(step()); local owned=N.current
    local replacement=setup(); N.current=owned
    N.Sync(step())
    assert(#old.removed==1 and #replacement.removed==0 and #replacement.added==1)
end)
test("manual waypoint retains the existing native fallback when TomTom is absent",function()
    setup(); TomTom=nil; Q.route={step()}
    local placed
    local oldPoint,oldTrack=UiMapPoint,C_SuperTrack
    UiMapPoint={CreateFromCoordinates=function(map,x,y) return {map=map,x=x,y=y} end}
    C_Map.SetUserWaypoint=function(point) placed=point end
    C_SuperTrack={SetSuperTrackedUserWaypoint=function(value) assert(value==true) end}
    Q.Runtime.Waypoint()
    assert(placed and placed.map==Q.Pack.mapID and placed.x==.575)
    C_Map.SetUserWaypoint=nil; UiMapPoint=oldPoint; C_SuperTrack=oldTrack
end)


-- Native fallback regressions exercise optional client boundaries, not rendering.
local function nativeEnvironment(fn)
    local oldTomTom,oldPoint,oldTrack,oldSet=TomTom,UiMapPoint,C_SuperTrack,C_Map.SetUserWaypoint
    local oldRoute,oldPrint,oldCurrent=Q.route,print,N.current
    local oldStatus,oldKey=Q.UI.waypointStatus,Q.UI.waypointStatusKey
    local output={}
    TomTom=nil;N.current=nil;Q.route={step()}
    print=function(text) output[#output+1]=text end
    local ok,err=pcall(fn,output)
    TomTom,UiMapPoint,C_SuperTrack,C_Map.SetUserWaypoint=oldTomTom,oldPoint,oldTrack,oldSet
    Q.route,print,N.current=oldRoute,oldPrint,oldCurrent
    Q.UI.waypointStatus,Q.UI.waypointStatusKey=oldStatus,oldKey
    assert(ok,err)
end

test("native manual fallback catches create set and tracking exceptions",function()
    nativeEnvironment(function(output)
        local auto,pin,route=Q.db.autoWaypoint,Q.db.pin,Q.route
        for _,failure in ipairs({"create","set","track"}) do
            UiMapPoint={CreateFromCoordinates=function()
                if failure=="create" then error("synthetic optional API error") end
                return {x=.575,y=.328}
            end}
            C_Map.SetUserWaypoint=function() if failure=="set" then error("synthetic optional API error") end end
            C_SuperTrack={SetSuperTrackedUserWaypoint=function() error("synthetic optional API error") end}
            Q.Runtime.Waypoint()
            assert(output[#output]:find("57.5, 32.8",1,true))
            assert(not output[#output]:find("synthetic",1,true),"client error details must not enter player chat")
            assert(Q.UI.waypointStatus:find("coordinates printed",1,true))
            assert(Q.db.autoWaypoint==auto and Q.db.pin==pin and Q.route==route and not N.current)
        end
    end)
end)

test("native manual fallback handles absent false and malformed optional APIs",function()
    nativeEnvironment(function(output)
        UiMapPoint=nil;C_Map.SetUserWaypoint=nil;C_SuperTrack=nil
        Q.Runtime.Waypoint();assert(#output==1 and Q.UI.waypointStatus:find("unavailable",1,true))
        UiMapPoint={CreateFromCoordinates=function() return false end};C_Map.SetUserWaypoint=function() error("must not set invalid point") end
        Q.Runtime.Waypoint();assert(#output==2)
        UiMapPoint={CreateFromCoordinates=function() return {} end};C_Map.SetUserWaypoint=function() return false end
        Q.Runtime.Waypoint();assert(#output==3)
        UiMapPoint={CreateFromCoordinates="unsupported"};C_Map.SetUserWaypoint=true
        Q.Runtime.Waypoint();assert(#output==4)
    end)
end)

test("manual waypoint validates the destination before optional client calls",function()
    nativeEnvironment(function(output)
        local called=0
        UiMapPoint={CreateFromCoordinates=function() called=called+1;return {} end}
        C_Map.SetUserWaypoint=function() called=called+1 end
        for _,target in ipairs({{x=0/0,y=.3},{x=math.huge,y=.3},{x=-1,y=.3},{x=.3,y=2}}) do
            Q.route={step()};Q.route[1].target=target;Q.Runtime.Waypoint()
        end
        Q.route={step()};Q.route[1].target=nil;Q.Runtime.Waypoint()
        Q.route={step()};Q.route[1].action="ACCEPT ITEM";Q.Runtime.Waypoint()
        Q.route={};Q.Runtime.Waypoint()
        assert(called==0 and #output==0 and Q.UI.waypointStatus:find("Location unavailable",1,true))
    end)
end)

test("native pin success acknowledges locally and stale acknowledgment clears during loading",function()
    nativeEnvironment(function(output)
        local oldWorld=Q.inWorld
        UiMapPoint={CreateFromCoordinates=function(map,x,y) return {map=map,x=x,y=y} end}
        C_Map.SetUserWaypoint=function() end;C_SuperTrack=nil
        Q.Runtime.Waypoint()
        assert(#output==0 and Q.UI.waypointStatus=="Map pin set.")
        assert(Q.UI.waypointStatusKey==N.Destination(Q.route[1]).key)
        Q.inWorld=false;Q.Runtime.Refresh();Q.inWorld=oldWorld
        assert(Q.UI.waypointStatus==nil and Q.UI.waypointStatusKey==nil)
    end)
end)

N.Clear(); TomTom=nil
