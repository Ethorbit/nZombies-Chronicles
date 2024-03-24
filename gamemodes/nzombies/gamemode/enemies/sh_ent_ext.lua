TARGET_PRIORITY_NONE = 0
TARGET_PRIORITY_PLAYER = 1
TARGET_PRIORITY_SPECIAL = 2
TARGET_PRIORITY_MAX = 2
-- Someone could add a new priority level by doing this:
-- TARGET_PRIORITY_CUSTOM = TARGET_PRIORITY_MAX + 1
-- TARGET_PRIORITY_MAX = TARGET_PRIORITY_MAX + 1
-- would be limited to 7 custom levels before overwritting TARGET_PRIORITY_ALWAYS, which shoiuld be enough.
TARGET_PRIORITY_ALWAYS = 10 --make this entity a global target (not recommended)

--WARNING HTIS IS ONLY PARTIALLY SHARED its not recommended to use it clientside.

local meta = FindMetaTable("Entity")

function meta:SetIsZombie(value)
	self.bIsZombie = value
end

function meta:SetIsActivatable(value)
	self.bIsActivatable = value
end

function meta:IsActivatable()
	return self.bIsActivatable or false
end

function meta:GetTargetPriority()
	return self.iTargetPriority or TARGET_PRIORITY_NONE
end

function meta:SetTargetPriority(value)
	self.iTargetPriority = value
end

function meta:SetDefaultTargetPriority()
	if self:IsPlayer() then
		if self:Team() == TEAM_SPECTATOR then
			self:SetTargetPriority(TARGET_PRIORITY_NONE)
		elseif (self:IsInCreative() or (self:GetNotDowned() and self:IsPlaying())) then
			self:SetTargetPriority(TARGET_PRIORITY_PLAYER)
		else
			self:SetTargetPriority(TARGET_PRIORITY_NONE)
		end
	else
		self:SetTargetPriority(TARGET_PRIORITY_NONE) -- By default all entities are non-targetable
	end
end

if SERVER then
	function UpdateAllZombieTargets(target)
		if IsValid(target) then
			for k,v in pairs(ents.GetAll()) do
				if nzConfig.ValidEnemies[v:GetClass()] then
					v:SetTarget(target)
				end
			end
		end
	end

	function meta:ApplyWebFreeze(time)
		local block = false
		if self.Freeze then
			block = self:Freeze(time) -- Return true to not apply effect
		else
			self.loco:SetDesiredSpeed(0)
			timer.Simple(time, function()
				if IsValid(self) then
					self.WebAura = nil
					local speeds = nzRound:GetZombieSpeeds()
					if speeds then
						self.loco:SetDesiredSpeed( nzMisc.WeightedRandom(speeds) )
					else
						self.loco:SetDesiredSpeed( 100 )
					end
				end
			end)
		end

		if block then return end
		
		local e = EffectData()
		e:SetMagnitude(1.5)
		e:SetScale(time) -- The time the effect lasts
		e:SetEntity(self)
		util.Effect("web_aura", e)
		--self.WebAura = CurTime() + time
	end

	function meta:ApplySlowEffect(new_speed, time)
		self:SetRunSpeed(new_speed)
		self.loco:SetDesiredSpeed(new_speed)

		timer.Simple(time, function()
			if IsValid(self) and !self:GetFrozen() then
				local speeds = nzRound:GetZombieSpeeds()
				if speeds then
					local speed = nzMisc.WeightedRandom(speeds)
					self:SetRunSpeed(speed)
					self.loco:SetDesiredSpeed(speed)
				else
					self:SetRunSpeed(100)
					self.loco:SetDesiredSpeed( 100 )
				end
			end
		end)
	end
end

--local validenemies = {}
--function nzEnemies:AddValidZombieType(class)
--	validenemies[class] = true
--end

