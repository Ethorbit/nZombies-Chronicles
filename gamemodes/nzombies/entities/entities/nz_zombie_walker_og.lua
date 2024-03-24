AddCSLuaFile()

nzRound:AddZombieType("OG", "nz_zombie_walker_og", {
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

ENT.Base = "nz_zombiebase"
ENT.PrintName = "Walker"
ENT.Category = "Brainz"
ENT.Author = "Lolle"

DEFINE_BASECLASS(ENT.Base)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")
	BaseClass.SetupDataTables(self)
    --self:NetworkVar("Bool", 1, "Decapitated")
end

ENT.Models = {
	"models/nz_zombie/zombie_rerig_animated.mdl",
}

local AttackSequences = {
	{seq = "nz_stand_attack1", dmgtimes = {0.75, 1.25}},
	{seq = "nz_stand_attack2", dmgtimes = {0.3}},
	{seq = "nz_stand_attack3", dmgtimes = {0.8}},
	{seq = "nz_stand_attack4", dmgtimes = {0.4, 0.8}},
}
local WalkAttackSequences = {
	{seq = "nz_walk_attack1", dmgtimes = {0.3}},
	{seq = "nz_walk_attack2", dmgtimes = {0.4, 0.9}},
	{seq = "nz_walk_attack3", dmgtimes = {0.5}},
	{seq = "nz_walk_attack4", dmgtimes = {0.4, 0.75}},
}
local RunAttackSequences = {
	{seq = "nz_run_attack1", dmgtimes = {0.3}},
	{seq = "nz_run_attack2", dmgtimes = {0.3, 0.65}},
	{seq = "nz_run_attack3", dmgtimes = {0.3, 0.7}},
	{seq = "nz_run_attack4", dmgtimes = {0.3, 0.8}},
}
local AttackSounds = {
	"nz/zombies/attack/attack_00.wav",
	"nz/zombies/attack/attack_01.wav",
	"nz/zombies/attack/attack_02.wav",
	"nz/zombies/attack/attack_03.wav",
	"nz/zombies/attack/attack_04.wav",
	"nz/zombies/attack/attack_05.wav",
	"nz/zombies/attack/attack_06.wav",
	"nz/zombies/attack/attack_07.wav",
	"nz/zombies/attack/attack_08.wav",
	"nz/zombies/attack/attack_09.wav",
	"nz/zombies/attack/attack_10.wav",
	"nz/zombies/attack/attack_11.wav",
	"nz/zombies/attack/attack_12.wav",
	"nz/zombies/attack/attack_13.wav",
	"nz/zombies/attack/attack_14.wav",
	"nz/zombies/attack/attack_15.wav",
	"nz/zombies/attack/attack_16.wav",
	"nz/zombies/attack/attack_17.wav",
	"nz/zombies/attack/attack_18.wav",
	"nz/zombies/attack/attack_19.wav",
	"nz/zombies/attack/attack_20.wav",
	"nz/zombies/attack/attack_21.wav",
	"nz/zombies/attack/attack_22.wav",
}

local WalkSounds = {
	"nz/zombies/ambient/ambient_00.wav",
	"nz/zombies/ambient/ambient_01.wav",
	"nz/zombies/ambient/ambient_02.wav",
	"nz/zombies/ambient/ambient_03.wav",
	"nz/zombies/ambient/ambient_04.wav",
	"nz/zombies/ambient/ambient_05.wav",
	"nz/zombies/ambient/ambient_06.wav",
	"nz/zombies/ambient/ambient_07.wav",
	"nz/zombies/ambient/ambient_08.wav",
	"nz/zombies/ambient/ambient_09.wav",
	"nz/zombies/ambient/ambient_10.wav",
	"nz/zombies/ambient/ambient_11.wav",
	"nz/zombies/ambient/ambient_12.wav",
	"nz/zombies/ambient/ambient_13.wav",
	"nz/zombies/ambient/ambient_14.wav",
	"nz/zombies/ambient/ambient_15.wav",
	"nz/zombies/ambient/ambient_16.wav",
	"nz/zombies/ambient/ambient_17.wav",
	"nz/zombies/ambient/ambient_18.wav",
	"nz/zombies/ambient/ambient_19.wav",
	"nz/zombies/ambient/ambient_20.wav"
}

local RunSounds = {
	"nz/zombies/sprint2/sprint0.wav",
	"nz/zombies/sprint2/sprint1.wav",
	"nz/zombies/sprint2/sprint2.wav",
	"nz/zombies/sprint2/sprint3.wav",
	"nz/zombies/sprint2/sprint4.wav",
	"nz/zombies/sprint2/sprint5.wav",
	"nz/zombies/sprint2/sprint6.wav",
	"nz/zombies/sprint2/sprint7.wav",
	"nz/zombies/sprint2/sprint8.wav"
}

local JumpSequences = {
	{seq = "nz_barricade1", speed = 15, time = 2.7},
	{seq = "nz_barricade2", speed = 15, time = 2.4},
	{seq = "nz_barricade_fast1", speed = 15, time = 1.8},
	{seq = "nz_barricade_fast2", speed = 35, time = 4},
}
local SprintJumpSequences = {
	{seq = "nz_barricade_sprint1", speed = 50, time = 1.9},
	{seq = "nz_barricade_sprint2", speed = 35, time = 1.9},
}

ENT.ActStages = {
	[1] = {
		act = ACT_WALK,
		minspeed = 5,
		attackanims = WalkAttackSequences,
		-- no attackhitsounds, just use ENT.AttackHitSounds for all act stages
		sounds = WalkSounds,
		barricadejumps = JumpSequences,
	},
	[2] = {
		act = ACT_WALK_ANGRY,
		minspeed = 40,
		attackanims = WalkAttackSequences,
		sounds = WalkSounds,
		barricadejumps = JumpSequences,
	},
	[3] = {
		act = ACT_RUN,
		minspeed = 100,
		attackanims = RunAttackSequences,
		sounds = RunSounds,
		barricadejumps = SprintJumpSequences,
	},
	[4] = {
		act = ACT_SPRINT,
		minspeed = 160,
		attackanims = RunAttackSequences,
		sounds = RunSounds,
		barricadejumps = SprintJumpSequences,
	},
}

ENT.RedEyes = true

ENT.ElectrocutionSequences = {
	"nz_electrocuted1",
	"nz_electrocuted2",
	"nz_electrocuted3",
	"nz_electrocuted4",
	"nz_electrocuted5",
}
ENT.EmergeSequences = {
	"nz_emerge1",
	"nz_emerge2",
	"nz_emerge3",
	"nz_emerge4",
	"nz_emerge5",
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
	"nz/zombies/death/death_00.wav",
	"nz/zombies/death/death_01.wav",
	"nz/zombies/death/death_02.wav",
	"nz/zombies/death/death_03.wav",
	"nz/zombies/death/death_04.wav",
	"nz/zombies/death/death_05.wav",
	"nz/zombies/death/death_06.wav",
	"nz/zombies/death/death_07.wav",
	"nz/zombies/death/death_08.wav",
	"nz/zombies/death/death_09.wav",
	"nz/zombies/death/death_10.wav"
}

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
				self:SetRunSpeed( nzMisc.WeightedRandom(speeds) )
			else
				self:SetRunSpeed( 100 )
			end

			local hp = nzRound:GetZombieHealth() or 75
			self:SetHealth(hp)
			self:SetMaxHealth(hp)
		end

		--Preselect the emerge sequnces for clientside use
		self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
	end
end

function ENT:SpecialInit()
	-- if SERVER then
	-- 	self:TimedEvent(0.1, function()
	-- 		self:SetNoDraw(true)

	-- 		self:TimedEvent(0.15, function()
	-- 			self:SetNoDraw(false)
	-- 		end)
	-- 	end)
	-- end

	if CLIENT then
		--make them invisible for a really short duration to blend the emerge sequences
		self:TimedEvent(0.1, function() -- Tiny delay just to make sure they are fully initialized
			if string.find(self:GetSequenceName(self:GetSequence()), "nz_emerge") then
				self:SetNoDraw(true)
				self:TimedEvent( 0.15, function()
					self:SetNoDraw(false)
				end)

				self:SetRenderClipPlaneEnabled( true )
				self:SetRenderClipPlane(self:GetUp(), self:GetUp():Dot(self:GetPos()))

				--local _, dur = self:LookupSequence(self.EmergeSequences[self:GetEmergeSequenceIndex()])
				local _, dur = self:LookupSequence(self.EmergeSequences[self:GetEmergeSequenceIndex()])
				dur = dur - (dur * self:GetCycle()) -- Subtract the time we are already thruogh the animation
				-- The above is important if the zombie only appears in PVS mid-way through the animation

				self:TimedEvent( dur, function()
					self:SetRenderClipPlaneEnabled(false)
				end)
			end
		end)

	end
end

function ENT:OnSpawn()
	self:SetSubMaterial(2, "vgui/black.vtf")
	--self:SetModel("models/nzr/ascension_zombies.mdl")
	local seq = self.EmergeSequences[self:GetEmergeSequenceIndex()]
	local _, dur = self:LookupSequence(seq)


    self:MakeDust()
    
	-- play emerge animation on spawn
	-- if we have a coroutine else just spawn the zombie without emerging for now.
	if coroutine.running() then
		self:PlaySequenceAndWait(seq)
	end

	self:SetLastActive(CurTime())
end

function ENT:OnZombieDeath(dmgInfo)

	if dmgInfo:GetDamageType() == DMG_SHOCK then
		self:SetRunSpeed(0)
		self.loco:SetVelocity(Vector(0,0,0))
		self:Stop()
		local seq, dur = self:LookupSequence(self.ElectrocutionSequences[math.random(#self.ElectrocutionSequences)])
		self:ResetSequence(seq)
		self:SetCycle(0)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		-- Emit electrocution scream here when added
		timer.Simple(dur, function()
			if IsValid(self) then
			-- 	self:BecomeRagdoll(dmgInfo) -- It's causing crashes!
				self:Kill()
			end
		end)
	else
		self:EmitSound( self.DeathSounds[ math.random( #self.DeathSounds ) ], 100)
		self:BecomeRagdoll(dmgInfo)
	end

end
