local PLAYER = FindMetaTable("Player")
util.AddNetworkString("AntiCheatWarning")
util.AddNetworkString("AntiCheatWarningCancel")

NZ_AntiCheat_Delay = GetConVar("nz_anticheat_delay"):GetInt()
if (cvars.GetConVarCallbacks(cvarName) and #cvars.GetConVarCallbacks(cvarName) == 0) then
    cvars.AddChangeCallback("nz_anticheat_delay", function()
        NZ_AntiCheat_Delay = GetConVar("nz_anticheat_delay"):GetInt()
    end)
end

-- Add entities players can cheat on:
local excludedClasses = { 
    "func_tracktrain",
    "func_tanktrain",
    "func_trackchange",
    "func_movelinear",
    "func_brush",
    "func_door"
} 

-- Handle TP time continuously so players cannot reset it by simply leaving the spot:
function PLAYER:GetTPSecs()
    if self.tptimer == nil then self:ResetTPSecs() end
    return self.tptimer + 1
end

function PLAYER:StartTPDecrease()
    if (!IsValid(self)) then return end
    if (timer.Exists("ACDecrease" .. self:SteamID())) then return end -- We're already counting down..
    timer.Destroy("ACDecrease" .. self:SteamID())
    timer.Create("ACDecrease" .. self:SteamID(), 1, 0, function()
        if (!IsValid(self)) then return end
        self.tptimer = self.tptimer - 1 > 0 and self.tptimer - 1 or 0
        if (self.tptimer < 0) then
            self:ResetTPSecs()
        end
    end)
end

function PLAYER:StopTPDecrease()
    if (!IsValid(self)) then return end
    timer.Destroy("ACDecrease" .. self:SteamID())
    self:ResetTPSecs()
end

function PLAYER:ResetTPSecs()
    self.tptimer = nzMapping.Settings.actptime and nzMapping.Settings.actptime or 5
end
-------------------------------------------------------------------------------------------
function PLAYER:NearUndetectedSpot() -- Undetected spots are spots the Anti-Cheat is unaware of that the AC Zombies mark as unreachable
    if (!isvector(self.undetectedSpot)) then return false end
    return (self:GetPos():DistToSqr(self.undetectedSpot) <= 12000) 
end

function PLAYER:ACSavePoint() -- Save the last position they were not cheating at for Anti-Cheat teleports
    if (!nzMapping.Settings.ac and nzMapping.Settings.ac != nil || !nzMapping.Settings.acsavespot) then return end
    if (self:NearUndetectedSpot()) then return end

    if (self.allowsavespot == nil) then 
        self.allowsavespot = true 
    end

    if self.saveDelay == nil then 
        self.saveDelay = CurTime() + (NZ_AntiCheat_Delay + 0.5) -- Optimization, don't need to save positions every tick
    end

    if (self.allowsavespot and self.saveDelay == nil or CurTime() > self.saveDelay and self.allowsavespot) then
        local navarea = navmesh.GetNavArea(self:GetPos(), 75)   
        if (!navarea || !IsValid(navarea)) then return end
        if (navarea:GetSizeX() >= 113 && navarea:GetSizeY() >= 113) then -- Player is on a big nav mesh
            if (#navmesh.Find(self:GetPos(), 250, 1, 1) >= 6) then -- Plenty of meshes near them
                self.noncheatspot = self:GetPos()
                self.oldangles = self:EyeAngles()
            end
        end
    end
end

function PLAYER:WarnToMove(force) -- Give the player a chance to move before being teleported to spawn
    if (!nzMapping.Settings.ac and nzMapping.Settings.ac != nil) then return end
    if ((force or self:CanBeCheater()) and (self.allowtp || self:GetTPSecs() <= 1)) then -- They had their chance to get back in the map
        self:NZMoveCheater() 
        self.undetectedSpot = nil
    return end 

    if self.warning then return end -- They still have time to move
    hook.Call("NZAntiCheatWarningPlayer", nil, self:GetPos(), self)
    self.warning = true
    
    net.Start("AntiCheatWarningCancel")
    net.Send(self)
    net.Start("AntiCheatWarning")
    net.WriteInt(self:GetTPSecs(), 13)
    net.Send(self)
    
    self:StartTPDecrease()

    -- Make sure the player's warning goes away if they aren't cheating
    timer.Create("ACWarning" .. self:SteamID(), 0.1, 0, function()
        if !IsValid(self) then return end

        if (!self.acdelayedjump and !self:NearUndetectedSpot() and !self:NZPlayerUnreachable()) then
            net.Start("AntiCheatWarningCancel")
            net.Send(self)
            timer.Destroy("ACWarning" .. self:SteamID())
            self.warning = false
        end
    end)

    timer.Create("ACTPTime" .. self:SteamID(), self:GetTPSecs(), 1, function()
        if !IsValid(self) || !self:Alive() || !self:GetNotDowned() then return end
        self:StopTPDecrease() -- Their countdown finished, reset it
       
        if self:NZPlayerUnreachable() then -- They are still cheating, teleport them
            net.Start("AntiCheatWarningCancel")
            net.Send(self)
            self:NZMoveCheater() -- We've given them a chance to move
        end

        self.allowtp = true
        self.warning = false
        self.allowsavespot = false
        self.undetectedSpot = nil

        timer.Destroy("ACWarning" .. self:SteamID())

        timer.Simple(15, function()
            if (IsValid(self)) then
                self.allowtp = false
                self.allowsavespot = true
            end
        end)
    end)

    local warnedPos = self:GetPos() -- Where they were when they were warned
    print("[NZ Anti-Cheat] Warning " .. self:Nick() .. " to move..")
end

function PLAYER:InAC(class) -- Can used to check if a player is inside an entity that derives from invis_wall
    local isinside = false
    for k,v in pairs(ents.FindByClass(class)) do
        if (isinside) then break end
        
        for a,b in pairs(ents.FindInBox(v:GetPos(), v:GetPos() + v:GetMaxBound())) do
            if (b == self) then
                isinside = true
                break
            end
        end
    end

    return isinside
end

function PLAYER:InACExclusionArea()
    return self:InAC("anticheat_exclude")
end

function PLAYER:InACArea()
    return self:InAC("anticheat_wall")
end

function PLAYER:CanBeCheater(notstrict)
    if self:IsSpectating() then return false end -- They are not in-game or in Creative Mode
    if !notstrict and self:InVehicle() then return false end -- They are inside a vehicle
    if self:GetNWBool("in_afterlife") then return false end -- They are in Afterlife Mode
    if self:Health() < 100 or !self:GetNotDowned() or !self:Alive() then return false end -- They are hurt, down or dead
    if self:GetMoveType() == MOVETYPE_NOCLIP or !notstrict and (self:GetMoveType() != MOVETYPE_WALK or !self:IsOnGround()) then return false end -- They cannot walk right now
    if self:InACExclusionArea() then return false end -- They are inside an Anti-Cheat Exclusion Area
    return true
end

function PLAYER:GetClosestNavMesh()
    return navmesh.GetNearestNavArea(self:GetPos(), false, 75, false, true)
end

function PLAYER:NZPlayerUnreachable()
    if self:GetMoveType() == MOVETYPE_LADDER then return true end
    --if !self:CanBeCheater() then return false end

    local startPos = self:GetPos() - Vector(0, 0, 0)
    local endPos = self:GetPos() - Vector(0, 0, 16384)
    local Maxs = Vector(self:OBBMaxs().X / self:GetModelScale(), self:OBBMaxs().Y / self:GetModelScale(), self:OBBMaxs().Z / self:GetModelScale()) 
    local Mins = Vector(self:OBBMins().X / self:GetModelScale(), self:OBBMins().Y / self:GetModelScale(), self:OBBMins().Z / self:GetModelScale())
    
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        maxs = Maxs,
        mins = Mins,
        collisiongroup = COLLISION_GROUP_PLAYER,
        filter = function(ent) return !ent:IsPlayer() end
    })

    if tr.Hit and !table.HasValue(excludedClasses, tr.Entity:GetClass()) then -- If it hit something that can't move
        if !IsValid(tr.Entity:GetParent()) then -- Parented entities typically have the ability to move, don't tp people on them
            local hitPos = tr.HitPos
            local navnear = self:GetClosestNavMesh()
            if !IsValid(navnear) then return true end -- No nav mesh close enough
            if IsValid(navnear) and nzNav.Locks and nzNav.Locks[navnear:GetID()] and !nzDoors:IsLinkOpened(nzNav.Locks[navnear:GetID()].link) then return true end
        end
    end

    self:ACSavePoint() -- They are not cheating, try to save their location as an Anti-Cheat teleport point
    return false
