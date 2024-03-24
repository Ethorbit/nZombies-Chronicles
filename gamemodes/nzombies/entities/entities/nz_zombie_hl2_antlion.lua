-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

nzConfig.AddValidEnemy("nz_zombie_hl2_antlion", {
    Valid = true,
    SpecialSpawn = true,
    ScaleDMG = function(zombie, hitgroup, dmginfo)
        --if hitgroup == HITGROUP_HEAD then dmginfo:ScaleDamage(2) end
    end,
    OnHit = function(zombie, dmginfo, hitgroup)
        local attacker = dmginfo:GetAttacker()
        if attacker:IsPlayer() and attacker:GetNotDowned() then
            attacker:GivePoints(10)
        end
    end,
    OnKilled = function(zombie, dmginfo, hitgroup)
        local attacker = dmginfo:GetAttacker()
        if attacker:IsPlayer() and attacker:GetNotDowned() then
            if dmginfo:GetDamageType() == DMG_CLUB then
                attacker:GivePoints(130)
            elseif hitgroup == HITGROUP_HEAD then
                attacker:GivePoints(100)
            else
                attacker:GivePoints(50)
            end
        end
    end
})

ENT.Base = "nz_hl2_zombiebase"
ENT.PrintName = "PB Antlion"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

ENT.DamageLow = 25
ENT.DamageHigh = 25
ENT.AttackRange = 90 

ENT.AttackDelay = 1

ENT.BlockHardcodedSwingSound = true

ENT.AntlionSounds = {
	["Wings"] = "NPC_Antlion.WingsOpen",
	["Dig"] = "NPC_Antlion.BurrowOut",
	["Footstep"] = "NPC_Antlion.Footstep",
	["Distracted"] = "NPC_Antlion.Distracted",
	["Land"] = "NPC_Antlion.Land"
}

ENT.Models = {
	"models/antlion.mdl",
}

local AttackSequences = {
	{seq = "attack1", attacksounds = {"NPC_Antlion.MeleeAttackSingle"}, dmgtimes = {0.5}, dmg = 40},
	{seq = "attack2", attacksounds = {"NPC_Antlion.MeleeAttackDouble"}, dmgtimes = {0.5}, dmg = 80},
	{seq = "attack3", attacksounds = {"NPC_Antlion.MeleeAttackSingle"}, dmgtimes = {0.5}, dmg = 40},
	{seq = "attack4", attacksounds = {"NPC_Antlion.MeleeAttackSingle"}, dmgtimes = {0.5}, dmg = 40},
	{seq = "attack5", attacksounds = {"NPC_Antlion.MeleeAttackSingle"}, dmgtimes = {0.5}, dmg = 40},
	{seq = "attack6", attacksounds = {"NPC_Antlion.MeleeAttackDouble"}, dmgtimes = {0.5}, dmg = 80},
	{seq = "pounce", attacksounds = {"NPC_Antlion.MeleeAttackDouble"}, dmgtimes = {0.5}, dmg = 80},
	{seq = "pounce2", attacksounds = {"NPC_Antlion.MeleeAttackSingle"}, dmgtimes = {0.5}, dmg = 40},
}

ENT.HitSounds = {
	"NPC_Antlion.MeleeAttack"
}

local JumpSequences = {
	{seq = "jump_start", speed = 15, time = 2.7},
}

ENT.ActStages = {
	[1] = {
		act = ACT_WALK,
		minspeed = 5,
		attackanims = AttackSequences,
		-- no attackhitsounds, just use ENT.AttackHitSounds for all act stages
		sounds = {},
		barricadejumps = JumpSequences,
	},
	[2] = {
		act = ACT_RUN,
		minspeed = 75,
		attackanims = AttackSequences,
		sounds = {},
		barricadejumps = JumpSequences,
	}
}

ENT.RedEyes = false -- We have no eyes, we have a headcrab lol

ENT.ElectrocutionSequences = {
	"drown",
}

ENT.EmergeSequences = {
	"digout",
}

ENT.AttackHitSounds = {
	"nzr/zombies/attack/player_hit_0.wav",
	"nzr/zombies/attack/player_hit_1.wav",
	"nzr/zombies/attack/player_hit_2.wav",
	"nzr/zombies/attack/player_hit_3.wav",
	"nzr/zombies/attack/player_hit_4.wav",
	"nzr/zombies/attack/player_hit_5.wav"
}

ENT.PainSounds = {
	"NPC_Antlion.Pain"
}

ENT.DeathSounds = {
	"NPC_FastZombie.Die"
}

DEFINE_BASECLASS(ENT.Base)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")

    BaseClass.SetupDataTables(self)
end

function ENT:OnNewTarget(target)
	if IsValid(target) and !target:IsPlayer() then
		self:PlayAntlionSound("Distracted")
	end
end	

function ENT:PlayAntlionSound(alias, loop)
	local snd = self.AntlionSounds[alias]
	if !snd then return end

	if loop then 
		self:StartLoopingSound(snd)
	else
		self:EmitSound(snd)
	end
end

function ENT:StopAntlionSound(alias)
	local snd = self.AntlionSounds[alias]
	if !snd then return end

	self:StopSound(snd)
end

function ENT:StopAntlionSounds()
	for _,sound in pairs(self.AntlionSounds) do
		if sound then
			self:StopSound(sound)
		end
	end
end

function ENT:OnTraceAttack( dmginfo, dir, trace ) -- We keep this blank because we don't want any hitbox damage multipliers for antlions
end

