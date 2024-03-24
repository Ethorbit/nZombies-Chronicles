if SERVER then
	function nzRound:SetNextSpecialRound(num)
		-- if (num == nil) then
		-- 	if (nzMapping.Settings.autodogrounds) then
		-- 		self.NextSpecialRound = self:GetNumber() + math.random(4, 6)
		-- 	else
		-- 		self.NextSpecialRound = self:GetNumber() + math.random(nzMapping.Settings.dogroundminoffset, nzMapping.Settings.dogroundmaxoffset)
		-- 	end
		-- else
			self.NextSpecialRound = num
		--end
	end

	function nzRound:GetNextSpecialRound()
		return self.NextSpecialRound
	end

	function nzRound:MarkedForSpecial( num )
		return ((self.NextSpecialRound == num and self.SpecialRoundType and self.SpecialData[self.SpecialRoundType] and true) or (nzConfig.RoundData[ num ] and nzConfig.RoundData[ num ].special)) or false
	end
	
	function nzRound:SetSpecialRoundType(id)
		if id == "None" then
			self.SpecialRoundType = nil -- "None" makes a nil key
		else
			self.SpecialRoundType = id or "Hellhounds" -- A nil id defaults to "Hellhounds", otherwise id
		end
	end
	
	function nzRound:GetSpecialRoundType()
		return self.SpecialRoundType
	end
	
	function nzRound:GetSpecialRoundData()
		if !self.SpecialRoundType then return nil end
		return self.SpecialData[self.SpecialRoundType]
	end

	function nzRound:SetSpecialCount(num) -- The amount of special rounds that have occurred
		self.SpecialCount = num
	end

	function nzRound:GetSpecialCount()
		return self.SpecialCount or 0
	end

	function nzRound:ShouldMixDogs()
		return nzMapping.Settings.mixdogs
	end

	util.AddNetworkString("nz_hellhoundround")
	function nzRound:CallHellhoundRound()
		net.Start("nz_hellhoundround")
			net.WriteBool(true)
		net.Broadcast()
	end
end

nzRound.SpecialData = nzRound.SpecialData or {}
function nzRound:AddSpecialRoundType(id)--, data, spawnfunc, roundfunc, endfunc)
	if SERVER then
		nzRound.SpecialData[id] = 1
		-- Zombie data, like those in the configuration files
		-- -- Optional spawn function, runs when a zombie spawns (can be used to set health, speed, etc)
		--if spawnfunc then nzRound.SpecialData[id].spawnfunc = spawnfunc end
		-- -- Optional round function, runs when the round starts (can be used to set amount, sounds, fog, etc)
		--if roundfunc then nzRound.SpecialData[id].roundfunc = roundfunc end
		-- Optional end function, runs when the special round ends (can be used to clean up changes)
		--if endfunc then nzRound.SpecialData[id].endfunc = endfunc end
	else
		-- Clients only need it for the dropdown, no need to actually know the data and such
		nzRound.SpecialData[id] = 1
	end
end

-- 	nzRound:AddSpecialRoundType("Hellhounds", {
-- 		specialTypes = {
-- 			["nz_zombie_special_dog"] = {chance = 100}
-- 		},
-- 		specialDelayMod = function() return math.Clamp(2 - #player.GetAllPlaying()*0.5, 0.5, 2) end, -- Dynamically change spawn speed depending on player count
-- 		specialCountMod = function() return nzRound:GetNumber() * #player.GetAllPlaying() end, -- Modify the count
-- 	}, function(dog) -- We want to modify health
-- 		local round = nzRound:GetNumber()
-- 		if round == -1 then
-- 			local hp = math.random(120, 1200)
-- 			dog:SetHealth(hp)
-- 			dog:SetMaxHealth(hp)
-- 		else
-- 			--dog:SetHealth(math.Clamp(round * 20, 120, 1200))
-- 			local hp = nzRound:GetHellHoundHealth() or 220
-- 			dog:SetHealth(hp)
-- 			dog:SetMaxHealth(hp)
-- 		end
-- 	end) -- No round func or end func

-- nzRound:AddSpecialRoundType("Burning Zombies", {
-- 	normalTypes = {
-- 		["nz_zombie_special_burning"] = {chance = 100}
-- 	},
-- 	normalDelay = 0.75,
-- 	normalCountMod = function(original) return original * 0.5 end, -- Half the normal count here
-- }) -- No special functions or anything really