-- Added by Ethorbit so players can't get stuck inside zombies.
timer.Create("nzPlayerStuckCollisionHandler", 0.15, 0, function()
    for _,ply in pairs(nzRound:GetState() == ROUND_CREATE and player.GetAll() or player.GetAllPlayingAndAlive()) do
        if (IsValid(ply)) then
            local groundEnt = ply:GetGroundEntity()
            local on_zombie = IsValid(groundEnt) and groundEnt:IsValidZombie() and !groundEnt.NZBoss
            
            local Maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale()) 
            local Mins = Vector(ply:OBBMins().X / ply:GetModelScale(), ply:OBBMins().Y / ply:GetModelScale(), ply:OBBMins().Z / ply:GetModelScale())
            local Trace = util.TraceHull({    
                start = ply:GetPos(),
                endpos = ply:GetPos(),
                maxs = Maxs, -- Exactly the size the player uses to collide with stuff
                mins = Mins, -- ^
                collisiongroup = COLLISION_GROUP_PLAYER, -- Collides with stuff that players collide with
                filter = function(ent) -- Slow but necessary
                    if (ent:IsNextBot()) then return true end
                end
            })

            if (on_zombie or Trace.Hit) then -- Player is stuck
                if (!ply:Alive() or ply:Health() <= 1 or (!ply:IsInCreative() and !ply:IsPlaying()) or !ply:GetNotDowned() or ply:GetMoveType() == MOVETYPE_NOCLIP) then return end

                for k,v in pairs(ents.FindInBox(ply:GetPos() + Maxs, ply:GetPos() + Mins)) do -- Respawn all zombies stuck in the player
                    if (IsValid(v) and v:Health() > 0 and v:IsValidZombie()) then 
                        -- if (v:GetClass() == "nz_zombie_walker" 
                        -- or v:GetClass() == "nz_zombie_special_dog" 
                        -- or v:GetClass() == "nz_zombie_special_burning") then
                            --v:RespawnZombie()
                            if v.DisableCollision then
                                v:DisableCollision()
                            end
                            --v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
                        --end
                    end
                end
            end
        end
    end
end)

-- Previous implementation below had one major issue: It used the worst hook known to man - ShouldCollide

-- Respawn zombies if they collide inside of us, it could cause us to lose our game!
--local function PlyStuckInZombie(ply)
--    if (IsValid(ply)) then
--        local groundEnt = ply:GetGroundEntity()
--        local on_zombie = IsValid(groundEnt) and groundEnt:IsValidZombie() and !groundEnt.NZBoss
--        
--        local Maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale()) 
--        local Mins = Vector(ply:OBBMins().X / ply:GetModelScale(), ply:OBBMins().Y / ply:GetModelScale(), ply:OBBMins().Z / ply:GetModelScale())
--        local Trace = util.TraceHull({    
--            start = ply:GetPos(),
--            endpos = ply:GetPos(),
--            maxs = Maxs, -- Exactly the size the player uses to collide with stuff
--            mins = Mins, -- ^
--            collisiongroup = COLLISION_GROUP_PLAYER, -- Collides with stuff that players collide with
--            filter = function(ent) -- Slow but necessary
--                if (ent:IsValidZombie()) then return true end
--            end
--        })
--
--        if (on_zombie or Trace.Hit) then -- Player is stuck
--            if (!ply:Alive() or ply:Health() <= 1 or !ply:IsPlaying() or !ply:GetNotDowned() or ply:GetMoveType() == MOVETYPE_NOCLIP) then return end
--
--            for k,v in pairs(ents.FindInBox(ply:GetPos() + Maxs, ply:GetPos() + Mins)) do -- Respawn all zombies stuck in the player
--                if (IsValid(v) and v:Health() > 0 and v:IsValidZombie()) then 
--                    -- if (v:GetClass() == "nz_zombie_walker" 
--                    -- or v:GetClass() == "nz_zombie_special_dog" 
--                    -- or v:GetClass() == "nz_zombie_special_burning") then
--                        --v:RespawnZombie()
--                        v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
--                    --end
--                end
--            end
--        end
--    end
--end
--
--hook.Add("ShouldCollide", "CheckIfPlyStuck", function(ent1, ent2)
--    if ent1:IsPlayer() then PlyStuckInZombie(ent1) end
--end)
