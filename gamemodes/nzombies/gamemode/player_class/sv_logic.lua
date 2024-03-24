local nothing = {
    "invis_wall",
    "invis_wall_zombie",
    "wall_block",
    "wall_block_zombie"
}

-- Controls purchasing entities that are visible, think of it as secondary :Use() functionality, but more flexible
-- and allows buying through invisible walls, wall_blocks, etc
hook.Add("KeyPress", "PlayerUsedSomething", function(ply, key)
    if (ply:GetNotDowned() and key == IN_USE) then
        local ent = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 90,
            filter = function(ent)
                if (ent != ply) then
                    if (IsValid(ent) and !nothing[ent:GetClass()] and ent:GetClass() == "easter_egg" or isfunction(ent.GetPrice) and ent:GetClass() != "power_box") then
                        if (!isnumber(ply.lastInvisUseTime) or isnumber(ply.lastInvisUseTime) and CurTime() > ply.lastInvisUseTime) then
                            ply.lastInvisUseTime = CurTime() + 0.3
                            
                            if ply:CanUse() then
                                ent:Use(ply, ply, USE_ON)
                            end
                        end
                    end
                end
            end,
            mask = MASK_SOLID || MASK_VISIBLE_AND_NPCS
        }).Entity
    end
end)

-- Block (NORMAL) use
hook.Add("PlayerUse", "NZNoUseWithSpecialWeps", function(ply, ent)
    return ply:CanUse()
end)