-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

nzConfig.AddValidEnemy("nz_zombie_hl2_vortigaunt", {
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
                attacker:GivePoints(330)
            else
                attacker:GivePoints(300)
            end
        end
    end
})

ENT.Base = "nz_hl2_zombiebase"
ENT.PrintName = "PB Vortigaunt"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

DEFINE_BASECLASS(ENT.Base)

ENT.DamageLow = 0
ENT.DamageHigh = 0
ENT.AttackRange = 75 

ENT.ZapDamage = 15
ENT.StompDamage = 5

ENT.ZapRange = 1000 -- If target is farther than this, the vortigaunt will move to them until it is close enough
ENT.ZapBeamColor = Color(0,255,0)
ENT.ZapBeamSprite = Material("effects/tool_tracer")
ENT.ZapImpactSprite = Material("sprites/vortring1.vmt")

ENT.TeleportSprite = Material("nzr/nz/zlight")
ENT.TeleportColor = Color(0,255,0)

ENT.MoveSpeed = 120
ENT.ZapDelay = 5.5
ENT.FleeDistance = 100

ENT.BlockHardcodedSwingSound = true

sound.Add({
    name        = "Vortigaunt.Alert",
    channel     = CHAN_VOICE,
    volume      = 1,
    soundlevel  = 75,
    pitchstart  = 100,
    pitchend    = 100,
    sound       = {
		"vo/npc/vortigaunt/vortigese02.wav",
		"vo/npc/vortigaunt/vortigese03.wav",
		"vo/npc/vortigaunt/vortigese04.wav",
		"vo/npc/vortigaunt/vortigese05.wav",
		"vo/npc/vortigaunt/vortigese07.wav",
		"vo/npc/vortigaunt/vortigese08.wav",
		"vo/npc/vortigaunt/vortigese09.wav"
	}
})

ENT.VortigauntSounds = {
	["TeleportElectricity"] = "npc/roller/mine/rmine_shockvehicle1.wav",
	["Teleport"] = "npc/roller/mine/rmine_explode_shock1.wav",
	["ZapPowerup"] = "npc/vort/attack_charge.wav",
	["Zap"] = "npc/vort/attack_shoot.wav",
	["Stomp"] = "npc/vort/foot_hit.wav",
	["FootstepLeft"] = "NPC_Vortigaunt.FootstepLeft",
	["FootstepRight"] = "NPC_Vortigaunt.FootstepRight",
	["Vort"] = "Vortigaunt.Alert"
}

ENT.Models = {
	"models/vortigaunt.mdl",
}

PrecacheParticleSystem("vortigaunt_hand_glow")

AccessorFunc(ENT, "fNextVortSound", "NextVortSound", FORCE_NUMBER)

AccessorFunc(ENT, "bMovementAllowed", "MovementAllowed", FORCE_BOOL)
AccessorFunc(ENT, "bMovingCloser", "MovingCloser", FORCE_BOOL)

AccessorFunc(ENT, "bZapping", "Zapping", FORCE_BOOL)
AccessorFunc(ENT, "bStomping", "Stomping", FORCE_BOOL)

AccessorFunc(ENT, "fLastZap", "LastZap", FORCE_NUMBER)
AccessorFunc(ENT, "fNextZap", "NextZap", FORCE_NUMBER)
AccessorFunc(ENT, "vIntendedZapDestination", "IntendedZapDestination")
AccessorFunc(ENT, "bTargetInIntendedZapRange", "TargetInIntendedZapRange")

AccessorFunc(ENT, "bShouldDrawModel", "ShouldDrawModel", FORCE_BOOL)
AccessorFunc(ENT, "bShowXenEffect", "ShowXenEffect", FORCE_BOOL)

if CLIENT then
	AccessorFunc(ENT, "fZapBeamWidth", "ZapBeamWidth", FORCE_NUMBER)
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "EmergeSequenceIndex")
	self:NetworkVar("Float", 0, "ZapShootDuration")
	self:NetworkVar("Bool", 0, "ZappingHandParticles")
	self:NetworkVar("Bool", 1, "ZapShooting")
	self:NetworkVar("Vector", 0, "ZapShootDesination")
	
	if CLIENT then -- Zap hand particles
		self:NetworkVarNotify("ZappingHandParticles", function(ent, name, oldval, newval)
			if (newval) then
				ParticleEffectAttach("vortigaunt_hand_glow", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("leftclaw"))
				ParticleEffectAttach("vortigaunt_hand_glow", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("rightclaw"))
			else
				self:StopParticlesNamed("vortigaunt_hand_glow")
			end
		end)

		self:NetworkVarNotify("ZapShooting", function(ent, name, oldval, newval)	
			if (newval) then
				self:SetZapBeamWidth(22.0)

				timer.Simple(0, function()
					local sparkData = EffectData()
					sparkData:SetOrigin(self:GetZapShootDesination())
					sparkData:SetMagnitude(20)
					sparkData:SetScale(0.1)
					util.Effect("Sparks", sparkData)
				end)
			end
		end)
	end

    BaseClass.SetupDataTables(self)
