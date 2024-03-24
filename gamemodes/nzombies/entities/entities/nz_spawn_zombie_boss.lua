AddCSLuaFile( )

ENT.Base = "nz_spawner_base"
ENT.PrintName = "Boss"

-- Ignore the commented code, this was going to store all boss logic, but it was decided
-- that the boss round file did an alright job handling the spawning.

-- Maybe this will change one day...

------ Add our boss types ----------------------------
-- nzRound:AddBossType("Panzer", "nz_zombie_boss_panzer")
------------------------------------------------------

ENT.NZOnlyVisibleInCreative = true

-- function ENT:OnReset()
-- 	self:SetBoss(nil)
-- 	self.spawncount = 0
-- 	self.spawntime = 0
-- end

function ENT:OnInitialize()
	self:SetModel("models/antlion_guard.mdl")
        --self:SetModel("models/zombie/poison.mdl")
        --self:SetModel("models/nz_zombie/zombie_panzersoldat.mdl")
	self:SetColor(Color(255, 0, 0)) 
        
	if CLIENT then
	--	-- Make smaller so it doesn't block too much vision
	  	local mat = Matrix()
		mat:Scale(Vector(0.75, 0.75, 0.75))
		self:EnableMatrix("RenderMultiply", mat)
	end	
end

-- function ENT:SetNextBossRound(num)
-- 	if num then
-- 		local round = nzRound:GetNumber()
		
-- 		if round == -1 then
-- 			local diff = num - round
-- 			if diff > 0 then -- If we're on infinity
-- 				self:SetNextBossRound(round) -- Mark this round again
-- 				self.spawntime = diff * 10 -- Spawn the boss 10 zombies later for each round it was delayed with
-- 			end
-- 		else
-- 			nzRound:SetNextBossRound(num)
-- 		end
-- 	return end

-- 	if (nzRound:GetBossRoundsElapsed() == 0) then
-- 		nzRound:SetNextBossRound(12)
-- 	else
-- 		nzRound:SetNextBossRound(nzRound:GetNumber() + 6)
-- 	end

-- 	-- We can't have boss round on dog round
-- 	if (nzRound:GetNextSpecialRound() == nzRound:GetNextBossRound()) then 
-- 		nzRound:SetNextBossRound(nzRound:GetNextBossRound() + 1)
-- 		self.spawntime = diff * 10
-- 	end
-- end

-- function ENT:OnGameBegin()
-- 	self:SetNextBossRound()
-- end

-- function ENT:SpawnBoss(id)
-- 	local bosstype = id or nzRound:GetBossType()
	
-- 	if bosstype then
-- 		local data = nzRound:GetBossData(bosstype)
-- 		--local spawnpoint = data.specialspawn and "nz_spawn_zombie_boss" or "nz_spawn_zombie_normal" -- Check what spawnpoint type we're using

-- 		local spawnpoint = #ents.FindByClass("nz_spawn_zombie_boss") > 0 and "nz_spawn_zombie_boss" or nil 
-- 		if !spawnpoint then
-- 			spawnpoint = #ents.FindByClass("nz_spawn_zombie_special") > 0 and "nz_spawn_zombie_special" or nil

-- 			if !spawnpoint then
-- 				spawnpoint = "nz_spawn_zombie_normal"
-- 			end
-- 		end
		
-- 		local spawnpoints = {}
-- 		for k,v in pairs(ents.FindByClass(spawnpoint)) do -- Find and add all valid spawnpoints that are opened and not blocked
-- 			if (v.link == nil or nzDoors:IsLinkOpened( v.link )) and v:IsSuitable() then
-- 				table.insert(spawnpoints, v)
-- 			end
-- 		end
		
