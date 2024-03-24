-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

nzRound:AddBossType("Antlion Guard", "nz_zombie_hl2_antlionguard", {
	specialspawn = true,
	initfunc = function()
		--nzRound:SetNextBossRound(math.random(6,8)) -- Randomly spawn in rounds 6-8
		nzRound:SetNextBossRound(nzRound:GetNumber() + math.random(10, 12))

		-- We can't have boss round on dog round
		if (nzRound:GetNextSpecialRound() == nzRound:GetNextBossRound()) then
			nzRound:SetNextBossRound(nzRound:GetNextBossRound() + 1)
		end
	end,
	spawnfunc = function(antlion_guard)
		local hp = 5000

		if (nzRound:GetBossRoundsElapsed() <= 0) then
			hp = 5000
		elseif (nzRound:GetBossRoundsElapsed() == 1) then
			hp = 10000
		else
			hp = 15000
		end

		antlion_guard:SetHealth(hp)
		antlion_guard:SetMaxHealth(hp)
	end,
	deathfunc = function(antlion_guard, killer, dmginfo, hitgroup)
		nzRound:SetNextBossRound(nzRound:GetNumber() + math.random(3,5)) -- Delay further boss spawning by 3-5 rounds after its death
		--nzRound:SetNextBossRound(nzRound:GetNumber() + 6)

		if IsValid(attacker) and attacker:IsPlayer() and attacker:GetNotDowned() then
			attacker:GivePoints(500) -- Give killer 500 points if not downed
		end

		-- We can't have boss round on dog round
		if (nzRound:GetNextSpecialRound() == nzRound:GetNextBossRound()) then
			nzRound:SetNextBossRound(nzRound:GetNextBossRound() + 1)
		end
	end
}) -- No onhit function, we don't give points on hit for this guy

ENT.Base = "nz_hl2_zombiebase"
ENT.PrintName = "PB Antlion Guard"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

ENT.DamageLow = 100
ENT.DamageHigh = 100
ENT.DamageForceMultiplier = 100

ENT.AttackRange = 140

ENT.NormalSpeed = 160
ENT.ChargeSpeed = 500
ENT.ChargeDelay = 3

ENT.ShortChargeTurnSpeed = 30
ENT.FarChargeTurnSpeed = 50

ENT.NZBoss = true
ENT.ExtraTriggerBounds = Vector(50,50,50)

AccessorFunc( ENT, "bStoppingCharge", "StoppingCharge", FORCE_BOOL)
AccessorFunc( ENT, "hChargeTarget", "ChargeTarget")
AccessorFunc( ENT, "bCharging", "Charging", FORCE_BOOL)
AccessorFunc( ENT, "bFarCharge", "FarCharge", FORCE_BOOL)
AccessorFunc( ENT, "bChargingAnimation", "ChargingAnimation", FORCE_BOOL)
AccessorFunc( ENT, "bChargeStopAnimation", "ChargeStopAnimation", FORCE_BOOL)
AccessorFunc( ENT, "bStutteringAnimation", "StutteringAnimation", FORCE_BOOL)
AccessorFunc( ENT, "bDyingAnimation", "DyingAnimation", FORCE_BOOL)
AccessorFunc( ENT, "bChargingChargePlayed", "ChargingChargePlayed", FORCE_BOOL)
AccessorFunc( ENT, "fLastCharge", "LastCharge", FORCE_NUMBER)
AccessorFunc( ENT, "fLastStutter", "LastStutter", FORCE_NUMBER)
AccessorFunc( ENT, "fNextStutter", "NextStutter", FORCE_NUMBER)

ENT.BlockHardcodedSwingSound = true

ENT.AntlionGuardSounds = {
	--["Breathe"] = "NPC_AntlionGuard.BreathSound", -- We just straight up use the path because we need to modify pitch anyway
	["Hit"] = "NPC_AntlionGuard.HitHard",
	["Roar"] = "NPC_AntlionGuard.Roar",
	["Die"] = "NPC_AntlionGuard.Die",
	["Fall"] = "NPC_AntlionGuard.Fallover",
	["Confused"] = "NPC_AntlionGuard.Confused",
	["LightFootstep"] = "NPC_AntlionGuard.StepLight",
	["HardFootstep"] = "NPC_AntlionGuard.StepHeavy"
}

ENT.Models = {
	"models/antlion_guard.mdl",
}

local AttackSequences = {

}

