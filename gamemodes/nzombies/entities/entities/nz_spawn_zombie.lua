-- Heavily modified by Ethorbit, merged everything from gamemode/enemies/sv_spawner.lua to here
-- and changed the spawning functionality to suit Black Ops better

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName		= "nz_spawn_zombie"

ENT.NZEntity = true
ENT.NZSpawner = true

ENT.bSpawnerActive = false

AccessorFunc(ENT, "tZombieData", "ZombieData")
AccessorFunc(ENT, "iZombiesToSpawn", "ZombiesToSpawn", FORCE_NUMBER)
AccessorFunc(ENT, "iZombiesSpawned", "ZombiesSpawned", FORCE_NUMBER)
AccessorFunc(ENT, "hSpawner", "Spawner")
AccessorFunc(ENT, "dNextSpawn", "NextSpawn", FORCE_NUMBER)

ENT.NZOnlyVisibleInCreative = true

function ENT:Reset()
	self:SetActive(false)
	self.bUnderSpawned = false
	self:SetSpawnQueue({})
	self:SetSpawners(ents.FindByClass(self:GetClass()))
	self:SetZombies({})
	self:SetZombiesToSpawn(0)
	self:SetZombiesSpawned(0)
	self:SetSpawnerAmount(0)
	self:SetNextSpawn(CurTime())
	self:SetUnlockedChild(false)
	self:UpdateUnlocked()
	self:OnReset()

	if SERVER then
		self:StopSpawnLoop()
	end
end

function ENT:Initialize()
	self:SetModel( "models/player/odessa.mdl" )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

	self:SetColor(Color(0, 255, 0))
	self:DrawShadow( false )

	self:Reset()
	self:OnInitialize()
end

