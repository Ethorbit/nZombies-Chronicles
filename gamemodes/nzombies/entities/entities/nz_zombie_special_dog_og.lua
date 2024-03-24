AddCSLuaFile()

nzConfig.AddValidEnemy("nz_zombie_special_dog_og", {
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

ENT.Base = "nz_zombie_special_base"
ENT.PrintName = "Hellhound"
ENT.Category = "Brainz"
ENT.Author = "Lolle, Cryo, Ethorbit"

--ENT.Models = { "models/boz/killmeplease.mdl" }
ENT.Models = { "models/nz_zombie/zombie_hellhound.mdl" }

ENT.AttackRange = 80
ENT.DamageLow = 40
ENT.DamageHigh = 40

ENT.DogWalkSpeed = 130
ENT.DogRunSpeed = 260 -- 230

ENT.PauseOnAttack = false

DEFINE_BASECLASS(ENT.Base)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 5, "DogRunning")
	self:NetworkVar("Entity", 5, "DogTarget")
	BaseClass.SetupDataTables(self)
end

ENT.AttackSequences = {
	{seq = "nz_attack1"},
	{seq = "nz_attack2"},
	{seq = "nz_attack3"},
}

ENT.DeathSequences = {
	"nz_death1",
	"nz_death2",
	"nz_death3",
}

ENT.AttackSounds = {
	"nz/hellhound/attack/attack_00.wav",
	"nz/hellhound/attack/attack_01.wav",
	"nz/hellhound/attack/attack_02.wav",
	"nz/hellhound/attack/attack_03.wav",
	"nz/hellhound/attack/attack_04.wav",
	"nz/hellhound/attack/attack_05.wav",
	"nz/hellhound/attack/attack_06.wav"
}

ENT.AttackHitSounds = {
	"nz/hellhound/bite/bite_00.wav",
	"nz/hellhound/bite/bite_01.wav",
	"nz/hellhound/bite/bite_02.wav",
	"nz/hellhound/bite/bite_03.wav",
}

ENT.WalkSounds = {
	"nz/hellhound/dist_vox_a/dist_vox_a_00.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_01.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_02.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_03.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_04.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_05.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_06.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_07.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_08.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_09.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_10.wav",
	"nz/hellhound/dist_vox_a/dist_vox_a_11.wav"
}

ENT.PainSounds = {
	"physics/flesh/flesh_impact_bullet1.wav",
	"physics/flesh/flesh_impact_bullet2.wav",
	"physics/flesh/flesh_impact_bullet3.wav",
	"physics/flesh/flesh_impact_bullet4.wav",
	"physics/flesh/flesh_impact_bullet5.wav"
}

ENT.DeathSounds = {
	"nz/hellhound/death2/death0.wav",
	"nz/hellhound/death2/death1.wav",
	"nz/hellhound/death2/death2.wav",
	"nz/hellhound/death2/death3.wav",
	"nz/hellhound/death2/death4.wav",
	"nz/hellhound/death2/death5.wav",
	"nz/hellhound/death2/death6.wav",
}

ENT.SprintSounds = {
	"nz/hellhound/close/close_00.wav",
	"nz/hellhound/close/close_01.wav",
	"nz/hellhound/close/close_02.wav",
	"nz/hellhound/close/close_03.wav",
}

ENT.JumpSequences = {seq = ACT_JUMP, speed = 30}

ENT.ActStages = {
	[1] = {
		act = ACT_WALK,
		minspeed = 5,
	},
	[2] = {
		act = ACT_WALK_ANGRY,
		minspeed = 50,
	},
	[3] = {
		act = ACT_RUN,
		minspeed = 150,
	},
	[4] = {
		act = ACT_RUN,
		minspeed = 160,
	},
}

function ENT:StatsInitialize()
	if (!nzMapping.Settings.dogautorunspeed) then
		self.DogRunSpeed = nzMapping.Settings.dogmaxrunspeed
	end

	if SERVER then
		local hp = nzRound:GetHellHoundHealth() or 220
		self:SetHealth(hp)
		self:SetMaxHealth(hp)
		self:SetNoDraw(true)

		self:SetCollisionBounds(Vector(-14,-14, 0), Vector(14, 14, 48))
	end

	self:SetSolid(SOLID_BBOX)
end

function ENT:OnTraceAttack( dmginfo, dir, trace ) -- We keep this blank because we don't want any hitbox damage multipliers for dogs
end

function ENT:OnTakeDamage(dmginfo)
	if !self:GetDogRunning() and dmginfo then
		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()

		if (IsValid(attacker) and attacker:IsPlayer() and self:CanDogTarget(attacker)) then
			self:SetDogTarget(attacker)
			self:SetDogRunning(true)
			self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
		elseif (IsValid(inflictor) and inflictor:IsPlayer() and self:CanDogTarget(inflictor)) then
			self:SetDogTarget(inflictor)
			self:SetDogRunning(true)
			self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
		end
	end
end

function ENT:OnSpawn()
	--self:SetNoDraw(true) -- Start off invisible while in the prespawn effect
	self:Stop() -- Also don't do anything
	self.AliveTime = CurTime()
	local effectData = EffectData()
	effectData:SetOrigin( self:GetPos() )
	effectData:SetMagnitude( 2 )
	effectData:SetEntity(nil)
	util.Effect("lightning_prespawn", effectData)
	self:SetNoDraw(true)
	self:SetInvulnerable(true)

	timer.Simple(1.4, function()
		if IsValid(self) then
			self:SetStop(false)
			self:SetNoDraw(false)

			effectData = EffectData()
			-- startpos
			effectData:SetStart( self:GetPos() + Vector(0, 0, 1000) )
			-- end pos
			effectData:SetOrigin( self:GetPos() )
			-- duration
			effectData:SetMagnitude( 0.75 )
			--util.Effect("lightning_strike", effectData)
			util.Effect("lightning_strike", effectData)

			self:SetTarget(self:GetPriorityTarget())
			self:SetInvulnerable(nil)
			self:SetLastActive(CurTime())

			self.FireHound = (math.Round(util.SharedRandom("FireHound" .. self:EntIndex(), 1, 3)) == 2)

			if (self.FireHound) then
				self.FireEffect = true

				if SERVER then
					util.SpriteTrail(self, 0, Color(255, 255, 0, 255), false, 40, 0, 0.3, 1 / 40 * 0.3, "trails/plasma")
				end

				ParticleEffectAttach("env_fire_tiny", 1, self, 0)
			end
		end
	end)
end

function ENT:OnZombieDeath(dmgInfo)
	if (SERVER) then
		if (self.FireHound and !self.exploded) then
			self.exploded = true
			local explodeme = ents.Create("env_explosion")
			explodeme:SetPos(self:GetPos())
			explodeme:Spawn()
			explodeme:SetKeyValue("iMagnitude", 70)
			explodeme:SetKeyValue("iRadius", 240)
			explodeme:SetOwner(self)
			explodeme:Fire( "Explode", 0, 0 )
		end
	end

	self:SetRunSpeed(0)
	self.loco:SetVelocity(Vector(0,0,0))
	self:Stop()
	local seqstr = self.DeathSequences[math.random(#self.DeathSequences)]
	local seq, dur = self:LookupSequence(seqstr)
	-- Delay it slightly; Seems to fix it instantly getting overwritten
	timer.Simple(0, function()
		if IsValid(self) then
			self:ResetSequence(seq)
			self:SetCycle(0)
			self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		end
	end)

	timer.Simple(dur + 1, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
	self:EmitSound( self.DeathSounds[ math.random( #self.DeathSounds ) ], 100)
end

function ENT:BodyUpdate()
	if !self:HasTarget() then
		self:SetDogRunning(false)
	end

	if (self:GetDogRunning()) then
		if (self:GetRunSpeed() != self.DogRunSpeed) then
			self:SetRunSpeed(self.DogRunSpeed)
			self.loco:SetDesiredSpeed(self.DogRunSpeed)
		end
	else
		self:SetRunSpeed(self.DogWalkSpeed)
		self.loco:SetDesiredSpeed(self.DogWalkSpeed)

		if IsValid(self:GetTarget()) and self:GetTarget():GetTargetPriority() > 0 then -- Our dog hasn't started running yet, look for an enemy
			local dist = 329233.1041707 -- Measured in Timka's Kino Der Toten based off of DoorMatt's drawing for distance
			if (self:GetRangeSquaredTo(self:GetTarget():GetPos()) < dist) then -- ^ It's close enough to the player
				if (self:Visible(self:GetTarget())) then -- It can see the player
					if (!self.LastSpawnTime or CurTime() - self.LastSpawnTime > 2.1) then -- It's been a little since it spawned
						self:SetDogTarget(self:GetTarget())
						self:SetDogRunning(true)
						self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
					end
				end
			end
		end
	end

	local len2d = self:GetVelocity():Length2D()

	if len2d <= 0 then self.CalcIdeal = ACT_IDLE
	elseif self:GetDogRunning() then self.CalcIdeal = ACT_RUN
	elseif len2d > 50 then self.CalcIdeal = ACT_WALK_ANGRY
	elseif len2d > 5 then self.CalcIdeal = ACT_WALK end

	if self:IsJumping() and self:WaterLevel() <= 0 then self.CalcIdeal = ACT_JUMP end

	if not self:GetSpecialAnimation() and not self:IsAttacking() then
		if self:GetActivity() ~= self.CalcIdeal and not self:GetStop() then self:StartActivity(self.CalcIdeal) end

		self:BodyMoveXY()
	end

	self:FrameAdvance()
end

function ENT:OnTargetInAttackRange()
	if (self:Health() > 0) then
		local atkData = {}
		atkData.dmglow = 40
		atkData.dmghigh = 40
		atkData.dmgforce = Vector( 0, 0, 0 )
		atkData.dmgdelay = 0.3
		self:Attack( atkData )
		self:TimeOut(0.4)
	end

	-- self:SetStop(true)
	-- timer.Simple(0.13, function()
	-- 	self:SetStop(false)
	-- end)
end

function ENT:OnNoTarget()
	self:IgnoreTarget(self:GetTarget())
    self:TimeOut(0.1)
	self:SetDogTarget(nil)
    local newtarget = self:GetPriorityTarget()
	if self:IsValidTarget(newtarget) then
		self:SetTarget(newtarget)
    end
	--self:SetTarget(self:GetPriorityTarget())
end

function ENT:CanDogTarget(ply)
	if !IsValid(ply) or !ply:IsPlayer() then return false end -- We only attack players.
    return self:IsValidTarget(ply) and (!ply:IsSpectating() or ply:IsInCreative()) and !self:IsIgnoredTarget(ply)
end

-- Hellhounds target differently
function ENT:GetPriorityTarget()
	if (IsValid(self:GetDogTarget()) and self:CanDogTarget(self:GetDogTarget())) then	
		return self:GetDogTarget() -- Just go after our initial target

		-- if (self:IsValidTarget(self:GetDogTarget()) and self:GetDogTarget():GetNotDowned() and (!self:GetDogTarget():IsSpectating() or self:GetDogTarget():IsInCreative()) and !self:IsIgnoredTarget(self:GetDogTarget())) then
		-- 	return self:GetDogTarget() -- Just go after our initial target
		-- end
	end

	if self:Health() <= 0 then return end
	self:SetLastTargetCheck( CurTime() )

	--if you really would want something that atracts the zombies from everywhere you would need something like this
	local allEnts = ents.GetAll()
	--[[for _, ent in pairs(allEnts) do
		if ent:GetTargetPriority() == TARGET_PRIORITY_ALWAYS and self:IsValidTarget(ent) then
			return ent
		end
	end]]

	-- Disabled the above for for now since it just might be better to use that same loop for everything

	local bestTarget = nil
	local highestPriority = TARGET_PRIORITY_NONE
	local maxdistsqr = self:GetTargetCheckRange()^2
	local targetDist = maxdistsqr + 10

	--local possibleTargets = ents.FindInSphere( self:GetPos(), self:GetTargetCheckRange())
	for _, target in pairs(allEnts) do
		if self:IsValidTarget(target) and !self:IsIgnoredTarget(target) then
			if target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end

			local dist = self:GetRangeSquaredTo( target:GetPos() )
			if maxdistsqr <= 0 or dist <= maxdistsqr then -- 0 distance is no distance restrictions
				local priority = target:GetTargetPriority()
				if target:GetTargetPriority() > highestPriority then
					highestPriority = priority
					bestTarget = target
					targetDist = dist
				elseif target:GetTargetPriority() == highestPriority then
					if targetDist > dist then
						highestPriority = priority
						bestTarget = target
						targetDist = dist
					end
				end
				--print(highestPriority, bestTarget, targetDist, maxdistsqr)
			end
		end
	end

	if self:IsValidTarget(bestTarget) then -- If we found a valid target
		-- local targetDist = self:GetRangeSquaredTo( bestTarget:GetPos() )
		-- if targetDist < 1000 then -- Under this distance, we will break into sprint
		-- 	self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
		-- 	self.sprinting = true -- Once sprinting, you won't stop
		-- 	self:SetRunSpeed(250)
		-- else -- Otherwise we'll just search (towards him)
		-- 	self:SetRunSpeed(100)
		-- 	self.sprinting = nil
		-- end
		-- self.loco:SetDesiredSpeed( self:GetRunSpeed() )

		-- Apply the new target numbers
		bestTarget.hellhoundtarget = bestTarget.hellhoundtarget and bestTarget.hellhoundtarget + 1 or 1
	end

	if (!IsValid(bestTarget) or !bestTarget:IsPlayer()) then -- We can't return nil or they break, resort to old target code..
		-- Otherwise, we just loop through all to try and target again
		local allEnts = ents.GetAll()

		local bestTarget = nil
		local lowest

		--local possibleTargets = ents.FindInSphere( self:GetPos(), self:GetTargetCheckRange())

		for _, target in pairs(allEnts) do
			if self:IsValidTarget(target) then
				if target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end
				if !lowest then
					lowest = target.hellhoundtarget -- Set the lowest variable if not yet
					bestTarget = target -- Also mark this for the best target so he isn't ignored
				end

				if lowest and (!target.hellhoundtarget or target.hellhoundtarget < lowest) then -- If the variable exists and this player is lower than that amount
					bestTarget = target -- Mark him for the potential target
					lowest = target.hellhoundtarget or 0 -- And set the new lowest to continue the loop with
				end

				if !lowest then -- If no players had any target values (lowest was never set, first ever hellhound)
					local players = player.GetAllTargetable()
					bestTarget = players[math.random(#players)] -- Then pick a random player
				end
			end
		end

		-- if self:IsValidTarget(bestTarget) then -- If we found a valid target
		-- 	-- local targetDist = self:GetRangeSquaredTo( bestTarget:GetPos() )
		-- 	-- if targetDist < 1000 then -- Under this distance, we will break into sprint
		-- 	-- 	self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
		-- 	-- 	self.sprinting = true -- Once sprinting, you won't stop
		-- 	-- 	self:SetRunSpeed(250)
		-- 	-- else -- Otherwise we'll just search (towards him)
		-- 	-- 	self:SetRunSpeed(100)
		-- 	-- 	self.sprinting = nil
		-- 	-- end
		-- 	--self.loco:SetDesiredSpeed( self:GetRunSpeed() )

		-- 	-- Apply the new target numbers
		-- 	bestTarget.hellhoundtarget = bestTarget.hellhoundtarget and bestTarget.hellhoundtarget + 1 or 1
		-- 	self:SetTarget(bestTarget) -- Well we found a target, we kinda have to force it

		-- 	if (self:GetDogRunning()) then
		-- 		self:SetDogTarget(bestTarget)
		-- 	end

		-- 	return bestTarget
		-- else
		-- 	if (self:GetDogRunning()) then
		-- 		self:SetDogTarget(bestTarget)
		-- 	end

		-- 	print(bestTarget)
		-- 	return self:GetTarget()
		-- end
	end

	if (self:GetDogRunning()) then
		self:SetDogTarget(bestTarget)
	end

	return bestTarget
end
