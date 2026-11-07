local _, Q = ...
Q.Navigation={}
local N=Q.Navigation

function N.Available()
    return type(TomTom)=="table" and type(TomTom.AddWaypoint)=="function" and type(TomTom.RemoveWaypoint)=="function"
end

function N.Destination(step)
    if not step or not step.target then return nil end
    local x,y=step.target.x,step.target.y
    if type(x)~="number" or type(y)~="number" or x~=x or y~=y or x<0 or x>1 or y<0 or y>1 then return nil end
    local member=step.members and step.members[1]
    local quest=member and member.quest
    local name=(member and member.label) or (quest and quest.name) or step.name or "Next step"
    local hint=quest and quest.navigationNote
    if quest and quest.navigationActions and not quest.navigationActions[step.action] then hint=nil end
    local title="QuestWeaver - "..(step.action or "GO")..": "..name
    if step.members and #step.members>1 then title=title.." (+"..(#step.members-1).." nearby)" end
    if hint then title=title.." - "..hint end
    title=title:gsub("|","||")
    return {map=Q.Pack.mapID,x=x,y=y,title=title,hint=hint,
        key=string.format("%d:%s:%.6f:%.6f:%s",Q.Pack.mapID,step.key or ((step.action or "")..":"..(step.id or 0)),x,y,title)}
end

function N.Clear()
    local current=N.current
    if not current then N.error=nil; return true end
    -- Keep the original owner/handle until cleanup succeeds. A failed API call
    -- must not cause an orphaned waypoint or removal of somebody else's UID.
    local ok=pcall(current.owner.RemoveWaypoint,current.owner,current.uid)
    if not ok then N.error="TomTom could not clear the previous waypoint"; return false end
    N.current=nil; N.error=nil
    return true
end

function N.Show(step,manual)
    local destination=N.Destination(step)
    if not destination then N.Clear(); return false end
    if not N.Available() then N.Clear(); return false end
    local current=N.current
    if current and current.owner==TomTom and current.key==destination.key then
        local valid=true
        if type(TomTom.IsValidWaypoint)=="function" then
            local ok,result=pcall(TomTom.IsValidWaypoint,TomTom,current.uid)
            if ok and result==false then valid=false end
        end
        if valid and (not manual or type(TomTom.SetCrazyArrow)=="function") then
            -- Do not fight a manually selected arrow on each update. An
            -- explicit Waypoint click may reselect our existing destination.
            if manual and type(TomTom.SetCrazyArrow)=="function" then
                local ok=pcall(TomTom.SetCrazyArrow,TomTom,current.uid,10,destination.title)
                if not ok then N.error="TomTom could not select its arrow"; return false end
            end
            N.error=nil
            return true
        end
    end
    if not N.Clear() then return false end
    local ok,uid=pcall(TomTom.AddWaypoint,TomTom,destination.map,destination.x,destination.y,{
        title=destination.title,from="QuestWeaver",source="QuestWeaver",persistent=false,
        minimap=true,world=true,crazy=true,arrivaldistance=10,cleardistance=0,silent=true,
    })
    if not ok or uid==nil or uid==false then N.error="TomTom could not create the waypoint"; return false end
    N.current={uid=uid,owner=TomTom,key=destination.key,title=destination.title,manual=manual==true}
    N.error=nil
    return true
end

function N.Sync(step)
    local destination=N.Destination(step)
    if not destination then N.Clear(); return end
    if not N.Available() then N.Clear(); return end
    if Q.db and Q.db.autoWaypoint then N.Show(step,false)
    elseif N.current and N.current.key~=destination.key then N.Clear() end
end

function N.SetAutomatic(enabled)
    Q.db.autoWaypoint=enabled==true
    if not Q.db.autoWaypoint then N.Clear() end
end

function N.NeedsUpdates()
    return N.current~=nil or (Q.db and Q.db.autoWaypoint and N.Available())
end

function N.Status()
    if N.error then return N.error end
    if not N.Available() then return "TomTom not loaded - manual waypoint available" end
    if N.current then return Q.db.autoWaypoint and "TomTom next-action destination ready" or "TomTom manual destination" end
    return Q.db.autoWaypoint and "TomTom ready - waiting for a destination" or "TomTom ready - automatic guidance off"
end