function ENT:SpawnLoop(nodelay) -- Loops the zombie spawn functionality (Tried the ENT:Think() approach and it just would NOT stop spawning all of them at once no matter how I coded it, fuck you Gmod)
	local delay = self:GetDelay() > 0 and self:GetDelay() or 0.1
	if nodelay then delay = 0 end

	local alias = "SpawningZombies" .. self.Updater:EntIndex()
	timer.Remove(alias)
	timer.Create(alias, delay, 1, function()
		if IsValid(self) then
			self:Update()
			if (nzRound:GetZombiesKilled() + nzEnemies:TotalAlive()) + 1 > nzRound:GetZombiesMax() then self:SpawnLoop() return end -- Just don't even try to spawn more, we'd be overspawning..

			for _,spawner in pairs(self:GetSpawnQueue()) do -- Valid spawns are sorted by weight, so we want to loop through them in order
				self:ClearSpawnQueue()

				if nzRound:InState( ROUND_PROG ) then --and spawner:GetZombiesToSpawn() > 0 then
					local maxspawns = NZZombiesMaxAllowed != nil and NZZombiesMaxAllowed or 35
					local extraSpawns = 0
					if (#player.GetAllPlayingAndAlive() - 1 > 0) then
						local extraPerPlayer = nzMapping.Settings.spawnsperplayer
						if (isnumber(extraPerPlayer) and extraPerPlayer > 0) then
							extraSpawns = extraPerPlayer * (#player.GetAllPlayingAndAlive() - 1)
						end
					end

					if (maxspawns > nzRound:GetZombiesMax()) then
						maxspawns = nzRound:GetZombiesMax()
					end

					if CurTime() > spawner:GetNextSpawn() and nzEnemies:TotalAlive() < maxspawns + extraSpawns then --and nzEnemies:TotalAlive() < maxspawns + extraSpawns then -- GetConVar("nz_difficulty_max_zombies_alive"):GetInt()
						self.bUnderSpawned = false

						local is_respawn = self.iMarkedRespawns and self.iMarkedRespawns > 0
						local class = nzMisc.WeightedRandom(self:GetSpawnerData(), "chance")
						local zombie = ents.Create(class)
						zombie:SetPos(spawner:GetPos())
						zombie:Spawn()
						-- make a reference to the spawner object used for "respawning"
						zombie:SetSpawner(spawner)
						zombie:Activate()

						local zombies = self:GetZombies()
						zombies[#zombies + 1] = zombie
						self:SetZombies(zombies)

						self:SpawnedEntity(zombie)

						spawner:DecrementZombiesToSpawn()
						spawner:IncrementZombiesSpawned()

						hook.Call("OnZombieSpawned", nzEnemies, zombie, spawner, is_respawn )

						if is_respawn then
							self.iMarkedRespawns = self.iMarkedRespawns - 1
						end
					end
				end

				break
			end

			self:SpawnLoop()
		end
	end)
end

function ENT:Update()
	if CLIENT then return end
	if (self != self.Updater) then return end

	if (self:GetSpawnerAmount() > nzRound:GetZombiesMax()) then
		self:SetSpawnerAmount(nzRound:GetZombiesMax())
	end

	if self:GetSpawnerAmount() <= 0 then return end

	self:SetZombies(self:GetZombies())
	self.Spawners = ents.FindByClass(self:GetClass())

	----------------- Add valid spawns ---------------------------------------------------------------------------------------------------
	self.tValidSpawns = {}

	local any_suitable = false
	for _,spawn in pairs(self.Spawners) do
		if spawn:IsSuitable() and spawn:IsUnlocked() then
			any_suitable = true
			break
		end
	end

	if nzRound:GetSpawnRadius() > 0 then
		for _,spawn in pairs(self.Spawners) do
			if (!any_suitable or spawn:IsSuitable()) and spawn:IsUnlocked() then -- Added by Ethorbit, WHY WAS THIS NOT DONE BEFORE?! If we add when they are not suitable then it will slow down spawns as the spawners will wait until they ARE suitable, hogging a spawn that can be used somewhere else!!
				local close_enough_to_ply = false

				for _,v in pairs(player:GetAllPlayingAndAlive()) do
					if (v:GetPos():DistToSqr(spawn:GetPos()) < nzRound:GetSpawnRadius()^2) then
						close_enough_to_ply = true
						break
					end
				end

				if close_enough_to_ply then
					table.insert(self.tValidSpawns, spawn)
				end
			end
		end
	else -- Spawn radius is infinite (which typically means this is a tiny map), just pick random spawners at this point..
		local spawn = self.Spawners[math.random(#self.Spawners)]

		if spawn and (!any_suitable or spawn:IsSuitable()) and spawn:IsUnlocked() then
			table.insert(self.tValidSpawns, spawn)
		end
	end

	-- No spawners? Let's just choose the closest one to a random player (Otherwise there wouldn't be any zombies spawning!):
	if (#self.tValidSpawns == 0) then
		local players = player:GetAllPlayingAndAlive()
		local randPly = players[math.random(#players)]
		if IsValid(randPly) then
			local closest_spawner = nil
			local closest_spawner_dist = nil

			for _,spawn in pairs(self.Spawners) do
				if (!any_suitable or spawn:IsSuitable()) and spawn:IsUnlocked() then
					local dist = closest_spawner and closest_spawner:GetPos():DistToSqr(randPly:GetPos()) or spawn:GetPos():DistToSqr(randPly:GetPos())
					if (dist < (closest_spawner_dist or dist + 1)) then
						closest_spawner_dist = dist
						closest_spawner = spawn
					end
				end
			end

			if closest_spawner then
				table.insert(self.tValidSpawns, closest_spawner)
			end
		end
	end
	---------------------------------------------------------------------------------------------------------------------------------------

	-- Underspawn protection
	if !self:CanSpawnZombies() then
		if !self.bUnderSpawned and self:GetZombiesAlive() <= 0 then -- Uh oh, we're actually underspawning..
			self.bUnderSpawned = true
			hook.Run("OnZombieSpawnerUnderspawn", self)
		end
	return end

	local spawn = self.tValidSpawns[math.random(#self.tValidSpawns)] -- This is what it does in BO1 and BO2's source code, selects a random spawner
	self:AddToSpawnQueue(spawn)
end

function ENT:UpdateUnlocked()
	if self:IsUnlocked() and !self:HasUnlockedChild() then
		for spawner in pairs(self.Spawners) do
			self:SetUnlockedChild(true)
		end

		if self.Updater.SetUnlockedChild then
			self.Updater:SetUnlockedChild(true)
		end
	end
end

function ENT:OnDoorUnlocked() -- Hook
	self:UpdateUnlocked()
end

function ENT:IsUnlocked()
	return !self.link or self.link == "disabled" or nzDoors:IsLinkOpened(self.link)
end

function ENT:HasUnlockedChild()
	return self.bHasUnlockedChild
end

function ENT:SetUnlockedChild(bool)
	self.bHasUnlockedChild = bool
end

function ENT:StopSpawnLoop()
	local alias = "SpawningZombies" .. self.Updater:EntIndex()
	timer.Remove(alias)
end

function ENT:MarkNextZombieAsRespawned()
	for _,spawner in pairs(self.Spawners) do
		spawner.iMarkedRespawns = spawner.iMarkedRespawns and spawner.iMarkedRespawns + 1 or 1
	end
end

function ENT:IncrementZombiesToSpawn()
	self:SetZombiesToSpawn(self:GetZombiesToSpawn() + 1)
end

function ENT:DecrementZombiesToSpawn()
	self:SetZombiesToSpawn(self:GetZombiesToSpawn() - 1)
end

function ENT:IncrementZombiesSpawned()
	self:SetZombiesSpawned(self:GetZombiesSpawned() + 1)
end

function ENT:DecrementZombiesSpawned()
	self:SetZombiesSpawned(self:GetZombiesSpawned() - 1)
end

function ENT:SetZombies(zombies)
	if self != self.Updater and self.Updater.SetZombies then self.Updater:SetZombies(zombies) return end
	self.tZombies = {}

	for _,zombie in pairs(zombies) do -- Add all the zombies from the table that are still valid
		if (IsValid(zombie)) then
			self.tZombies[#self.tZombies + 1] = zombie
		end
	end
end

function ENT:GetZombies()
	if (self.Updater and self != self.Updater and self.Updater.GetZombies) then
		return self.Updater:GetZombies()
	end

	return self.tZombies
end

function ENT:GetSpawnQueue() -- Zombies awaiting to spawn
	return self.tSpawnQueue
end

function ENT:RemoveFromSpawnQueue(spawn)
	self.tSpawnQueue[spawn] = nil
end

function ENT:AddToSpawnQueue(spawn)
	if (spawn != nil) then
		self.tSpawnQueue[spawn] = spawn
	end
end

function ENT:SetSpawnQueue(spawn_queue)
	self.tSpawnQueue = spawn_queue
end

function ENT:ClearSpawnQueue()
	self.tSpawnQueue = {}
end

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "Link" )
	self:NetworkVar( "Bool", 0, "SpawnNearPlayers" )

	self:OnSetupDataTables()
end

function ENT:GetZombiesAlive() -- Total zombies that we spawned that are still alive
	if (self.Updater and self != self.Updater and self.Updater.GetZombiesAlive) then
		return self.Updater:GetZombiesAlive()
	end

	return #self:GetZombies()
end

function ENT:GetZombiesKilled() -- Total zombies made by this spawner that have been killed
	return nzRound:GetZombiesKilled(self:GetClass())
end

function ENT:GetTotalZombies() -- The total amount of zombies (dead & alive) created by this spawner
	return self:GetZombiesAlive() + self:GetZombiesKilled()
end

function ENT:OnNuke() -- Delay the spawning from nukes
    for _,spawner in pairs(self.Spawners) do
		if spawner.SetNextSpawn then
			spawner:SetNextSpawn( CurTime() + 6 )
		end
	end
end

function ENT:SetSpawnerData(spawndata)
	self.SpawnerData = spawndata
end

function ENT:SetSpawners(spawners)
	self.Spawners = spawners
	self.Updater = spawners[1]

	if (self == self.Updater) then
		self.tValidSpawns = {}
		self.tActiveSpawns = {}
	end
end

function ENT:GetSpawners()
	return self.Spawners
end

function ENT:OnSetupDataTables()
end

function ENT:IsSuitable()
	local tr = util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos(),
		filter = self,
		mins = Vector( -20, -20, 0 ),
		maxs = Vector( 20, 20, 70 ),
		ignoreworld = true,
		mask = MASK_NPCSOLID
	} )

	if (tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() or !tr.Hit) then -- Doesn't matter if they spawn inside players, collision will auto disable
		-- We are not allowed to spawn near players
		if (!self:GetSpawnNearPlayers()) then
			local entsInRadius = ents.FindInBox(self:GetPos() - Vector(400, 400, 400), self:GetPos() + Vector(400, 400, 400))
			for _,v in pairs(entsInRadius) do
				if (IsValid(v) and v:IsPlayer() and v:GetNotDowned() and !v:IsSpectating()) then
					--if (self:Visible(v)) then
						return false
					--end
				end
			end
		end

		-- We are allowed to spawn near players, so just spawn
		return true
	end

	return false
end

function ENT:GetValidSpawns()
	if (self.Updater and self != self.Updater) then
		return self.Updater:GetValidSpawns()
	end

	return self.tValidSpawns
end

function ENT:GetActiveSpawns()
	if (self.Updater and self != self.Updater) then
		return self.Updater:GetValidSpawns()
	end

	return self.tActiveSpawns or {}
end

function ENT:GetSpawnerAmount() -- The total that we are allowed to spawn
    return self.iSpawnerAmount or 0
end

function ENT:SetSpawnerAmount(num)
	if CLIENT then return end

	if self != self.Updater and self.Updater.SetSpawnerAmount then
        self.Updater:SetSpawnerAmount(num)
    return end

    self.iSpawnerAmount = self:GetTotalZombies() + num
	--hook.Run("OnZombieSpawnerAmountChanged", self, num)
end

function ENT:Think()
	self:OnThink()
end

function ENT:SetActive(bool) -- Starts/Stops spawning our enemies once zombies are allowed to spawn
	if CLIENT then return end
	if !self.Updater then return end

	self.bSpawnerActive = bool

	if bool then
		if self.Updater.tActiveSpawns then
			table.insert(self.Updater.tActiveSpawns, self)
		end

		self.Updater:SpawnLoop(true)
	else
		if self.Updater.tActiveSpawns then
			table.RemoveByValue(self.Updater.tActiveSpawns, self)
		end

		self:StopSpawnLoop()
	end
end

function ENT:CanActivate(ent)
	return tobool(self:HasUnlockedChild() or self:IsUnlocked()) --or #self.Updater:GetActiveSpawns() > 0)
end

function ENT:IsActive()
    return tobool(self.bSpawnerActive)
end

function ENT:CanSpawnZombies()
	if self != self.Updater then
		return self.Updater:CanSpawnZombies()
	end

	return (self:GetTotalZombies() < nzRound:GetZombiesMax() and self:GetTotalZombies() < self:GetSpawnerAmount())
end

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end
end
