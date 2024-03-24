-- this is the OG nova crawler which has been added back since the new one never worked.
-- PLEASE DO NOT OVERRIDE THIS WITH SOMETHING THAT DOESN'T WORK!

AddCSLuaFile()

nzConfig.AddValidEnemy("nz_zombie_special_nova", {
    Valid = true,
    ScaleDMG = function(zombie, hitgroup, dmginfo)
        if hitgroup == HITGROUP_HEAD then dmginfo:ScaleDamage(2) end
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

game.AddParticles("particles/n6_fx.pcf")
PrecacheParticleSystem("novagas_xplo")
PrecacheParticleSystem("novagas_trail")

ENT.Base = "nz_zombie_special_base"
ENT.PrintName = "Nova Crawler"
ENT.Category = "Brainz"
ENT.Author = "Ruko, Ethorbit"

DEFINE_BASECLASS(ENT.Base)

--ENT.Models = { "models/boz/killmeplease.mdl" }
ENT.Models = { "models/roach/bo1_overhaul/quadcrawler.mdl" }

ENT.AttackRange = 80
ENT.DamageLow = 30
ENT.DamageHigh = 45

ENT.IgnoreDistractions = false -- There's a lot of us, so let's allow distractions..

ENT.NovaWalkSpeed = 80
ENT.NovaRunSpeed = 90

ENT.AttackSequences = {
	{seq = "attack1"},
	{seq = "attack2"},
	{seq = "attack3"},
	{seq = "attack4"},
	{seq = "attack5"},
}

ENT.DeathSequences = {
	"death1",
}

ENT.AttackSounds = {
	"bo1_overhaul/n6/att.mp3"
}

ENT.AttackHitSounds = {
	"bo1_overhaul/nz/evt_zombie_hit_player_0.mp3"
}

ENT.WalkSounds = {
	"bo1_overhaul/n6/crawl.mp3"
}

ENT.PainSounds = {
	"physics/flesh/flesh_impact_bullet1.wav",
	"physics/flesh/flesh_impact_bullet2.wav",
	"physics/flesh/flesh_impact_bullet3.wav",
	"physics/flesh/flesh_impact_bullet4.wav",
	"physics/flesh/flesh_impact_bullet5.wav"
}

ENT.DeathSounds = {
	"bo1_overhaul/n6/die1.mp3",
	"bo1_overhaul/n6/die2.mp3",
	"bo1_overhaul/n6/die3.mp3",
	"bo1_overhaul/n6/die4.mp3"
}

ENT.SprintSounds = {
	"bo1_overhaul/n6/crawl1.mp3"
}

ENT.JumpSequences = {seq = ACT_JUMP, speed = 30}

ENT.ActStages = {
	[1] = {
		act = ACT_RUN,
		minspeed = 5,
	},
	[2] = {
		act = ACT_RUN,
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

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 5, "NovaRunning")
    self:NetworkVar("Bool", 6, "HasExploded")
	self:NetworkVar("Entity", 5, "NovaTarget")
    BaseClass.SetupDataTables(self)
end

function ENT:StatsInitialize()
	if SERVER then
	    self:SetHasExploded(false)

		if nzRound:GetNumber() == -1 then
			self:SetRunSpeed( math.random(60, 600) )
			self:SetHealth( math.random(200, 30000) )
		else
			local speeds = nzRound:GetZombieSpeeds()
			if speeds then
				self:SetRunSpeed( nzMisc.WeightedRandom(speeds) )
			else
				self:SetRunSpeed( 200 )
			end
			self:SetHealth( nzRound:GetZombieHealth() or 200 )
		end
	end

	--self:SetCollisionBounds(Vector(-16,-16, 0), Vector(40, 16, 45))
end

function ENT:OnSpawn()
	--self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- Don't collide in this state
	self:Stop() -- Also don't do anything

    self:MakeDust()

	self:SetNoDraw(true)
	self:SetInvulnerable(true)

	timer.Simple(1.4, function()
		if IsValid(self) then
			self:SetNoDraw(false)

			--self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:SetStop(false)

            util.SpriteTrail(self, 1, Color(0, 110, 0, 50), false, 80, 30, 1, 1 / (80 + 30) * 0.5, "trails/plasma")
            ParticleEffectAttach("novagas_trail", PATTACH_POINT_FOLLOW, self, 0)

			self:SetTarget(self:GetPriorityTarget())
			self:SetInvulnerable(nil)
			self:SetLastActive(CurTime())
		end
	end)

	nzRound:SetNextSpawnTime(CurTime() + 2) -- This one spawning delays others by 3 seconds
end

function ENT:OnZombieDeath(dmgInfo)
    local attacker = dmgInfo:GetAttacker()
    local inflictor = dmgInfo:GetInflictor()
    local is_knife = IsValid(inflictor) and nzSpecialWeapons and nzSpecialWeapons.Knives and nzSpecialWeapons.Knives[inflictor:GetClass()]

	if !is_knife and IsValid(attacker) and attacker:IsPlayer() and !self:GetHasExploded() then
        self:SetHasExploded(true)

        self:EmitSound("bo1_overhaul/n6/xplo"..math.random(2)..".mp3")

        timer.Simple(math.Rand(1, 2), function()
            ParticleEffect("novagas_xplo", self:GetPos(), Angle(0,0,0))

			for k,v in pairs(ents.FindInSphere(self:GetPos(),100)) do
				if v:IsPlayer() then
					v:SetDSP(34, false)

					local slow_walk = v:GetWalkSpeed("novagas")
					local slow_run = v:GetRunSpeed("novagas")

					if slow_walk and slow_run then
						v:SetRunSpeed(slow_run)
						v:SetWalkSpeed(slow_walk)
						v:SetStamina(10)
					end

					timer.Simple(1.2,function()
						if IsValid(v) then
							v:SetWalkSpeed(v:GetDefaultWalkSpeed())
							v:SetRunSpeed(v:GetDefaultRunSpeed())
						end
					end)
				end
			end

			self:SetNoDraw(true)

			-- Blast Damage
			for _,ent in pairs(ents.FindInSphere(self:GetPos(), 100)) do
				if IsValid(ent) and ent:IsPlayer() then
					if ent:GetNotDowned() and !ent:IsSpectating() then
						local explosion_dmg = DamageInfo()
						explosion_dmg:SetDamage(10)
						explosion_dmg:SetDamageType(DMG_NERVEGAS)
						explosion_dmg:SetAttacker(Entity(0))
						ent:TakeDamageInfo(explosion_dmg)
					end

					if ent.SetLastNovaGasTouch then
						ent:SetLastNovaGasTouch(CurTime())
					end
				end
			end

			-- Continuous Damage
			local pos = self:GetPos()
			timer.Create("NZNovaPoisonDamage" .. self:EntIndex(), 0.01, 600, function()
				if pos then
					for _,ent in pairs(ents.FindInSphere(pos, 100)) do
						if IsValid(ent) and ent:IsPlayer() then
							if ent:GetNotDowned() and !ent:IsSpectating() then
								local poison_dmg = DamageInfo()
								poison_dmg:SetDamage(0.1)
								poison_dmg:SetDamageType(DMG_NERVEGAS)
								poison_dmg:SetAttacker(Entity(0))
								ent:TakeDamageInfo(poison_dmg)
							end

							if ent.SetLastNovaGasTouch then
								ent:SetLastNovaGasTouch(CurTime())
							end
						end
					end
				end
			end)
        end)
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

function ENT:OnTakeDamage(dmginfo)
	if dmginfo then
		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()

		if (IsValid(attacker) and attacker:IsPlayer() and self:CanNovaTarget(attacker)) then
			self:SetNovaTarget(attacker)
		elseif (IsValid(inflictor) and inflictor:IsPlayer() and self:CanNovaTarget(inflictor)) then
			self:SetNovaTarget(inflictor)
		end
	end
end

function ENT:BodyUpdate()
	if !self:HasTarget() then
		self:SetNovaRunning(false)
	end

	if (self:GetNovaRunning()) then
		if (self:GetRunSpeed() != self.NovaRunSpeed) then
			self:SetRunSpeed(self.NovaRunSpeed)
			self.loco:SetDesiredSpeed(self.NovaRunSpeed)
		end
	else
		self:SetRunSpeed(self.NovaWalkSpeed)
		self.loco:SetDesiredSpeed(self.NovaWalkSpeed)

		if IsValid(self:GetTarget()) and self:GetTarget():GetTargetPriority() > 0 then -- Our dog hasn't started running yet, look for an enemy
			local dist = 155000 -- Measured in Timka's Kino Der Toten based off of DoorMatt's drawing for distance
			if (self:GetRangeSquaredTo(self:GetTarget():GetPos()) < dist) then -- ^ It's close enough to the player
				if (self:Visible(self:GetTarget())) then -- It can see the player
					if (!self.LastSpawnTime or CurTime() - self.LastSpawnTime > 2.1) then -- It's been a little since it spawned
						self:SetNovaTarget(self:GetTarget())
						self:SetNovaRunning(true)
						self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
					end
				end
			end
		end
	end

	local len2d = self:GetVelocity():Length2D()
	if len2d <= 0 then
		self.CalcIdeal = ACT_IDLE
	elseif len2d >= 50 then
		self.CalcIdeal = ACT_RUN
	elseif len2d <= 5 then
		self.CalcIdeal = ACT_WALK
	end

	--if ( len2d > 150 ) then self.CalcIdeal = ACT_RUN elseif ( len2d > 50 ) then self.CalcIdeal = ACT_RUN elseif ( len2d > 5 ) then self.CalcIdeal = ACT_WALK end


	if self:IsJumping() and self:WaterLevel() <= 0 then self.CalcIdeal = ACT_JUMP end

	if not self:GetSpecialAnimation() and not self:IsAttacking() then
		if self:GetActivity() ~= self.CalcIdeal and not self:GetStop() then self:StartActivity(self.CalcIdeal) end

		self:BodyMoveXY()
	end

	self:FrameAdvance()
end


function ENT:OnTargetInAttackRange()
    local atkData = {}
    atkData.dmglow = 30
    atkData.dmghigh = 45
    atkData.dmgforce = Vector( 0, 0, 0 )
	atkData.dmgdelay = 0.3
    self:Attack( atkData )
end

function ENT:CanNovaTarget(ply)
	return self:IsValidTarget(ply) and ply:GetNotDowned() and (!ply:IsSpectating() or ply:IsInCreative()) and !self:IsIgnoredTarget(ply)
end

-- Hellhounds target differently
function ENT:GetPriorityTarget()
	local previous_target = self:GetNovaTarget()

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
		if IsValid(target) then --and !self:IsIgnoredTarget(target) then
			if target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end

			if self:IsValidTarget(target) and !self:IsIgnoredTarget(target) then
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

	if (!IsValid(bestTarget)) then -- or !bestTarget:IsPlayer()) then -- We can't return nil or they break, resort to old target code..
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

		-- 	if (self:GetNovaRunning()) then
		-- 		self:SetNovaTarget(bestTarget)
		-- 	end

		-- 	return bestTarget
		-- else
		-- 	if (self:GetNovaRunning()) then
		-- 		self:SetNovaTarget(bestTarget)
		-- 	end

		-- 	print(bestTarget)
		-- 	return self:GetTarget()
		-- end
	end

    if IsValid(bestTarget) then
    --     local dist = self:GetRangeSquaredTo( bestTarget:GetPos() )
    --     if dist < 1000 then
    --         if !self.sprinting then
    --             self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
    --             self.sprinting = true
    --         end
    --     --    self:SetRunSpeed(270)
    --     --    self.loco:SetDesiredSpeed( self:GetRunSpeed() )
    --     --elseif !self.sprinting then
    --    --     self:SetRunSpeed(100)
    --    ---     self.loco:SetDesiredSpeed( self:GetRunSpeed() )
    --    -- end

		-- Make sure instead of switching player targets we continue going after our current one instead.
		if (bestTarget:IsPlayer() and IsValid(self:GetNovaTarget()) and self:GetNovaTarget():IsPlayer()) then
			if (self:CanNovaTarget(self:GetNovaTarget())) then
				return self:GetNovaTarget() -- Just go after our initial target
			end
		end
    end

    self:SetNovaTarget(bestTarget)

	return bestTarget
end

-- local glow =  Material( "nzr/nz/zlight" )
-- local gasColor = Color(0, 255, 0, 255)

-- function ENT:OnDraw()
--     cam.Start3D(self:GetPos(), self:GetAngles())
--     render.SetMaterial(glow)
--     render.DrawSprite(self:GetPos(), 114, 114, gasColor)
--     cam.End3D()
-- end

function ENT:OnNoTarget()
	self:TimeOut(0.1)
	self:SetNovaTarget(nil)
	self:SetTarget(self:GetPriorityTarget())
end