function ENT:ApplyChargeAttackSequences()
	self.AttackSequences = {
		{
			seq = "ACT_MELEE_ATTACK1", attacksounds = {"NPC_AntlionGuard.Roar"},
			dmgtimes = {0}
		}
	}
end

function ENT:ApplyNormalAttackSequences()
	self.AttackSequences = {
		{
			seq = "ACT_MELEE_ATTACK1", attacksounds = {"NPC_AntlionGuard.Roar"},
			dmgtimes = {0.5},
			dmg = 40
		}
	}
end

ENT.HitSounds = {
}

local JumpSequences = {
}

ENT.ActStages = {
	[1] = {
		act = ACT_WALK,
		minspeed = 5,
		-- no attackhitsounds, just use ENT.AttackHitSounds for all act stages
		sounds = {},
		barricadejumps = JumpSequences,
	},
	[2] = {
		act = ACT_RUN,
		minspeed = 75,
		sounds = {},
		barricadejumps = JumpSequences,
	}
}

ENT.RedEyes = false -- We have no eyes, we have a headcrab lol

ENT.ElectrocutionSequences = {
	"drown",
}

ENT.EmergeSequences = {
	"floor_break",
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
	""
}

ENT.DeathSounds = {

}

DEFINE_BASECLASS(ENT.Base)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")
    BaseClass.SetupDataTables(self)
end

function ENT:PlayAntlionGuardSound(alias, loop)
	local snd = self.AntlionGuardSounds[alias]
	if !snd then return end

	if loop then
		self:StartLoopingSound(snd)
	else
		self:EmitSound(snd)
	end
end

function ENT:StopAntlionGuardSound(alias)
	local snd = self.AntlionGuardSounds[alias]
	if !snd then return end

	self:StopSound(snd)
end

function ENT:StopAntlionGuardSounds()
	for _,sound in pairs(self.AntlionGuardSounds) do
		if sound then
			self:StopSound(sound)
		end
	end

	self:StopSound("npc/antlion_guard/growl_high.wav")
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

function ENT:StatsInitialize()
	if SERVER then
		if nzRound:GetNumber() == -1 then
			self:SetRunSpeed( math.random(30, 300) )

			local hp = math.random(100, 1500)
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		else
			local hp = 1000
			self:SetHealth(hp)
			self:SetMaxHealth(hp)

			local hp = 5000

			if (nzRound:GetBossCount() <= 0) then
				hp = 5000
			elseif (nzRound:GetBossCount() == 1) then
				hp = 10000
			else
				hp = 15000
			end

			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		end
	end

	--Preselect the emerge sequnces for clientside use
	self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
end

function ENT:OnInitialize()
	BaseClass.OnInitialize(self)
	self:ApplyNormalAttackSequences()

	self:SetMaterial("models/antlion_guard/antlionguard")

	self:SetFarCharge(false)
	self:SetChargeStopAnimation(false)
	self:SetStutteringAnimation(false)
	self:SetCharging(false)
	self:SetLastStutter(0)
	self:SetNextStutter(CurTime() + 2)
	self:SetLastCharge(CurTime() + 3)
	self:SetLastFootstepSound(CurTime())

	self.ConfusedSoundPlayer = CreateSound(self, self.AntlionGuardSounds["Confused"])
end

function ENT:OnBarricadeBlocking( barricade ) -- LMAO I saw that they could attack barricades so I made it break all boards in 1 hit..
	timer.Simple(1, function()
		if (IsValid(barricade) and barricade:GetClass() == "breakable_entry") then
			barricade:RemoveAllPlanks()
		end
	end)
end

function ENT:OnSpawn()
	self:EmitSound("npc/antlion_guard/growl_high.wav", 65, 100)

	BaseClass.OnSpawn(self)

	self:SetRunSpeed(self.NormalSpeed)
	self.loco:SetDesiredSpeed(self.NormalSpeed)
end

