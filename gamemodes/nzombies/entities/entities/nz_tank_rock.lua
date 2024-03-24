game.AddParticles( "particles/tank_fx.pcf" )
PrecacheParticleSystem("tank_rock_throw_impact")
-- These don't seem to show..
--PrecacheParticleSystem("tank_rock_throw_impact_stump")
--PrecacheParticleSystem("tank_rock_throw_impact_chunks")
--PrecacheParticleSystem("tank_rock_throw_impact_chunks_stump")

ENT.Author 			= "Berb, Ethorbit"
ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "Rocket_RPG7"
ENT.Category		= "None"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false


ENT.MyModel = "models/props_debris/concrete_chunk01a.mdl"
ENT.MyModelScale = 1
ENT.Damage_NoJugg = 80
ENT.Damage_Jugg = 190
ENT.Radius = 120 -- The damage radius

if SERVER then

	AddCSLuaFile()

	function ENT:Initialize()
		self.NextAllowedDamage = {}
		self.Class = self:GetClass()

		self:SetModel(self.MyModel)
		ParticleEffectAttach("rocket_smoke",PATTACH_ABSORIGIN_FOLLOW,self,0)
		--ParticleEffectAttach("bo3_zombie_spawn",PATTACH_ABSORIGIN_FOLLOW,self,0)
		self:PhysicsInit(SOLID_OBB)
		self:SetSolid(SOLID_NONE)
		self:SetTrigger(true)
		self:SetAngles( Angle( 180,180,180 ))
		self:UseTriggerBounds(true, 0)
		self:SetMoveType(MOVETYPE_FLY)
		--self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		--self:SetSolid(SOLID_VPHYSICS)
		phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:Wake()
		end
		self:SetModelScale(self.MyModelScale,0)

		local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:Wake()
		end
	end
function ENT:Launch(dir, speed)
	self:SetLocalVelocity(dir * speed)
	self:SetAngles(((dir)):Angle())
	self.AutoReturnTime = CurTime() + 5
	SafeRemoveEntityDelayed(self, 2.1)
end

function ENT:OnContact(ent)
	local panzer = self:GetParent()
	if ent:IsPlayer() or ent:IsWorld() then
		self:EmitSound("ambient/explosions/explode_1.wav")
		local ent = ents.Create("env_explosion")
		ent:SetPos(self:GetPos())
		ent:SetAngles(self:GetAngles())
		ent:Spawn()
		ent:SetKeyValue("imagnitude", "75")
		ent:Fire("explode")
		self.ExplosionLight1 = ents.Create("light_dynamic")
		self.ExplosionLight1:SetKeyValue("brightness", "4")
		self.ExplosionLight1:SetKeyValue("distance", "1000")
		self.ExplosionLight1:SetLocalPos(self:GetPos())
		self.ExplosionLight1:SetLocalAngles(self:GetAngles())
		self.ExplosionLight1:Fire("Color", "255 150 0")
		self.ExplosionLight1:SetParent(self)
		self.ExplosionLight1:Spawn()
		self.ExplosionLight1:Activate()
		self.ExplosionLight1:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(self.ExplosionLight1)
		SafeRemoveEntityDelayed(self,0.1)
		end
	end

end

function ENT:StartTouch(ent)
	local panzer = self:GetParent()
	if ent:IsPlayer() or ent:IsWorld() then
		for _,ent in pairs(ents.FindInSphere(self:GetPos(), self.Radius)) do
			 if IsValid(ent) and ent:IsPlayer() and ent:GetNotDowned() and self.NextAllowedDamage and (!self.NextAllowedDamage[ent] or CurTime() > self.NextAllowedDamage[ent]) then
				 self.NextAllowedDamage[ent] = CurTime() + 4 -- Don't stack damage :|
				 local dmg = DamageInfo()
				 dmg:SetAttacker(self)
				 dmg:SetInflictor(self)
				 dmg:SetDamagePosition(self:GetPos())
				 dmg:SetDamageType(DMG_CRUSH)
				 dmg:SetDamage(ent:HasPerk("jugg") and self.Damage_Jugg or self.Damage_NoJugg)
				 ent:TakeDamageInfo(dmg)
			 end
		end

	   self:EmitSound("tank/hit/thrown_projectile_hit_01.wav")
	   --ParticleEffect("bo3_panzer_landing",self:LocalToWorld(Vector(40,-20,0)),Angle(0,0,0),nil)
	   ParticleEffect("tank_rock_throw_impact", self:GetPos(), Angle(0,0,0), nil)
	   util.ScreenShake(self:GetPos(), 20, 40, 1.2, 2000)
	   SafeRemoveEntityDelayed(self, 0.1)
	end
end

if CLIENT then

	function ENT:Draw()
		self:DrawModel()
	end

end

function ENT:Return() -- Emptyhanded return - Grab is with player
	self.HasGrabbed = true

	local panzer = self:GetPanzer()
	if !IsValid(panzer) then self:Remove() return end

	self:SetMoveType(MOVETYPE_FLYGRAVITY)
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