end

function PLAYER:NZNotifyCheat(msg) -- Sends a message to victims of the NZ Anti-Cheat
    if !self.NZACNotified and !self.warning then
        self.NZACNotified = true

        self:ChatPrint(msg)
        timer.Simple(5, function() 
            if (IsValid(self)) then
                self.NZACNotified = false 
            end
        end)
    end
end

function PLAYER:NZMoveCheater() -- Teleports them out of the cheat spot
    if !nzMapping.Settings.ac and nzMapping.Settings.ac != nil then return end

    if !self.LastTPTime or isnumber(self.LastTPTime) and CurTime() > self.LastTPTime then
        self.LastTPTime = CurTime() + 0.1

        local navmeshDist = nil
        local navPos = nil
        local oldPos = self:GetPos()
    
        timer.Simple(0.1, function()
            if (!IsValid(self)) then return end
            if (self.noncheatspot != nil and self.lastTPspot == nil or self.noncheatspot != nil and self.lastTPspot != nil and self.noncheatspot:Distance(self.lastTPspot) > 150) then -- Make sure they aren't being teleported where they last teleported at     
                self:SetPos(self.noncheatspot) -- Tp to their last non-cheat spot
                self.lastTPspot = self.noncheatspot

                if (self.oldangles != nil) then self:SetEyeAngles(self.oldangles) end
            else -- No last spot saved one of these teleports:
                if !IsValid(self) then return end

                if (#player.GetAllPlayingAndAlive() > 1) then -- To the other player
                    for k,v in pairs(player.GetAllPlayingAndAlive()) do
                        if v != self then 
                            self:SetPos(v:GetPos())
                        end
                    end
                else
                    -- To spawn:
                    local class = "player_spawns"
                    if (#ents.FindByClass("player_spawns") == 0) then class = "info_player_start" end
                    
                    local destent = ents.FindByClass(class)[1]
                    if (IsValid(destent)) then
                        self:SetPos(destent:GetPos())
                    else
                        return -- Don't give them Zombie's Blood if they can't be teleported
                    end              
                end

                -- Prevent zombies from immediately targetting, so they don't instantly die on AC teleport:
                if (self.aczblood == nil or self.aczblood) then 
                    self.aczblood = false -- Don't allow again for a bit
                    nzPowerUps:Activate("zombieblood", self)
                    
                    timer.Create("ACZombieBloodCD" .. self:SteamID(), 1500, 1, function()
                        if IsValid(self) then self.aczblood = true end
                    end)
                else -- No available zombie blood for them, just make them untargetable for 5 seconds
                    if (self:GetTargetPriority() == TARGET_PRIORITY_NONE) then return end

                    if (self:Team() == TEAM_PLAYERS) then
                        self:SetTargetPriority(TARGET_PRIORITY_NONE)
                        timer.Simple(3, function()
                            if !IsValid(self) or self:Team() != TEAM_PLAYERS then return end
                            self:SetTargetPriority(TARGET_PRIORITY_PLAYER)
                        end)
                    end
                end
            end

            self.allowsavespot = true
        end)

        ServerLog("[NZ Anti-Cheat] " .. self:Nick() .. " was caught cheating!\n")
        PrintMessage(HUD_PRINTTALK, "[NZ] " .. self:Nick() .. " was teleported by the Anti-Cheat.")
        hook.Call("NZAntiCheatMovedPlayer", nil, oldPos, self)
    end
end

function PLAYER:OnCheating()
    if (nzMapping.Settings.ac) then
        self.allowsavespot = false -- Prevents possibly adding a save point outside the map for cheaters (just until the warning time resets)
        self:WarnToMove() 
    end
end

local jumpDelay
AccessorFunc(PLAYER, "bIsJumping", "IsJumping", FORCE_BOOL)
hook.Add("Tick", "NZAntiCheat", function() -- Scan for players who are cheating
    if !nzMapping.Settings.ac then return end
    
    if (waittime == nil or CurTime() > waittime) then 
        if (NZ_AntiCheat_Delay != nil) then 
            if NZ_AntiCheat_Delay <= 5.0 then
                waittime = CurTime() + NZ_AntiCheat_Delay
            else
                waittime = CurTime() + 5.0
            end
        else
            waittime = CurTime()
        end

        for _,ply in pairs(player.GetAll()) do
            if ply:CanBeCheater() then
                if ply:NZPlayerUnreachable() then 
                    ply:OnCheating()
                end
            end

            if ply:CanBeCheater(true) then
                if ply:InACArea() then 
                    ply:NZMoveCheater()
                end
            end
           
            if (nzMapping.Settings.ac and nzMapping.Settings.acpreventboost and !ply:IsInCreative()) then -- Stop boosting fast upwards
                -- Prevent boosting in the air
                if (ply:GetVelocity()[3] >= ply:GetJumpPower()) then
                    timer.Simple(0, function()
                        if (IsValid(ply)) then
                            ply:SetVelocity(Vector(0, 0, -math.abs(ply:GetVelocity()[3])))
                        end
                    end) 
                end

                -- Prevent boosting on slopes
                -- if (ply:GetIsJumping() and ply.acBeginJumpTime < CurTime() - 1.4) then -- They've been jumping longer than usual, probably sliding off a ledge     
                --     ply:SetGravity(ply:GetGravity() + 0.2)
                -- else
                --     if (!ply:IsOnGround() and ply:GetSequence() != 125 and math.abs(ply:GetVelocity()[1]) <= 10 and math.abs(ply:GetVelocity()[2]) <= 10 and math.abs(ply:GetVelocity()[3]) > 10) then
                --         ply:SetGravity(ply:GetGravity() + 0.2)
                --     else
                --         ply:SetGravity(1)
                --     end
                -- end
            end

            -- if (ply:GetGravity() >= 10) then
            --     if (!ply.warning) then
            --         ply.warning = false
            --         ply:WarnToMove(true)
            --     end
            -- end

            -- Detect jumps
            -- if (ply:GetSequence() == 125) then -- They're jumping 
            --     if (!ply.acBeginJumpTime or ply.acBeginJumpTime <= 0) then
            --         ply.acBeginJumpTime = CurTime()
            --         ply:SetIsJumping(true)
            --         ply.acdelayedjump = true
            --     end
            -- else
            --     if (!jumpDelay) then jumpDelay = CurTime() + 0.6 end
            --     ply:SetIsJumping(false)
            --     ply:SetGravity(1)
            --     ply.acBeginJumpTime = 0

            --     if (CurTime() > jumpDelay) then
            --         jumpDelay = CurTime() + 0.6
            --         ply.acdelayedjump = false
            --     end
            -- end
        end
    end
end)

hook.Add("PlayerDeath", "RemoveDeadPlayersStuckSpot", function(ply)
    if IsValid(ply) then 
        ply.noncheatspot = nil 
    end 
end)

hook.Add("OnPlayerDropOut", "RemoveDroppedOutPlayersStuckSpot", function(ply)
    if IsValid(ply) then 
        ply.noncheatspot = nil
    end 
end)

hook.Add("PlayerSpawn", "NZAntiCheatCancelTimer", function(ply)
    ply:StopTPDecrease()
end)
