AddCSLuaFile( )

ENT.Base = "nz_spawner_base"
ENT.PrintName = "Hellhound"
nzRound:AddSpecialRoundType("Hellhounds")

ENT.NZOnlyVisibleInCreative = true

function ENT:GetSpawnerData() -- A list of the enemies this spawns, and the chances for us to spawn them
	return {["nz_zombie_special_dog"] = {chance = 100}}
end

function ENT:OnReset()
	self.ZombiesTracked = 0
end

function ENT:OnInitialize()
	self:SetModel("models/nz_zombie/zombie_hellhound.mdl")
	self:SetColor(Color(255, 0, 0))
end

function ENT:SetNextSpecialRound()
	if self != self.Updater then return end
	if !nzMapping.Settings.enabledogs then return end
	if nzRound:GetSpecialRoundType() != "Hellhounds" then return end

	if (!nzMapping.Settings.autodogrounds) then
		nzRound:SetNextSpecialRound(nzRound:GetNumber() + math.random(nzMapping.Settings.dogroundminoffset, nzMapping.Settings.dogroundmaxoffset))
	return end

	if (nzRound:GetSpecialCount() == 0) then -- This is the first one
		nzRound:SetNextSpecialRound(nzRound:GetNumber() + math.random(5, 8))
	else
		nzRound:SetNextSpecialRound(nzRound:GetNumber() + math.random(4, 6))
	end
end

function ENT:AddMaxZombies()
	if !nzMapping.Settings.enabledogs then return end
	if self != self.Updater then return end

	if (nzRound:IsSpecial()) then
		if (nzRound:GetSpecialRoundType() == "Hellhounds") then
			if nzMapping.Settings.automaxdogs then
				-- Logic taken from BO1's source code
				if (nzRound:GetSpecialCount() < 3) then
					nzRound:SetZombiesMax(#player.GetAllPlaying() * 6)
				else
					nzRound:SetZombiesMax(#player.GetAllPlaying() * 8)
				end
			else -- Use user-defined maximum dogs:
				local extra_from_players = math.Clamp((#player.GetAllPlayingAndAlive() - 1) * nzMapping.Settings.dogsperplayer, 0, math.huge)
				nzRound:SetZombiesMax(nzMapping.Settings.maxdogs + extra_from_players)
			end
		end
	end
end

function ENT:DoSpawnChance()
	if !nzMapping.Settings.enabledogs then return end
	if self != self.Updater then return end

	-- We calculated it before-hand in OnRoundStart so that zombie respawns don't inflate
	-- the mixed dog amount well beyond what it was intended to be:
	self.ZombiesTracked = self.ZombiesTracked + 1

	local res = false
	if nzRound:GetNumber() == -1 then
		if nzRound:ShouldMixDogs() then
			res = math.random(100) < 3 --math.random(1, 3)
		end
	end

	if (res or (self.MixedZombies and self.MixedZombies[self.ZombiesTracked] != nil)) then
		self.MixedZombies[self.ZombiesTracked] = nil -- TotalZombies can fluctuate due to it keeping track of alive zombies too, so let's just rid this index now that we've used it (So it's not overused)

		if self:CanActivate() then
			nzRound:SetZombiesMax(nzRound:GetZombiesMax() + 1)
			self:SetSpawnerAmount(1)
			self:SetActive(true)
		end
	end
end

function ENT:OnRoundPreparation()
	if !nzMapping.Settings.enabledogs then return end

	if (nzRound:IsSpecial() or !nzRound:GetNextSpecialRound() or nzRound:GetNextSpecialRound() < nzRound:GetNumber()) then
		self:SetNextSpecialRound()
	end

	self.ZombiesTracked = 0
	self:AddMaxZombies()
end

function ENT:OnZombieSpawned(zombie, spawner, is_respawn) -- Every zombie spawn has a very low chance for a dog
	if !nzMapping.Settings.enabledogs then return end
	if (zombie:GetClass() == "nz_zombie_walker") then
		self:DoSpawnChance()
	end
end

function ENT:OnRoundStart(round_num) -- Begin spawning on special round
	if !nzMapping.Settings.enabledogs then return end
	if self != self.Updater then return end
	if (nzRound:IsSpecial() and nzRound:GetSpecialRoundType() == "Hellhounds") then
		timer.Simple(3, function()
			if !IsValid(self) then return end

			if (nzRound:GetSpecialRoundType() == "Hellhounds") then
				nzRound:CallHellhoundRound() -- Play the "Fetch me their souls" sound
				self:SetSpawnerAmount(nzRound:GetZombiesMax())
				self:SetActive(true)
			end
		end)
	return end

	-- Calculate how many dogs shall be mixed in per zombie count:
	self.MixedZombies = {}

	if nzRound:ShouldMixDogs() then
		if self == self.Updater then -- We obviously only want to archive the dog spawn chances ONCE.
			local num = math.Clamp(nzRound:GetZombiesMax(), 0, 5000) -- We limit this because we could lag out the server for extended periods of time in the loop below (and because how many dogs do we REALLY need??)

			for i = 1, num do
				local increased = false

				-- Logic based on BO1's Source Code:
				if (nzRound:GetNumber() > 30 and math.random(100) < 3) then
					increased = true
				elseif (nzRound:GetNumber() > 20 and math.random(100) < 2) then
					increased = true
				-- Fun fact: the cod devs actually did this in their games, and it doesn't even work.. math.random(100) CANNOT be under 1.
				-- elseif (nzRound:GetNumber() > 15 and math.random(100) < 1) then
				-- 	increased = true
				end

				if increased then
					self.MixedZombies[i] = 1
				end
			end
		end

		self:SetSpawnerAmount(0) -- We'll add to this as the zombies spawn
	end
end

function ENT:GetDelay()
	local delay = hook.Run("HellHoundSpawnDelay", self)
	if delay then return delay end

	--if nzRound:IsSpecial() then
		-- Matches BO1's source code
		local default_wait = 1.5

		if (nzRound:GetSpecialCount() + 1 == 1) then
			default_wait = 3
		elseif (nzRound:GetSpecialCount() + 1 == 2) then
			default_wait = 2.5
		elseif (nzRound:GetSpecialCount() + 1 == 3) then
			default_wait = 2
		else
			default_wait = 1.5
		end

		local spawn_delay = 1.4 -- (How long the dog spawn takes)
		local value = ((default_wait + spawn_delay) - (self:GetZombiesAlive() / self:GetSpawnerAmount()))
		local extra_players = #player.GetAllPlayingAndAlive() - 1

		local bo_delay = extra_players <= 0 and value or math.Clamp(value - (0.2 * extra_players), 0.5, value) -- or self:GetZombiesAlive() >= extra_players
	    local multiplier = (nzMapping.Settings.dogspawnspeedmult or 1)
		return (bo_delay / multiplier)
    --else
	--	return 0
	--end
end

function ENT:SpawnedEntity(dog) -- We spawned something
	local hp = nzRound:GetHellHoundHealth() or 220
	dog:SetHealth(hp)
	dog:SetMaxHealth(hp)
end
