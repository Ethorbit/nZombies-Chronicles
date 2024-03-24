-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of fastzombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.

AddCSLuaFile()

nzRound:AddZombieType("HL2 Fast Zombie", "nz_zombie_hl2_fastzombie", {
    -- Set to false to disable the spawning of this zombie
    Valid = true,
    -- Allow you to scale damage on a per-hitgroup basis
    ScaleDMG = function(zombie, hitgroup, dmginfo)
        -- Headshots for double damage
        --if hitgroup == HITGROUP_HEAD then dmginfo:ScaleDamage(2) end
    end,
    -- Function runs whenever the zombie is damaged (NOT when killed)
    OnHit = function(zombie, dmginfo, hitgroup)
        local attacker = dmginfo:GetAttacker()
        -- If player is playing and is not downed, give points
        if attacker:IsPlayer() and attacker:GetNotDowned() then
            attacker:GivePoints(10)
        end
    end,
    -- Function is run whenever the zombie is killed
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
ENT.PrintName = "PB Fastzombie"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

ENT.DamageLow = 25
ENT.DamageHigh = 25
ENT.AttackRange = 65

ENT.NetworkOnTakeDamage = true -- We need to play (clientside) gurgle damaged sounds

ENT.BlockHardcodedSwingSound = true

ENT.FastZombieSounds = {
	["NewTarget"] = "NPC_FastZombie.AlertNear",
	["NewTargetFar"] = "NPC_FastZombie.AlertFar",
	["Breathe"] = "npc/fast_zombie/breathe_loop1.wav",
	["Gurgle"] = "NPC_FastZombie.Gurgle",
	["Roar"] = "NPC_FastZombie.Frenzy",
	["Leap"] = "NPC_FastZombie.LeapAttack",
	["RangeAttack"] = "NPC_FastZombie.RangeAttack",
	["AttackMiss"] = "NPC_FastZombie.AttackMiss",
	["Scream"] = "NPC_FastZombie.Scream",
	["FootstepLeft"] = "NPC_FastZombie.FootstepLeft",
	["FootstepRight"] = "NPC_FastZombie.FootstepRight"
}

ENT.Models = {
	"models/zombie/fast.mdl",
}

local AttackSequences = {
	{seq = "Melee", dmgtimes = {0.1, 0.3}},
}

local AttackSounds = {
	"NPC_FastZombie.Frenzy",
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
	"idle_angry",
}

ENT.EmergeSequences = {
	"climbdismount",
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
	"nzr/zombies/death/nz_flesh_impact_0.wav",
	"nzr/zombies/death/nz_flesh_impact_1.wav",
	"nzr/zombies/death/nz_flesh_impact_2.wav",
	"nzr/zombies/death/nz_flesh_impact_3.wav",
	"nzr/zombies/death/nz_flesh_impact_4.wav"
}
ENT.DeathSounds = {
	"NPC_FastZombie.Die"
}

DEFINE_BASECLASS(ENT.Base)

AccessorFunc( ENT, "fFZLastRoar", "FZLastRoar", FORCE_NUMBER)
AccessorFunc( ENT, "bFZRoaring", "FZRoaring", FORCE_BOOL)
AccessorFunc( ENT, "bFZHasScreamed", "FZHasScreamed", FORCE_BOOL)
AccessorFunc( ENT, "bFZRunning", "FZRunning", FORCE_BOOL)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")
	self:NetworkVar("Bool", 1, "HeadcrabDetached")

    BaseClass.SetupDataTables(self)
end

function ENT:OnSpawn()
	self:PlayFastZombieSound("Breathe", nil, true)

	BaseClass.OnSpawn(self)
end

function ENT:PlayFastZombieSound(alias, sndlvl, loop)
	local snd = self.FastZombieSounds[alias]
	if !snd then return end

	if loop then
		self:StartLoopingSound(snd)
	else
		self:EmitSound(snd, sndlvl)
	end
end

function ENT:StopFastZombieSound(alias)
	local snd = self.FastZombieSounds[alias]
	if !snd then return end
	self:StopSound(snd)
end

function ENT:StopFastZombieSounds()
	for _,sound in pairs(self.FastZombieSounds) do
		if sound then
			self:StopSound(sound)
		end
	end
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
			if speeds and !table.IsEmpty(speeds) then
				local speed = nzMisc.WeightedRandom(speeds)
				self:SetRunSpeed(speed <= 150 and 150 or speed)
			else
				self:SetRunSpeed( 100 )
			end

			local hp = nzRound:GetZombieHealth() or 75
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		end

		timer.Simple(0.1, function() -- We wait because if spawned by toolgun, it runs injected code after all this runs
			if (self:GetRunSpeed() >= 100) then
				self:SetFZRunning(true)
				self:SetLeapPower(2.0)
			else
				self:SetFZRunning(false)
				self:SetLeapPower(0.9)
			end
		end)

		--Preselect the emerge sequnces for clientside use
		self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
	end

	if CLIENT then
		self:SetRenderMode(RENDERMODE_TRANSADD)
		self:SetColor(Color(255,255,255,20))
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

	self:SetDropsHeadcrab(true)
	self:SetHeadcrabClass("nz_zombie_hl2_headcrab_fast")

	self:SetLeapAtPlayers(true)
    self:SetMaxLeapRange(300.0)
	self:SetMinLeapRange(290.0)

	self:SetLeapDelayMin(5)
	self:SetLeapDelayMax(5)

	self:SetLeapDamage(25)

	self:SetLeapPower(2)
    self:SetLeapXYMax(80)

	self.GurgleSound = CreateSound(self, self.FastZombieSounds["Gurgle"])
	self:SetFZLastRoar(0)
	self:SetFZRoaring(false)
	self:SetFZHasScreamed(false)

	local torso_mdl = "models/Gibs/Fast_Zombie_Torso.mdl"
	local legs_mdl = "models/Gibs/Fast_Zombie_Legs.mdl"
	self:SetTorsoModel(torso_mdl)
	self:SetLegsModel(legs_mdl)
	self.Gibs = {
		torso_mdl,
		legs_mdl
	}
end

function ENT:FastZombie_Alert(target)
	local alertsound = self:GetRangeSquaredTo(target:GetPos()) >= 900^2 and "NewTargetFar" or "NewTarget"
	self:PlayFastZombieSound(alertsound)
end

function ENT:OnNewTarget(target)
	if self:GetEmerging() then return end
	self:FastZombie_Alert(target)
end

function ENT:OnEmergeFinished()
	if IsValid(self:GetTarget()) then
		self:FastZombie_Alert(self:GetTarget())
	end
end

function ENT:Attack(data, ...)
	BaseClass.Attack(self, data, ...)

	if !data or !data.isleapdmg then
		self:Fastzombie_Roar()
	end
end

function ENT:SoundThink()

end

function ENT:Fastzombie_Roar() -- This is what HL2 plays after it swings at a player
	self:SetFZRoaring(true)
	self:PlayIdleAndWait("", 1)
	self:PlayFastZombieSound("Roar")
	self:PlayIdleAndWait("BR2_Roar", 1)
	self:SetFZRoaring(false)
end

function ENT:OnPreHL2Leap() -- We are about to jump at a player
	if !self:GetFZHasScreamed() then
		self:PlayFastZombieSound("Scream") -- make them shit themselves
		self:SetFZHasScreamed(true)
	else
		self:PlayFastZombieSound("RangeAttack")
	end

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
end

function ENT:OnLeapFinished()
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
end

function ENT:OnTakeDamage(dmginfo)
	if self:Health() <= 0 then return end

	if CLIENT then
		self.GurgleSound:PlayEx(0.8, 100)

		timer.Create("Fastzombie_FadingOutGurgle" .. self:EntIndex(), 0.4, 1, function()
			if IsValid(self) and self.GetLastHurt and CurTime() > self:GetLastHurt() + 0.4 then
				self.GurgleSound:FadeOut(0.4)
			end
		end)
	return end

	BaseClass.OnTakeDamage(self, dmginfo)
end

function ENT:OnKilled(dmgInfo)
	self:StopFastZombieSounds()
	self.GurgleSound:Stop()

	BaseClass.OnKilled(self, dmgInfo)
end

function ENT:OnThink()
	BaseClass.OnThink(self)

	if self:GetBodygroup(1) != 1 then
		self:SetBodygroup(1, 1)
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	self:StopFastZombieSounds()
end

function ENT:Fastzombie_Footstep()
	self:SetLastFootstepSound(CurTime())
	self.PlayedRightFootstep = !self.PlayedRightFootstep
	self:PlayFastZombieSound(self.PlayedRightFootstep and "FootstepLeft" or "FootstepRight")
end

function ENT:BodyUpdate()
	self.CalcIdeal = ACT_IDLE

	local velocity = self:GetVelocity()
	local len2d = velocity:Length2D()

	if len2d <= 0 then self.CalcIdeal = ACT_IDLE
	elseif len2d >= 90 then self.CalcIdeal = ACT_RUN
	elseif len2d > 0 then self.CalcIdeal = ACT_WALK
	else self.CalcIdeal = ACT_IDLE end

	if self:IsJumping() and self:WaterLevel() <= 0 then
		self.CalcIdeal = ACT_JUMP
	end

	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	end

	if self.CalcIdeal == ACT_WALK and CurTime() > self:GetLastFootstepSound() + 0.3 then
		self:Fastzombie_Footstep()
	end

	if self.CalcIdeal == ACT_RUN and CurTime() > self:GetLastFootstepSound() + 0.2 then
		self:Fastzombie_Footstep()
	end

	--if self:GetFZRoaring() then return end

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
