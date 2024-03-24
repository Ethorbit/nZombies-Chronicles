-- If you hate errors, get the addon: https://steamcommunity.com/sharedfiles/filedetails/?id=717560985

AddCSLuaFile()

nzRound:AddZombieType("HL2 Zombine", "nz_zombie_hl2_zombine", {
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
ENT.PrintName = "Zombine"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

ENT.DamageLow = 50
ENT.DamageHigh = 50
ENT.AttackRange = 65

ENT.NetworkOnTakeDamage = true -- We need to play (clientside) damaged sounds

ENT.BlockHardcodedSwingSound = true

ENT.PauseOnAttack = true

ENT.ZombineSounds = {
	["NewTarget"] = "Zombine.Alert",
	["Grenade"] = "Zombine.ReadyGrenade",
    ["Charge"] = "Zombine.Charge",
	["FootstepLeft"] = "Zombine.StrafeLeft",
	["FootstepRight"] = "Zombine.StrafeRight",
    ["Pain"] = "Zombine.Pain"
}

ENT.Models = {
    "models/zombie/zombie_soldier.mdl",
}

local AttackSequences = {
	{seq = "ACT_ZOMBINE_ATTACK_FAST", dmgtimes = {0.3}, dmg = 50},
	{seq = "ACT_ZOMBINE_ATTACK_FAST", dmgtimes = {0.3}, dmg = 50},
	{seq = "ACT_ZOMBINE_ATTACK_FAST", dmgtimes = {0.3}, dmg = 50},
	{seq = "ACT_ZOMBINE_ATTACK_FAST", dmgtimes = {0.3}, dmg = 50},
	{seq = "ACT_ZOMBINE_ATTACK_FAST", dmgtimes = {0.3}, dmg = 50},
	{seq = "ACT_MELEE_ATTACK1", dmgtimes = {0.8}, dmg = 100},
}

--ENT.AttackSounds = {
--	"Zombie.AttackHit",
--}

ENT.AttackMissSounds = {
	"Zombie.AttackMiss"
}

local JumpSequences = {
	{seq = "ACT_ZOMBINE_GRENADE_IDLE", speed = 15, time = 2.7},
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
	"ACT_IDLE",
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
	"Zombine.Die"
}

DEFINE_BASECLASS(ENT.Base)

AccessorFunc( ENT, "bFZRunning", "FZRunning", FORCE_BOOL)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")
	self:NetworkVar("Bool", 1, "HeadcrabDetached")

    BaseClass.SetupDataTables(self)
end

function ENT:OnSpawn()
	BaseClass.OnSpawn(self)
end

function ENT:PlayZombineSound(alias, sndlvl, loop)
	local snd = self.ZombineSounds[alias]
	if !snd then return end

	if loop then
		self:StartLoopingSound(snd)
	else
		self:EmitSound(snd, sndlvl)
	end
end

function ENT:StopZombineSound(alias)
	local snd = self.ZombineSounds[alias]
	if !snd then return end
	self:StopSound(snd)
end

function ENT:StopZombineSounds()
	for _,sound in pairs(self.ZombineSounds) do
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
			else
				self:SetFZRunning(false)
			end
		end)

		--Preselect the emerge sequnces for clientside use
		--self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
	end

	if CLIENT then
		self:SetRenderMode(RENDERMODE_TRANSADD)
		self:SetColor(Color(255,255,255,20))
	end
end

function ENT:SpecialInit()
	--make them invisible for a really short duration to blend the emerge sequences
	--self:SetNoDraw(true)
	--self:TimedEvent(0.1, function() -- Tiny delay just to make sure they are fully initialized
	--	self:TimedEvent( 0.5, function()
	--		self:SetNoDraw(false)
	--	end)

	--	local _, dur = self:LookupSequence(self.EmergeSequences[self:GetEmergeSequenceIndex()])
	--	dur = dur - (dur * self:GetCycle()) -- Subtract the time we are already thruogh the animation
	--end)
end

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)

	self:SetDropsHeadcrab(true)
	self:SetHeadcrabClass("nz_zombie_hl2_headcrab")

	self:SetLeapAtPlayers(false)

	local torso_mdl = "models/zombie/zombie_soldier_torso.mdl"
	local legs_mdl = "models/zombie/zombie_soldier_legs.mdl"
	self:SetTorsoModel(torso_mdl)
	self:SetLegsModel(legs_mdl)
	self.Gibs = {
		torso_mdl,
		legs_mdl
	}
end

function ENT:Zombine_Alert(target)
	self:PlayZombineSound("NewTarget")
end

function ENT:OnNewTarget(target)
	if self:GetEmerging() then return end
	self:Zombine_Alert(target)
end

function ENT:OnEmergeFinished()
	if IsValid(self:GetTarget()) then
		self:Zombine_Alert(self:GetTarget())
	end
end

function ENT:Attack(data, ...)
	BaseClass.Attack(self, data, ...)
end

function ENT:SoundThink()

end

function ENT:OnTakeDamage(dmginfo)
	if self:Health() <= 0 then return end

	if CLIENT then
	    self:PlayZombineSound("Pain")
    return end

	BaseClass.OnTakeDamage(self, dmginfo)
end

function ENT:OnKilled(dmgInfo)
	self:StopZombineSounds()

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
	self:StopZombineSounds()
end

function ENT:Zombine_Footstep()
	self:SetLastFootstepSound(CurTime())
	self.PlayedRightFootstep = !self.PlayedRightFootstep
	self:PlayZombineSound(self.PlayedRightFootstep and "FootstepLeft" or "FootstepRight")
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

	if self.CalcIdeal == ACT_WALK and CurTime() > self:GetLastFootstepSound() + 0.53 then
		self:Zombine_Footstep()
	end

	if self.CalcIdeal == ACT_RUN and CurTime() > self:GetLastFootstepSound() + 0.3 then
		self:Zombine_Footstep()
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
