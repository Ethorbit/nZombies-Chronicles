-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

ENT.Base = "nz_hl2_zombiebase"
ENT.PrintName = "PB Headcrab Base"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"
ENT.Spawnable = false

AccessorFunc( ENT, "bDetachedFromZombie", "DetachedFromZombie", FORCE_BOOL)

ENT.HeadcrabSpeed = 150
ENT.DamageLow = 5
ENT.DamageHigh = 5

DEFINE_BASECLASS(ENT.Base)

ENT.AttackHitSounds = {
	"NPC_HeadCrab.Bite"
}

function ENT:Jump() -- Zombies leap with loco.JumpAcrossGap, this function ruins the headcrab jump immersion
end

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)

	self:SetLeapAtPlayers(true)
    self:SetMaxLeapRange(250.0)
	self:SetMinLeapRange(0.0)
	self:SetLeapDamageRadius(90.0)

	self:SetLeapPower(2)

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
end

function ENT:OnLeapHurtPlayer(player)
end

function ENT:OnTakeDamage(dmginfo)
	BaseClass.OnTakeDamage(self, dmginfo)

	if (dmginfo:GetIsMeleeDamage()) then -- Melee ALWAYS 1-hits headcrabs
		self:Kill(dmginfo)
	end
end

function ENT:OnSpawn()
	BaseClass.OnSpawn(self)

	self:SetRunSpeed(self.HeadcrabSpeed)
	self.loco:SetDesiredSpeed(self.HeadcrabSpeed)
end

function ENT:BodyUpdate()
	self.CalcIdeal = ACT_IDLE

	local velocity = self:GetVelocity()
	local len2d = velocity:Length2D()

	if len2d <= 0 then self.CalcIdeal = ACT_IDLE
	elseif len2d > 0 then self.CalcIdeal = ACT_RUN
	elseif len2d > 5 then self.CalcIdeal = ACT_IDLE end

	if self:IsJumping() and self:WaterLevel() <= 0 then
		self.CalcIdeal = ACT_JUMP
	end

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	end

	if self:GetLeaping() then  
		self.CalcIdeal = "ACT_RANGE_ATTACK1"
	end

	-- if self:GetEmerging() then
	-- 	self.CalcIdeal = ACT_IDLE
	-- end

	if !self:GetSpecialAnimation() and !self:IsAttacking() then
		if self:GetActivity() != self.CalcIdeal and !self:GetStop() then self:StartActivitySeq(self.CalcIdeal) end

		if self.ActStages[self:GetActStage()] and !self.FrozenTime then
			self:BodyMoveXY()
		end
	end

	if self.FrozenTime then
		if self.FrozenTime < CurTime() then
			self.FrozenTime = nil
			self:SetStop(false)
		end
		self:BodyMoveXY()
		--self:FrameAdvance()
	else
		self:FrameAdvance()
	end
end

function ENT:TryDecapitation(dmgInfo) -- Headcrabs ARE the heads lol..
end