end

local AttackSequences = {
	{seq = "MeleeHigh1", dmgtimes = {0.5}, dmg = 0},
	{seq = "MeleeHigh2", dmgtimes = {0.5}, dmg = 0},
	--{seq = "MeleeLow", dmgtimes = {0.5}, dmg = 0},
}

local JumpSequences = {
	{seq = "climbloop", speed = 15, time = 2.7},
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
	"releasecrab",
}

ENT.EmergeSequences = {
	"slumprise_a",
	"slumprise_a2",
	"slumprise_a2",
	"slumprise_b",
}

ENT.AttackHitSounds = {
	"npc/vort/foot_hit.wav"
}

ENT.AttackMissSounds = {
	"NPC_Vortigaunt.Swing"
}

ENT.PainSounds = {
	"nzr/zombies/death/nz_flesh_impact_0.wav",
	"nzr/zombies/death/nz_flesh_impact_1.wav",
	"nzr/zombies/death/nz_flesh_impact_2.wav",
	"nzr/zombies/death/nz_flesh_impact_3.wav",
	"nzr/zombies/death/nz_flesh_impact_4.wav"
}
ENT.DeathSounds = {
	""
}

function ENT:OnInitialize()
	BaseClass.OnInitialize(self)

	self:SetMovingCloser(false)
	self:SetNextZap(CurTime() + math.Clamp(self.ZapDelay - 3.5, 0, self.ZapDelay))
	self:SetLastZap(CurTime())
	self:SetNextVortSound(CurTime() + math.Rand(4, 10))
end

function ENT:PlayVortigauntSound(alias, loop)
	local snd = self.VortigauntSounds[alias]
	if !snd then return end

	if loop then 
		self:StartLoopingSound(snd)
	else
		self:EmitSound(snd)
	end
end

function ENT:StopVortigauntSound(alias)
	local snd = self.VortigauntSounds[alias]
	if !snd then return end
	self:StopSound(snd)
end

function ENT:StopVortigauntSounds()
	for _,sound in pairs(self.VortigauntSounds) do
		if sound then
			self:StopSound(sound)
		end
	end
end

function ENT:OnNewTarget()
	self:PlayVortigauntSound("NewTarget")
end

function ENT:OnTraceAttack( dmginfo, dir, trace ) -- We keep this blank because we don't want any hitbox damage multipliers for antlions
end

function ENT:StatsInitialize()
	if SERVER then
		if nzRound:GetNumber() == -1 then
			local hp = math.random(100, 1500)
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		else
			self:SetHealth(1000)
			self:SetMaxHealth(1000)
		end		
	end
end

function ENT:SpecialInit()
	if SERVER then
		self:EmitSound(self.VortigauntSounds["TeleportElectricity"], 65)
	end

	local effect = EffectData()
	effect:SetScale(1)
	effect:SetMagnitude(4)
	effect:SetScale(1)
	effect:SetRadius(1)
	effect:SetStart(self:GetPos())
	effect:SetOrigin(self:GetPos())
	effect:SetEntity(self)
	effect:SetMagnitude(41)
	util.Effect("TeslaHitboxes", effect)

	self:TimedEvent(0.1, function()
		self:SetShouldDrawModel(false)
		self:SetShowXenEffect(true)
		util.Effect("TeslaHitboxes", effect)
	end)	

	if SERVER then
		self:TimedEvent(0.95, function()
			self:PlayVortigauntSound("Teleport")
		end)
	end

	self:TimedEvent(1, function()
		self:SetShouldDrawModel(true)
		self:SetShowXenEffect(false)

		if SERVER then
			self:TimedEvent(1.5, function()
				self:SetRunSpeed(self.MoveSpeed)
				self.loco:SetDesiredSpeed(self.MoveSpeed)
			end)
		end
	end)
end

function ENT:CanHurtTarget()
	return false
end

function ENT:OnTakeDamage(dmginfo)
	BaseClass.OnTakeDamage(self, dmginfo)

	if (self:GetShowXenEffect()) then
		dmginfo:SetDamage(0)
	end
end

