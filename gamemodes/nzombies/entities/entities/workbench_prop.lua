-- A prop built onto a Bench
AddCSLuaFile()

ENT.Type = "anim"
ENT.Author = "Ethorbit"
ENT.NZEntity = true

function ENT:Initialize()
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
   
    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:SetBenchInteraction(bool) -- Use Bench and see Bench text via this entity, not recommended with big props
    if bool then
        self.StartTimedUse = function(ply) 
            if IsValid(self:GetOwner()) then
                self:GetOwner():StartTimedUse(ply)
            end
        end
        
        self.StopTimedUse = function(ply) 
            if IsValid(self:GetOwner()) then
                self:GetOwner():StopTimedUse(ply)
            end
        end
        
        self.FinishTimedUse = function(ply) 
            if IsValid(self:GetOwner()) then
                self:GetOwner():FinishTimedUse(ply)
            end
        end

        -- COOL CONCEPT BUT AS WE KNOW GMOD IS SHIT so this won't work, 
        -- nZombies uses a line trace for text that will NEVER hit this entity without causing other issues
        -- self.GetNZTargetText = function() -- Show Bench's text instead
        --     if IsValid(self:GetOwner()) then
        --         return self:GetOwner():GetNZTargetText()
        --     end
        -- end
    else
        self.StartTimedUse = nil
        self.StopTimedUse = nil
        self.FinishTimedUse = nil
        self.GetNZTargetText = nil
    end
end
