if SERVER then
	local function getRoundInfiniteSpawnTimesFromDiff(diff)
		local spawn_times = {}

		spawn_times[1] = diff * 10 -- Spawn the first boss 10 zombies later for each round it was delayed with

		for i = 2,nzRound:GetBossCount() do
			local last_time = spawn_times[i - 1]
			spawn_times[i] = math.random(last_time, last_time + 5)
		end

		return spawn_times
	end

	function nzRound:SetNextBossRound( num )
		local round = self:GetNumber()
		if round == -1 then
			local diff = num - round
			if diff > 0 then -- If we're on infinity
				self.NextBossRound = round -- Mark this round again
                self:PrepareBoss(getRoundInfiniteSpawnTimesFromDiff(diff)) -- Spawn the boss 10 zombies later for each round it was delayed with
			end
		else 
			self.NextBossRound = num
		end
	end

	function nzRound:GetNextBossRound()
		return self.NextBossRound
	end

	function nzRound:IsBossRound()
		return self.bIsBossRound
	end

	function nzRound:SetIsBossRound(bool)
		self.bIsBossRound = bool
	end

	function nzRound:MarkedForBoss( num )
		return self.NextBossRound == num and self.BossType and self.BossData[self.BossType] and true -- Valid boss
	end

	function nzRound:SetBossCount(count)
		self.iBossCount = count
	end

	function nzRound:GetBossCount()
		return self.iBossCount or 0
	end

	function nzRound:GetBossesSpawned()
	       return self.iBossesSpawned or 0
	end

	function nzRound:SetBossesSpawned(num)
	       self.iBossesSpawned = num
	end

        function nzRound:GetBossRoundsElapsed()
	        return self.iBossRoundsElapsed or 0
	end

	function nzRound:SetBossRoundsElapsed(amount)
	        self.iBossRoundsElapsed = amount
	end

	function nzRound:SetBossType(id)
		if id == "None" then
			self.BossType = nil -- "None" makes a nil key
		else
			self.BossType = id or "Panzer" -- A nil id defaults to "Panzer", otherwise id
		end
	end

	function nzRound:GetBossType(id)
		return self.BossType
	end

	function nzRound:GetBossData(id)
		local bosstype = id or self.BossType
		return bosstype and self.BossData[bosstype] or nil
	end

    local firstSpawnAttemptRound = 0
    function nzRound:SpawnBoss(id, isRespawn, waitingForSpawner)
		if (!isRespawn and nzRound:GetBossesSpawned() >= nzRound:GetBossCount()) then return end -- Don't overspawn!

		if (!isRespawn and !waitingForSpawner) then 
			firstSpawnAttemptRound = nzRound:GetNumber() 
		end 
		
		if (waitingForSpawner and firstSpawnAttemptRound and nzRound:GetNumber() < firstSpawnAttemptRound) then return end -- The game has ended, stop trying to find a spawner..
        
	    local bosstype = id or self.BossType
		if bosstype then
			local data = nzRound:GetBossData(bosstype)
			--local spawnpoint = data.specialspawn and "nz_spawn_zombie_boss" or "nz_spawn_zombie_normal" -- Check what spawnpoint type we're using

			local spawnpoint = #ents.FindByClass("nz_spawn_zombie_boss") > 0 and "nz_spawn_zombie_boss" or nil
			if !spawnpoint then
				spawnpoint = #ents.FindByClass("nz_spawn_zombie_special") > 0 and "nz_spawn_zombie_special" or nil

				if !spawnpoint then
					spawnpoint = "nz_spawn_zombie_normal"
				end
			end

			local spawnpoints = {}
			for k,v in pairs(ents.FindByClass(spawnpoint)) do -- Find and add all valid spawnpoints that are opened and not blocked
				if (v.link == nil or nzDoors:IsLinkOpened( v.link )) and v:IsSuitable() then
					table.insert(spawnpoints, v)
				end
			end

			local spawn = spawnpoints[math.random(#spawnpoints)] -- Pick a random one
			if IsValid(spawn) then -- If we this exists, spawn here
				local boss = ents.Create(data.class)
				boss:SetPos(spawn:GetPos())
				boss:Spawn()

				if !isRespawn and IsValid(boss) then
					nzRound:SetBossesSpawned(nzRound:GetBossesSpawned() + 1)
				end

				boss.NZBossType = bosstype
				data.spawnfunc(boss) -- Call this after in case it runs PrepareBoss to enable another boss this round
				return boss
			else -- Keep trying, it NEEDS to spawn..
				if (#ents.FindByClass("nz_spawn_zombie_special") > 0 or #ents.FindByClass("nz_spawn_zombie_normal") > 0) then
					timer.Simple(1, function()
						nzRound:SpawnBoss(id, false, true)
					end)
				end
			end
		end
	end

	-- This runs at the start of every round
	hook.Add("OnRoundStart", "nzBossRoundHandler", function(round)	
        -- This is a universal emergency fallback, you should really avoid this from happening in your boss's spawner, so that you can control the next round.
        if round > 0 and (!nzRound:GetNextBossRound() or nzRound:GetNextBossRound() < nzRound:GetNumber()) then 
            nzRound:SetNextBossRound(round + math.random(3,5))
        return end
    
		if round == -1 then -- Round infinity always spawn bosses
			local diff = nzRound:GetNextBossRound() - round

			if diff > 0 then
				nzRound:SetNextBossRound(round) -- Mark this round again
				nzRound:PrepareBoss(getRoundInfiniteSpawnTimesFromDiff(diff)) -- Spawn the boss 10 zombies later for each round it was delayed with
			end
			return
		end

		if nzRound:MarkedForBoss(round) then -- If this round is a boss round
			if nzRound:IsSpecial() then nzRound:SetNextBossRound(round + 1) return end -- If special round, delay 1 more round and back out

			-- Support for more than 1 boss added by Ethorbit
			local spawntimes = {}

	  		for i = 1, nzRound:GetBossCount() + 10 do
		    	spawntimes[i] = math.random(1, math.Clamp((spawntimes[i - 1] or nzRound:GetZombiesMax()) - 2, 1, math.huge))
			end

			PrintTable(spawntimes)
			nzRound:PrepareBoss( spawntimes )
		end
	end)

	-- hook.Add("OnGameBegin", "nzBossFirst", function()

	-- end)

	-- This function spawns a boss in after this many zombies has spawned
	-- If called multiple times, the latter will overwrite the prior (because of hook names)
	function nzRound:PrepareBoss( spawntimes )
		local spawncount = 0

		hook.Add("OnZombieSpawned", "nzBossSpawnHandler", function(zombie) -- Add a hook for each zombie spawned
		    if zombie.NZBoss then return end

		    if !nzRound:MarkedForBoss(nzRound:GetNumber()) then
				hook.Remove("OnZombieSpawned", "nzBossSpawnHandler") -- Cancel if we're no longer on a boss round!
			return end

			spawncount = spawncount + 1 -- Add 1 more zombie spawned since we started tracking

			--print("BOSS: "..spawncount.."/"..spawntime)
			if spawncount >= (spawntimes[nzRound:GetBossesSpawned() + 1] or 1) then -- If we've spawned the amount of zombies that we randomly set
				local data = nzRound:GetBossData() -- Check if we got boss data
				if !data then hook.Remove("OnZombieSpawned", "nzBossSpawnHandler") return end -- If not, remove and cancel

				local boss = nzRound:SpawnBoss()

				if IsValid(boss) then
					if (nzRound:GetBossesSpawned() >= nzRound:GetBossCount()) then
					     hook.Remove("OnZombieSpawned", "nzBossSpawnHandler") -- Only remove the hook when we spawned all the bosses
					end
			    end
				-- If there is no valid spawnpoint to spawn at, it will try again next zombie that spawns
				-- until we get out of the boss round, then it gives up
			end
		end)
	end

	hook.Add( "OnGameBegin", "nzBossInit", function()
		nzRound:SetBossType(nzMapping.Settings.bosstype)

		local data = nzRound:GetBossData()
		if data then
			print("Calling boss spawner's init()")
            data.initfunc()
		end
	end)

	hook.Add( "OnBossKilled", "nzInfinityBossReengange", function(boss)
		boss.HasBeenDefeated = true -- This is so our EntityRemoved hook doesn't respawn it..

		local round = nzRound:GetNumber()
		if round == -1 then
			local diff = nzRound:GetNextBossRound() - round
			if diff > 0 then -- If a new round for the boss has been set after the first one died
				nzRound:SetNextBossRound(round) -- Mark this round again
				nzRound:PrepareBoss(getRoundInfiniteSpawnTimesFromDiff(diff))
			end
		end
	end)

	hook.Add("EntityRemoved", "NZBossFix", function(ent)
		if (nzRound) then
			if IsValid(ent) and ent.NZBoss and !ent.HasBeenDefeated then
				local bossType = ent.NZBossType

				-- So the boss got deleted, but its deathfunc wasn't ran, meaning it wasn't killed properly
				-- This is a HUGE issue, because if we don't do anything about this, then the boss will never
				-- spawn again for the remainder of the game, making it loads more easy.
				if (nzRound and !nzRound:InState(ROUND_GO) and !nzRound:InState(ROUND_CREATE) and (nzRound:GetNumber() > 0 or nzRound:GetNumber() == -1)) then -- and nzRound:GetNextBossRound() and nzRound:GetNextBossRound() <= nzRound:GetNumber()) then
			        bossType = bossType or nzRound.BossType
			        if (isstring(bossType)) then
						ServerLog(string.format("%s boss respawned.\n", bossType))
						nzRound:SpawnBoss(bossType, true)
					end
				end
			end
		end
	end)
end

nzRound.BossData = nzRound.BossData or {}
function nzRound:AddBossType(id, class, funcs)
	if SERVER then
		if class then
			local data = {}
			-- Which entity to spawn
			data.class = class
			-- Whether to spawn at special spawnpoints
			data.specialspawn = funcs.specialspawn
			-- Runs on game begin with this boss set, use to set first boss round
			data.initfunc = funcs.initfunc
			-- Run when the boss spawns, arguments are (boss)
			data.spawnfunc = funcs.spawnfunc
			-- Run when the boss dies, arguments are (boss, attacker, dmginfo, hitgroup)
			data.deathfunc = funcs.deathfunc
			-- Whenever the boss is damaged, arguments are (boss, attacker, dmginfo, hitgroup) Called before damage applied (can scale dmginfo)
			data.onhit = funcs.onhit
			-- All functions are optional, but death/spawn func is needed to set next boss round! (Unless you got another way)
			nzRound.BossData[id] = data
			nzConfig.ValidEnemies[class] = data
		else
			nzRound.BossData[id] = nil -- Remove it if no valid class was added
			nzConfig.ValidEnemies[class] = nil
		end
	else
		-- Clients only need it for the dropdown, no need to actually know the data and such
		nzRound.BossData[id] = class
	end
end

-- The code that registers valid bosses were moved to the top of the boss lua files themselves
-- This is because it makes it easier for the boss creators to keep track of everything
-- /Ethorbit