function ENT:StatsInitialize()
	if SERVER then
		if nzRound:GetNumber() == -1 then
			self:SetRunSpeed( math.random(30, 300) )

			local hp = math.random(100, 1500)
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		else
			local speeds = nzRound:GetZombieSpeeds()
			if speeds then
				self:SetRunSpeed( nzMisc.WeightedRandom(speeds) )
			else
				self:SetRunSpeed( 100 )
			end

			-- local hp = nzRound:GetZombieHealth() or 75
			-- self:SetHealth(hp)
			-- self:SetMaxHealth(hp)

			-- if hp > 2000 then
			-- 	hp = 2000
			-- end

			local hp = nzRound:GetHellHoundHealth() or 220 -- Hell hound health
			hp = hp * 3
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		end

		--Preselect the emerge sequnces for clientside use
		self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
	end
end

function ENT:SpecialInit()
	--make them invisible for a really short duration to blend the emerge sequences
	self:SetNoDraw(true)
	self:TimedEvent(0.1, function() -- Tiny delay just to make sure they are fully initialized
		self:TimedEvent( 0.5, function()
			self:SetNoDraw(false)
		end)

		local _, dur = self:LookupSequence(self.EmergeSequences[self:GetEmergeSequenceIndex()])
		dur = dur - (dur * self:GetCycle()) -- Subtract the time we are already thruogh the animation
	end)
end

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)

	self:SetLeapAtPlayers(true)
    self:SetMaxLeapRange(1200.0)
	self:SetMinLeapRange(300.0)

	self:SetLeapDelayMin(5)
	self:SetLeapDelayMax(5)

	self:SetLeapDamage(30)
	self:SetLeapDamageRadius(90.0)

    self:SetLeapXYMax(80)

	self:SetFlyOnLeap(true)

	self:SetLeapPower(1.5)
	self:SetLeapFlyTime(math.Rand(0.3, 3.5))
	self:SetLandAfterDealingDamage(true)
	self:SetLandWhenNearTarget(true)

	--self:SetLeapZMax(50)
end

function ENT:OnSpawn()
	self:PlayAntlionSound("Dig")
	BaseClass.OnSpawn(self)

	self:SetRunSpeed(255)
	self.loco:SetDesiredSpeed(255)
end

function ENT:CanLeapAtTarget(target)
    return true
end

function ENT:OnHl2PreFly()
	self:PlayAntlionSound("Wings")
end

function ENT:OnPreHL2Leap() -- We are about to jump at a player
	self.loco:SetGravity(math.random(100, 1000))
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
end

function ENT:OnLeapFinished()
	self:SetLeapPower(1.5)
	self:SetLeapFlyTime(math.Rand(0.3, 3.5))
	self.loco:SetGravity(1000)

	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
end

function ENT:OnHL2Land()
	self:PlayAnimation("jump_stop", 1)
	self:StopAntlionSound("Wings")
	self:PlayAntlionSound("Land")
end


function ENT:OnKilled(dmgInfo)
	self:StopAntlionSounds()

	local wep = dmgInfo:GetInflictor()
	local is_shotgun_dmg = dmgInfo:GetDamageType() == DMG_BUCKSHOT or (IsValid(wep) and wep.Primary and wep.Primary.NumShots and wep.Primary.NumShots > 2)

	if dmgInfo:GetIsExplosionDamage() or is_shotgun_dmg then
		ParticleEffect("AntlionGib", self:GetPos(), Angle(0,0,0)) -- In HL2 the antlions can explode into bits (We are only able to replicate the particle effect)
	end

	BaseClass.OnKilled(self, dmgInfo)
end

function ENT:IsValidTarget( ent ) -- Antlions CAN get distracted by things like Bug Bait, but let's not allow that during a Special around (AKA likely an Antlion round)
	if nzRound:IsSpecial() then 
		if !ent then return false end 
		return IsValid( ent ) and ent:GetTargetPriority() != TARGET_PRIORITY_NONE and ent:GetTargetPriority() != TARGET_PRIORITY_SPECIAL
	else
		return BaseClass.IsValidTarget(self, ent)
	end
end

function ENT:OnThink()
	BaseClass.OnThink(self)

	if SERVER and !self:IsOnGround() then
		if !self:GetLeaping() and IsValid(self:GetTarget()) then
			self:HL2Fly(self:GetTarget(), 1)
			--self:HL2Leap(self:GetTarget())
		end

		--self.loco:SetGravity(300)
	end

	-- Show/hide wings bodygroup
	if SERVER then
		if !self:IsOnGround() then
			if self:GetBodygroup(1) != 1 then
				self:SetBodygroup(1, 1)
			end
		elseif self:GetBodygroup(1) != 0 then
			self:SetBodygroup(1, 0)
		end
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	self:StopAntlionSounds()
end

function ENT:BodyUpdate()
	self.CalcIdeal = ACT_IDLE

	local velocity = self:GetVelocity()
	local len2d = velocity:Length2D()

	if len2d <= 0 then self.CalcIdeal = ACT_IDLE
	elseif len2d >= 100 then self.CalcIdeal = ACT_RUN
	elseif len2d > 0 then self.CalcIdeal = ACT_WALK
	else self.CalcIdeal = ACT_IDLE end

	if self:IsJumping() and self:WaterLevel() <= 0 then
		self.CalcIdeal = ACT_JUMP
	end

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	end

	if self.CalcIdeal == ACT_RUN and CurTime() > self:GetLastFootstepSound() + 0.3 then
		self:SetLastFootstepSound(CurTime())
		self:PlayAntlionSound("Footstep")
	end

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
