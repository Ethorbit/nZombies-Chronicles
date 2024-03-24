AddCSLuaFile()

ENT.Type = "anim"
ENT.Base 			= "base_anim"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable 		= false
ENT.AdminSpawnable 	= false



--stats
ENT.PrintName		= "Rock"
ENT.Category 		= ""

ENT.Model = ("models/props_debris/concrete_chunk01a.mdl")
ENT.Damage = 25
ENT.SmashSound = "tank/hit/thrown_projectile_hit_01.wav"

if SERVER then
	function ENT:Initialize()
	 
		self:SetModel(self.Model)
		self:SetHealth(999999)
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
			local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableMotion( true )
		end
		
		timer.Simple(2, function() 
			if ( self:IsValid() ) then 
			SafeRemoveEntity( self )
			end
		end)
		
	end
end

function ENT:Think()
end

ENT.nxtHitSound = 0
function ENT:HitSound()

	if !self.nxtHitSound then self.nxtHitSound = 0 end
    if CurTime() < self.nxtHitSound then return end

    self.nxtHitSound = CurTime() + 1

	self:EmitSound(self.SmashSound)
end

function ENT:PhysicsCollide(data, physobj)
	if  ( self:IsValid() ) then
		if SERVER then
		self:HitSound()
		end
	end
end


if CLIENT then

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:Launch(dir)
	self:SetLocalVelocity(dir * 1450)
	self:SetAngles(((dir)):Angle())
	self.AutoReturnTime = CurTime() + 5
end

function ENT:Return() -- Emptyhanded return - Grab is with player
	self.HasGrabbed = true

	local panzer = self:GetPanzer()
	if !IsValid(panzer) then self:Remove() return end

	self:SetMoveType(MOVETYPE_FLY)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetNotSolid(true)
	self:SetCollisionBounds(Vector(0,0,0), Vector(0,0,0))
	
	local att = panzer:LookupAttachment("clawlight")
	local pos = att and panzer:GetAttachment(att).Pos or panzer:GetPos()
	self:SetLocalVelocity((pos - self:GetPos()):GetNormalized() * 1500)
end

function ENT:Release()
	if IsValid(self.GrabbedPlayer) then
		hook.Remove("SetupMove", "PanzerGrab"..self:EntIndex())
		
		if SERVER then
			net.Start("nz_panzer_grab")
				net.WriteBool(false)
				net.WriteEntity(self)
			net.Send(self.GrabbedPlayer)
			
			self:Return()
		end
	else
		if SERVER then
			net.Start("nz_panzer_grab")
				net.WriteBool(false)
				net.WriteEntity(self)
			net.Broadcast()
		end
	end
	self.GrabbedPlayer = nil
end