-- Created by Ethorbit, recoded the itemcarry stuff
local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

function ENTITY:IsValidPart()
    return IsValid(self) and self:GetClass() == "nz_workbench_prop"
end

function PLAYER:CanPickupParts() -- Whether or not the player can grab new parts
    if !self:GetNotDowned() then return false end
    if self:IsSpectating() then return false end
    if (IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon():IsSpecial()) then return false end

    return true
end

function PLAYER:GetParts(numbered) -- Get all parts in player inventory
    if numbered then 
        if nzParts.Equipped[self] then 
            return table.GetKeys(nzParts.Equipped[self])
        end
    end

    return nzParts.Equipped[self] or {}
end

function PLAYER:GetPart() -- Get first part player has
    if !nzParts.Equipped[self] then return end
    
    local res
    for _,v in pairs(nzParts.Equipped[self]) do
        if v then
            res = v
            break
        end
    end

    return res
end

function PLAYER:HasParts() -- Check if player has any Parts in their inventory
    return nzParts.Equipped[self] and !table.IsEmpty(nzParts.Equipped[self])
end

function PLAYER:HasPart(part) -- Check if player is holding a specific Part
    return nzParts.Equipped[self] and nzParts.Equipped[self][part]
end

function PLAYER:HasPartsForBench(bench)
    return nzParts.PartsForBenches[self] and nzParts.PartsForBenches[self][bench]
end

function PLAYER:OnPickupPart(part) -- When a player has picked up a part, called by PickupPart
    part:Pickup()   

    if nzMapping.Settings.buildablesshare then
        for _,v in pairs(player.GetAll()) do
            nzParts.Network:Add(v, part)
        end
    else
        nzParts.Network:Add(self, part)
    end  
end

function PLAYER:HasMaxParts()
    return table.Count(self:GetParts()) >= nzMapping.Settings.buildablesmaxamount
end

function PLAYER:PickupPart(part) -- Pick up part
    if !self:CanPickupParts() or self:HasPart(part) then return end

    if (part:IsValidPart()) then
        if (nzMapping.Settings.buildablesmaxamount <= 1 and !nzMapping.Settings.buildablesshare and self:HasParts()) then
            self:SwapPart(part)
        return end

        if !self:HasMaxParts() then
            self:OnPickupPart(part)
        end
    end
end

function PLAYER:SwapPart(new) -- Swap their currently held Part with this one
    local current = self:GetPart()

    if (new:IsValidPart()) then
        if nzMapping.Settings.buildablesdrop then
            current:Reset(self:GetPos())
        else
            current:Reset()
        end
       
        nzParts.Network:Remove(self, current)
        self:OnPickupPart(new)
    end
end

function PLAYER:DropParts(parts, respawn) -- Drop parts from inventory
    if (!self:HasParts()) then return end
    
    for _,part in pairs(parts) do     
        if (IsValid(part) and part:IsValidPart()) then
            --if part.GetBuilt and part:GetBuilt() then 
                if (!nzMapping.Settings.buildablesshare or !nzParts:IsHeld(part, self)) then -- If sharing is off or sharing is on and nobody has this part
                    if (!respawn and nzMapping.Settings.buildablesdrop) then -- and Part:IsDisabled() would make it only set the posiiton to the player if it didn't respawn at its default position yet
                        part:Reset(self:GetPos())
                        part:StartRespawnTimer(300) -- Just in case this place is unreachable
                    else
                        part:Reset()
                    end

                    nzParts.Network:Remove(self, part)
                end
            --end 
        end
    end 
end

function PLAYER:StripParts(parts) 
    if nzMapping.Settings.buildablesshare then
        for _,v in pairs(player.GetAll()) do
            nzParts.Network:RemoveParts(v, parts)
        end
    else
        nzParts.Network:RemoveParts(self, parts)
    end
end

-- -- In itemcarry these were thrown in its meta file, I only did the same out of uncertainty. Technically this should go in
-- -- another file to make it easier to find as it can be used in other parts of the gamemode if desired.
--function PLAYER:StartTimedUse(ent)
--    if IsValid(self.TimedUseEntity) then self:StopTimedUse() end
--    
--    local time = ent:StartTimedUse(self, self, USE_OFF, 0)
--    if time then
--        self.TimedUseEntity = ent
--        self.TimedUseComplete = CurTime() + time
--        
--        net.Start("nzTimedUse")
--            net.WriteBool(true)
--            net.WriteFloat(time)
--        net.Send(self)
--    end
--end
--
--function PLAYER:StopTimedUse()
--    local ent = self.TimedUseEntity
--    if !IsValid(ent) then return end
--    
--    ent:StopTimedUse(self, self, USE_OFF, 0)
--    self.TimedUseEntity = nil
--    self.TimedUseEntity = nil
--    
--    net.Start("nzTimedUse")
--        net.WriteBool(false)
--    net.Send(self)
--end
--
--function PLAYER:FinishTimedUse()
--    local ent = self.TimedUseEntity
--    if !IsValid(ent) then return end
--    
--    ent:FinishTimedUse(self, self, USE_ON, 0) -- Imitate ENTITY:Use arguments
--    self.TimedUseEntity = nil
--    self.TimedUseComplete = nil
--    
--    net.Start("nzTimedUse")
--        net.WriteBool(false)
--    net.Send(self)
--end