function ENT:Draw()
	-- Show Xen teleportation effect, Vortigaunts are cool like that:
	if self:GetShowXenEffect() then
		cam.Start3D(EyePos(),EyeAngles())
		render.SetMaterial(self.TeleportSprite)
		render.DrawSprite(self:GetPos() + Vector(0,0,30), 250, 250, self.TeleportColor)
		cam.End3D()
	end

	if self:GetZapShooting() then
		local leftclaw_pos = self:GetAttachment(self:LookupAttachment("leftclaw")).Pos
		local rightclaw_pos = self:GetAttachment(self:LookupAttachment("rightclaw")).Pos
		render.SetMaterial(self.ZapBeamSprite)

		self:SetZapBeamWidth(math.Approach(self:GetZapBeamWidth(), 0, 0.25))
		render.DrawBeam(leftclaw_pos, self:GetZapShootDesination(), self:GetZapBeamWidth(), 0, 0, self.ZapBeamColor)
		render.DrawBeam(rightclaw_pos, self:GetZapShootDesination(), self:GetZapBeamWidth(), 0, 0, self.ZapBeamColor)
	end

	if self:GetShouldDrawModel() then
		BaseClass.Draw(self)
	end
end

function ENT:OnKilled(dmgInfo)
	self:StopVortigauntSounds()

	BaseClass.OnKilled(self, dmgInfo)
end

function ENT:Vortigaunt_CancelZap()
	self:SetZapping(false)
	self:SetZappingHandParticles(false)
	self:StopBodyUpdateSequence("zapattack1")
	self:SetIntendedZapDestination(nil)
	self:SetTargetInIntendedZapRange(false)
end

function ENT:TargetTooCloseToZap()
	return self:TargetInRange(200)
end

function ENT:Vortigaunt_Zap(target, forced)
	if self:TargetTooCloseToZap() and !forced then return end
	self:SetZapping(true)

	-- Mark where we plan to hit the enemy:
	local zap_pos = target:GetPos()
	self:SetIntendedZapDestination(zap_pos)
	self:SetZappingHandParticles(true)
	
	self:EmitSound(self.VortigauntSounds["ZapPowerup"], 75, 150)

	self:TimedEvent(1.5, function()
		self:StopSound(self.VortigauntSounds["ZapPowerup"])

		if !self:GetZapping() then 
			self:Vortigaunt_CancelZap()
		return end

		self:PlayVortigauntSound("Zap") 
		self:SetZappingHandParticles(false)

		local dist_away_from_spot = target:GetPos():DistToSqr(zap_pos)

		if (dist_away_from_spot >= 350^2 and !self:TargetInAttackRange()) then -- They got away, hit the old position
			local tr = self:TraceSelf(self:GetPos() + Vector(0,0,10), zap_pos, true, true)
			self:SetZapShootDesination(tr.HitPos)
		else -- They are still close, lock our zap onto them 
			local tr = self:TraceSelf(self:GetPos(), target:GetPos(), nil, true)
			self:SetZapShootDesination(tr.HitPos)

			local hit_target = tr.HitPos:DistToSqr(target:GetPos()) <= 50^2
			if hit_target then
				local dmginfo = DamageInfo()
				dmginfo:SetAttacker(self)
				dmginfo:SetDamageType(DMG_SHOCK)
				dmginfo:SetDamage(self.ZapDamage)
				target:TakeDamageInfo(dmginfo)
			end
		end	

		self:SetZapShootDuration(1)
		self:SetZapShooting(true)

		self:TimedEvent(1, function()
			self:SetZapShooting(false)
			self:SetIntendedZapDestination(nil)
			self:SetTargetInIntendedZapRange(false)
		end)
	end)

	-- Zap animation
	self:StartBodyUpdateSequence("zapattack1", function() -- After zap is finished
		if !self:GetZapping() then return end
		self:Vortigaunt_CancelZap()
		
		-- Move a little closer after each shot (Just like in HL2)
		if IsValid(target) and target == self:GetTarget() then
			self:SetMovingCloser(true)
			self:SetRunSpeed(self.MoveSpeed) 
			self.loco:SetDesiredSpeed(self.MoveSpeed)
			
			self.loco:Approach(target:GetPos(), 1000)
			self:TimedEvent(1.5, function()
				self:SetMovingCloser(false)
				self.loco:Approach(self:GetPos(), 1000)
			end)
		end
	end) 
end