function ENT:Charge(target)
	if (self:GetCharging()) then return end
	self:PlayAntlionGuardSound("Roar")
	self:ApplyChargeAttackSequences()

	self:SetChargeTarget(target)
	self:SetChargingAnimation(false)
	self:PlayAnimation("charge_startfast")
	self:SetRunSpeed(0)
	self.loco:SetDesiredSpeed(0)
 	self:SetCharging(true)
	self:SetChargingChargePlayed(false)

	local should_add_seconds = self:GetRangeSquaredTo(target:GetPos()) > 500^2
	local distance_needed = self:GetRangeSquaredTo(target:GetPos())

	self:TimedEvent(0.8, function()
		self.loco:FaceTowards(target:GetPos())

		if should_add_seconds then
			self.loco:SetMaxYawRate(self.FarChargeTurnSpeed)
		else
			self.loco:SetMaxYawRate(self.ShortChargeTurnSpeed)
		end

		self:SetChargingAnimation(true)
		self:StopSound("npc/antlion_guard/growl_high.wav")
		self:EmitSound("npc/antlion_guard/growl_high.wav", 65, 150)

		-- In HL2, the Antlionguard's charge depends on distance to player when the charge started, it is not a set time.
		timer.Stop("AntlionGuardCharging" .. self:EntIndex())
		timer.Create("AntlionGuardCharging" .. self:EntIndex(), (distance_needed / self.ChargeSpeed^2) + (should_add_seconds and 3 or 1), 1, function()
			if IsValid(self) and self:Health() > 0 and self:GetCharging() then
				self:StopCharge()
			end
		end)
	end)
end

function ENT:StopChargeTimer()
	timer.Stop("AntlionGuardCharging" .. self:EntIndex())
end

function ENT:StopCharge(fast)
	if !self:GetCharging() then return end
	self:StopChargeTimer()

	self:PlayAntlionGuardSound("Roar")
	self:StopSound("npc/antlion_guard/growl_high.wav")
	self:EmitSound("npc/antlion_guard/growl_high.wav", 65, 100)

	self:ApplyNormalAttackSequences()

	self:SetChargeStopAnimation((!self:TargetInAttackRange() and !fast) and true or false)

	self.loco:SetMaxYawRate(250)
	self:SetRunSpeed(self.NormalSpeed)
	self.loco:SetDesiredSpeed(self.NormalSpeed)
	self:SetChargingAnimation(false)
	self:SetLastCharge(CurTime())
	self:SetCharging(false)
end

function ENT:ChargeThink()
	-- Keep their speed
	if self:GetChargingAnimation() then
		self:SetRunSpeed(self.ChargeSpeed)
		self.loco:SetDesiredSpeed(self.ChargeSpeed)
	end

	-- Target validation, also keep the same target we started charging to
	local charge_target = self:GetChargeTarget()
	if IsValid(charge_target) and !charge_target:IsPlayer() or (charge_target:GetNotDowned() and (!charge_target:IsSpectating() or charge_target:IsInCreative())) then
		self:SetTarget(self:GetChargeTarget())
	else
		self:StopCharge(true)
	end

	-- Cancel when running into map
	local pos = self:GetPos()
	pos[3] = pos[3] + 50

	local tr = util.TraceLine({
		start = pos,
		endpos = pos + (self:GetForward() * 50),
		filter = self,
		mask = MASK_ALL,
		collisiongroup = COLLISION_GROUP_DEBRIS
	})

	if tr.Hit then
		self:StopCharge()
		self:PlayAntlionGuardSound("Hit")
	end
end

function ENT:OnAttack(target)
	BaseClass.OnAttack(self, target)

	-- Fling them
	self:PlayAntlionGuardSound("Hit")

	-- Stop charging
	if self:GetCharging() then
		self:TimedEvent(1, function()
			if self:GetCharging() then
				self:StopCharge(true)
			end
		end)
	end
end

function ENT:ScaleNPCDamage(zombie, hitgroup, dmginfo) -- Antlionguard takes decreased damage from most things that aren't explosions
	if dmginfo:GetIsBulletDamage() then
		dmginfo:ScaleDamage(0.5)
	end

	if dmginfo:GetIsShotgunDamage() then
		dmginfo:ScaleDamage(0.25)
	end

	if dmginfo:GetDamageType() == DMG_SHOCK || dmginfo:GetDamageType() == DMG_DISSOLVE then
		if dmginfo:GetDamage() > 1000 then
			dmginfo:SetDamage(1000)
		end
	end
end

function ENT:OnTakeDamage(dmginfo)
	BaseClass.OnTakeDamage(self, dmginfo)

	if ((dmginfo:GetIsExplosionDamage() and dmginfo:GetDamage() >= 150) or dmginfo:GetDamage() >= 2500) then -- This is enough to stutter us!
		if CurTime() > self:GetNextStutter() then
			self:SetLastStutter(CurTime())
			self:SetNextStutter(CurTime() + math.Rand(2, 4.5))
			self.ConfusedSoundPlayer:Play()
			self:StopCharge()
			self:SetStutteringAnimation(true)
			self:TimedEvent(1, function()
				self.ConfusedSoundPlayer:FadeOut(0.5)
			end)
		end
	end