-- 		local spawn = spawnpoints[math.random(#spawnpoints)] -- Pick a random one
-- 		if IsValid(spawn) then -- If we this exists, spawn here
-- 			local boss = ents.Create(data.class)
-- 			boss:SetPos(spawn:GetPos())
-- 			boss:Spawn()
-- 			boss.NZBossType = bosstype
-- 			data.spawnfunc(boss) -- Call this after in case it runs PrepareBoss to enable another boss this round
-- 			return boss
-- 		else -- Keep trying, it NEEDS to spawn..
-- 			if (#ents.FindByClass("nz_spawn_zombie_special") > 1 or #ents.FindByClass("nz_spawn_zombie_normal") > 1) then
-- 				timer.Simple(1, function()
-- 					nzRound:SpawnBoss(id)
-- 				end)
-- 			end
-- 		end
-- 	end
-- 	-- if self:CanActivate() then
-- 	-- 	self:SetSpawnerAmount(1)
-- 	-- 	self:SetActive(true)
-- 	-- end
-- end

-- function ENT:OnRoundStart(round_num) -- Spawn us if it's time
-- 	if self != self.Updater then return end

-- 	if nzRound:GetBossType() == "Panzer" then 
-- 		if round_num == -1 then -- Round infinity always spawns bosses
-- 			local diff = nzRound:GetNextBossRound() - round_num
-- 			if diff > 0 then
-- 				self:SetNextBossRound(round_num) -- Mark this round again
-- 				self.spawntime = diff * 10 -- Spawn the boss 10 zombies later for each round it was delayed with
-- 			end

-- 			return
-- 		end

-- 		if (nzRound:IsBossRound()) then			
-- 			if nzRound:IsSpecial() then -- If special round, delay 1 more round and back out (We don't spawn Panzers during those rounds)
-- 				self:SetNextBossRound(round_num + 1) 
-- 			return end

-- 			self.spawntime = math.random(1, nzRound:GetZombiesMax() - 2) -- Set a random time to spawn
-- 		end
-- 	end
-- end

-- function ENT:OnZombieSpawned(zombie, spawner, is_respawn) -- Round Infinity support
-- 	if self != self.Updater then return end
	
-- 	if nzRound:GetBossType() == "Panzer" then
-- 		if nzRound:GetNumber() != -1 then return end
-- 		if IsValid(self:GetBoss()) then return end
-- 		if !nzRound:MarkedForBoss(nzRound:GetNumber()) then return end
		
-- 		self.spawncount = self.spawncount + 1 -- Add 1 more zombie spawned since we started tracking
		
-- 		if self.spawncount >= self.spawntime then -- If we've spawned the amount of zombies that we randomly set	
-- 			self:SpawnBoss()
-- 		end
-- 	end
-- end

-- function ENT:OnBossKilled(boss, dmginfo)
-- 	if self != self.Updater then return end

-- 	if nzRound:GetBossType() == "Panzer" then
-- 		local attacker = dmginfo:GetAttacker()
-- 		if IsValid(attacker) and attacker:IsPlayer() and attacker:GetNotDowned() then
-- 			attacker:GivePoints(500) -- Give killer 500 points if not downed
-- 		end
	
-- 		local round = nzRound:GetNumber()
-- 		if round == -1 then
-- 			local diff = nzRound:GetNextBossRound() - round
			
-- 			if diff > 0 then -- If a new round for the boss has been set after the first one died
-- 				self:SetNextBossRound(round) -- Mark this round again
-- 				self.spawntime = diff * 10
-- 			end
-- 		end
-- 	end
-- end

-- function ENT:EntityRemoved(ent)
-- 	if self != self.Updater then return end

-- 	if nzRound:GetBossType() == "Panzer" then		
-- 		if IsValid(ent) and ent.NZBoss then
-- 			-- So the Panzer got deleted, but its deathfunc wasn't ran, meaning it wasn't killed properly
-- 			-- This is a HUGE issue, because if we don't do anything about this, then the Panzer will never
-- 			-- spawn again for the remainder of the game, making it loads more easy.
-- 			if (nzRound:GetNextBossRound() <= nzRound:GetNumber()) then 
-- 				self:SpawnBoss()
-- 			end
-- 		end
-- 	end
-- end

-- function ENT:GetBoss()
-- 	return self.hBossEnt
-- end

-- function ENT:SetBoss(boss)
-- 	self.hBossEnt = boss
-- end

-- function ENT:SpawnedEntity(boss) -- We spawned something
-- 	self:SetBoss(boss)
	
-- 	local hp = nzRound:GetPanzerHealth() or 500
-- 	boss:SetHealth(hp)
-- 	boss:SetMaxHealth(hp)
-- end