function meta:IsValidZombie()
    -- Improved by Ethorbit. I think it's safe to say if we registered a zombie for configs then it's a valid zombie..
    -- Moreover bIsZombie is already built into the zombiebase, so every zombie is automatically valid.
	return self.bIsZombie or nzConfig.ValidEnemies[self:GetClass()] --or validenemies[self:GetClass()] != nil
end

-- This is so silly, we do not need to do this anymore.
-- From now on if your zombie is registered or inherits from 
-- zombiebase (which it should always do), it will already be a "Valid Zombie Type"
-- /Ethorbit
--nzEnemies:AddValidZombieType("nz_zombie_walker")
--nzEnemies:AddValidZombieType("nz_zombie_walker_derriese_supersprint")
--nzEnemies:AddValidZombieType("nz_zombie_walker_tranzit")
--nzEnemies:AddValidZombieType("nz_zombie_walker_tranzit_supersprint")
--nzEnemies:AddValidZombieType("nz_zombie_walker_og")
--nzEnemies:AddValidZombieType("nz_zombie_special_burning")
--nzEnemies:AddValidZombieType("nz_zombie_special_dog")

function meta:ShouldPhysgunNoCollide()
	return self.bPhysgunNoCollide
end

local base = "nz_zombiebase"
--[[function nzEnemies:NZModNextbot(class, ignore)
	local bclass = scripted_ents.get(base)
	local tclass = scripted_ents.get(class)
	if not tclass or not bclass then return end
	
	local old = tclass.RunBehaviour
	tclass.RunBehaviour = function(self)
		
	end
	
	scripted_ents.Register(tclass, class)
end]]

if SERVER then
	local Path = FindMetaTable("PathFollower")

	-- Overwrite Update which moves the bot so that if it hits a barricade, it will attack it
	--local update = Path.Update
	--function Path:Update(bot)
	--	update(self, bot)
		
	--end

	-- Overwrite Compute so that it computes with nZombies pathfinding if a custom func is not given
	local compute = Path.Compute
	function Path:Compute(bot, to, func)
		compute(self, bot, to, func or function( area, fromArea, ladder, elevator, length )
			if ( !IsValid( fromArea ) ) then
				-- First area in path, no cost
				return 0
			else
				if ( !bot.loco:IsAreaTraversable( area ) ) then
					-- Our locomotor says we can't move here
					return -1
				end
				-- Prevent movement through either locked navareas or areas with closed doors
				if (nzNav.Locks[area:GetID()]) then
					if nzNav.Locks[area:GetID()].link then
						if !nzDoors:IsLinkOpened( nzNav.Locks[area:GetID()].link ) then
							bot:IgnoreTarget(bot:GetTarget())
							return -1
						end
					elseif nzNav.Locks[area:GetID()].locked then
					return -1 end
	
					if !nzNav.Locks[area:GetID()] then
					end
				end
				-- Compute distance traveled along path so far
				local dist = 0
				--[[if ( IsValid( ladder ) ) then
					dist = ladder:GetLength()
				elseif ( length > 0 ) then
					--optimization to avoid recomputing length
					dist = length
				else
					dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
				end]]--
				local cost = dist + fromArea:GetCostSoFar()
				--check height change
				local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
				if ( deltaZ >= bot.loco:GetStepHeight() ) then
					-- use player default max jump height even thouh teh zombie will jump a bit higher
					if ( deltaZ >= 64 ) then
						--Include ladders in pathing:
						--currently disableddue to the lack of a loco:Climb function
						--[[if IsValid( ladder ) then
							if ladder:GetTopForwardArea():GetID() == area:GetID() then
								return cost
							end
						end --]]
						--too high to reach
						return -1
					end
					--jumping is slower than flat ground
					local jumpPenalty = 1.1
					cost = cost + jumpPenalty * dist
				elseif ( deltaZ < -bot.loco:GetDeathDropHeight() ) then
					--too far to drop
					return -1
				end
				return cost
			end
		end)
	end
end