function ENT:Vortigaunt_Stomp()
	if self:GetZapping() then return end

	self:SetStomping(true)

	self:TimedEvent(0.7, function()
		if !self:GetStomping() then return end

		self:PlayVortigauntSound("Stomp")

		local footPos = self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_R_Foot")) 
		effects.BeamRingPoint(footPos, 0.2, 80, 300, 10, 0, self.ZapBeamColor)

		self:EmitSound(self.VortigauntSounds["Zap"], 75, 90)

		-- Push players
		for _,ent in pairs(ents.FindInSphere(self:GetPos(), 300)) do
			if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent.Type == "nextbot") then
				local dir = (ent:GetPos() - self:GetPos()):GetNormalized()
				local newVec = dir * 3000
				ent:SetVelocity(newVec)

				local dmginfo = DamageInfo()
				dmginfo:SetAttacker(self)
				dmginfo:SetDamageType(DMG_SHOCK)
				dmginfo:SetDamage(self.StompDamage)
				ent:TakeDamageInfo(dmginfo)
			end
		end
	end)

	self:StartBodyUpdateSequence("stomp", function()
		self:SetStomping(false)
		self:SetNextZap(CurTime() - 1)
	end, 1.5)
end

function ENT:Jump() end -- Vortigaunts don't jump..

function ENT:Attack() -- Our only ways to attack is by zapping, but we can stomp-push away our enemies too
	coroutine.wait(0)
	
	if !self:GetStomping() then
		self:Vortigaunt_Stomp()
	end
end

function ENT:OnThink()
	BaseClass.OnThink(self)

	if SERVER then
		if CurTime() > self:GetNextVortSound() then
			self:SetNextVortSound(CurTime() + math.Rand(4, 10))
			self:PlayVortigauntSound("Vort")
		end

		if !self:GetShouldDrawModel() then
			self:SetRunSpeed(0)
			self.loco:SetDesiredSpeed(0)
		end

		local target = self:GetTarget()
		local is_valid_target = IsValid(target) and (target:GetNotDowned() or target:IsInCreative()) and !self:GetTargetUnreachable() and self:IsLineOfSightClear(target:GetPos())
		local intended_zap_dest = self:GetIntendedZapDestination()

		if is_valid_target and intended_zap_dest then
			self:SetTargetInIntendedZapRange(target:GetPos():DistToSqr(self:GetIntendedZapDestination()) <= 350^2)

			if self:GetTargetInIntendedZapRange() then -- We turn to them
				self.loco:FaceTowards(target:GetPos())
				self.loco:SetMaxYawRate(250)
			else -- We turn to intended place
				self.loco:FaceTowards(self:GetIntendedZapDestination())
				self.loco:SetMaxYawRate(0)
			end
		elseif (self.loco:GetMaxYawRate() == 0) then
			self.loco:SetMaxYawRate(250)
		end

		if !self:GetShowXenEffect() then
			if self:IsPlayingCustomBodyActivity() then
				self:SetRunSpeed(0)
				self.loco:SetDesiredSpeed(0)
			elseif self:GetMovingCloser() then
				if (self:TargetInRange(290)) then
					self:SetMovingCloser(false)
					self.loco:Approach(self:GetPos(), 1000)
				end
			else 
				if is_valid_target then
					if self:TargetInRange(self.ZapRange) then -- We are close enough to zap em
						local tr = self:TraceSelf(self:GetPos(), self:GetTarget():GetPos(), nil, true)
						if tr.Entity == self:GetTarget() then 
							if (self:TargetTooCloseToZap()) then 	
								self:SetRunSpeed(self.MoveSpeed)
								self.loco:SetDesiredSpeed(self.MoveSpeed)
								self:FleeTarget(1)
								self:SetNextZap(CurTime() - 1)
							else
								self:StopFleeing()
	
								self:SetRunSpeed(0)
								self.loco:SetDesiredSpeed(0)
		
								if CurTime() > self:GetNextZap() then
									self:SetLastZap(CurTime())
									self:SetNextZap(CurTime() + self.ZapDelay)
									self:Vortigaunt_Zap(target)
								end
							end
						end 
					end
				else
					self:SetRunSpeed(self.MoveSpeed)
					self.loco:SetDesiredSpeed(self.MoveSpeed)
				end
			end
		end
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	self:StopVortigauntSounds()
end

function ENT:Vortigaunt_Footstep()
	self:SetLastFootstepSound(CurTime())
	self.PlayedRightFootstep = !self.PlayedRightFootstep
	self:PlayVortigauntSound(self.PlayedRightFootstep and "FootstepLeft" or "FootstepRight")
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

	if self:IsJumping() and self:WaterLevel() <= 0 then
		self.CalcIdeal = ACT_JUMP
	end

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	end

	if self.CalcIdeal == ACT_WALK and CurTime() > self:GetLastFootstepSound() + 0.5 then
		self:Vortigaunt_Footstep()
	end

	local data = self:GetBodyUpdateData()
	if data then
		self:StopFleeing()
		self:SetStuckCounter(0)
		self.CalcIdeal = data.activity_name
		self:SetPlaybackRate(data.playback_rate)
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