end

function ENT:IsValidTarget( ent )
	if !ent then return false end
	return IsValid(ent) and !self:IsTargetDead(ent) and ent:GetTargetPriority() != TARGET_PRIORITY_NONE and ent:GetTargetPriority() != TARGET_PRIORITY_SPECIAL
	-- Won't go for special targets (Monkeys), but still MAX, ALWAYS and so on
end

function ENT:OnThink()
	BaseClass.OnThink(self)

	if SERVER then
		-- Make sure they are always running fast when charging
		if self:GetCharging() and !self:GetChargeStopAnimation() then
			self:ChargeThink()
		end

		-- Do charge when close enough
		if self:Health() > 0 and self:IsAllowedToMove() then
			local target = self:GetTarget()
			if (CurTime() > (self:GetLastCharge() + self.ChargeDelay) and IsValid(target) and !self:GetTargetUnreachable()) then
				local dist_to_target = self:GetRangeSquaredTo(self:GetTarget():GetPos())

				if dist_to_target <= 2000^2 and dist_to_target > 200^2 then
					if target:IsPlayer() and !self:IsIgnoredTarget(target) and target:Visible(self) then
						if self:GetCharging() then return end
						self:Charge(target)
					end
				end
			end
		end
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	self:StopAntlionGuardSounds()
end

function ENT:BodyUpdate()
	self.CalcIdeal = ACT_IDLE

	local velocity = self:GetVelocity()
	local len2d = velocity:Length2D()

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	else
		self.CalcIdeal = ACT_RUN
	end

	if self:GetChargingAnimation() then
		self.CalcIdeal = "ACT_ANTLIONGUARD_CHARGE_RUN"
	end

	if self:IsJumping() and self:WaterLevel() <= 0 then
		self.CalcIdeal = ACT_JUMP
	end

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	end

	if self.CalcIdeal == ACT_RUN and CurTime() > self:GetLastFootstepSound() + 0.3 then
		self:SetLastFootstepSound(CurTime())
		self:PlayAntlionGuardSound("LightFootstep")
	end

	if self.CalcIdeal == "ACT_ANTLIONGUARD_CHARGE_RUN" and CurTime() > self:GetLastFootstepSound() + 0.3 then
		self:SetLastFootstepSound(CurTime())
		self:PlayAntlionGuardSound("HardFootstep")
	end

	if self:GetChargeStopAnimation() then
		self:SetRunSpeed(0)
		self.loco:SetDesiredSpeed(0)
		self.CalcIdeal = "ACT_ANTLIONGUARD_CHARGE_STOP"

		self:TimedEvent(1.5, function()
			self:SetChargeStopAnimation(false)
			self:SetRunSpeed(self.NormalSpeed)
			self.loco:SetDesiredSpeed(self.NormalSpeed)
		end)
	end

	if self:GetStutteringAnimation() then
		self:SetRunSpeed(0)
		self.loco:SetDesiredSpeed(0)
		self.CalcIdeal = "ACT_ANTLIONGUARD_PHYSHIT_FR"

		self:TimedEvent(1.3, function()
			self:SetStutteringAnimation(false)
			self:SetRunSpeed(self.NormalSpeed)
			self.loco:SetDesiredSpeed(self.NormalSpeed)
		end)
	end

	if self:GetDyingAnimation() then
		self.CalcIdeal = "ACT_DIESIMPLE"
		self:SetChargeStopAnimation(false)
		self:SetChargingAnimation(false)
		self:SetStutteringAnimation(false)
		self:SetRunSpeed(0)
		self.loco:SetDesiredSpeed(0)
		self.loco:SetMaxYawRate(0)

		if !self.DidDeathStuff then
			self.DidDeathStuff = true

			self.CanHurtTarget = function() return false end
			self.AttackSequences = {seq = "", attacksounds = {""}}

			self.ConfusedSoundPlayer:Stop()
			self:StopSound("npc/antlion_guard/growl_high.wav")
			self:PlayAntlionGuardSound("Die")

			timer.Simple(2.5, function()
				if IsValid(self) then
					self:PlayAntlionGuardSound("Fall")
					self:BecomeRagdoll(DamageInfo())
				end
			end)

			self:TimedEvent(3, function()
				self:SetDyingAnimation(false)
			end)
		end
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

function ENT:OnZombieDeath(dmgInfo)
	self:StopCharge(true)
	self:SetDyingAnimation(true)
end
