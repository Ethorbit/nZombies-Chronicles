
function nzMapping:LoadMapSettings(data)
	if !data then return end

	if data.startwep then
		nzMapping.Settings.startwep = weapons.Get(data.startwep) and data.startwep or nzConfig.BaseStartingWeapons[1]
	end

	if data.knifeclass then
		nzMapping.Settings.knifeclass = weapons.Get(data.knifeclass) and data.knifeclass or "nz_quickknife_crowbar"
	end

	if data.nadeclass then
		nzMapping.Settings.nadeclass = weapons.Get(data.nadeclass) and data.nadeclass or "nz_grenade"
	end

	if data.startpoints then
		nzMapping.Settings.startpoints = tonumber(data.startpoints) or 500
	end
	if data.eeurl then
		nzMapping.Settings.eeurl = data.eeurl or nil
	end
	if data.script then
		nzMapping.Settings.script = data.script or nil
	end
	if data.scriptinfo then
		nzMapping.Settings.scriptinfo = data.scriptinfo or nil
	end

	local function AddBoxWeapons(boxWeps)
		if table.Count(boxWeps) > 0 then
			local tbl = {}
			for k,v in pairs(boxWeps) do
				local wep = weapons.Get(k)
				if wep and !wep.NZTotalBlacklist and !wep.NZPreventBox then -- Weapons are keys
					tbl[k] = tonumber(v) or 10 -- Set weight to value or 10
				else
					wep = weapons.Get(v) -- Weapons are values (old format)
					if wep and !wep.NZTotalBlacklist and !wep.NZPreventBox then
						tbl[v] = 10 -- Set weight to 10
					else
						print("[NZ INVALID] This weapon is invalid and has not been added to the box! - " .. k)
						-- -- No valid weapon on either key or value
						-- if tonumber(k) == nil then -- For every key that isn't a number (new format keys are classes)
						-- 	tbl[k] = 10
						-- end
						-- if tonumber(v) == nil then -- Or for every value that isn't a number (old format values are classes)
						-- 	tbl[v] = 10 -- Insert them anyway to make use of mismatch
						-- end
					end
				end
			end

			nzMapping.Settings.rboxweps = tbl
		else
			nzMapping.Settings.rboxweps = nil
		end
	end

	if data.boxpreset and file.Exists(data.boxpreset, "DATA") then
		local boxWeps = util.JSONToTable(file.Read(data.boxpreset))
		timer.Simple(0.1, function()
			if (istable(boxWeps)) then
				AddBoxWeapons(boxWeps)
				print("[nZ] Using Mystery Box preset: " .. data.boxpreset)
			else
				AddBoxWeapons(data.rboxweps)
			end
		end)
	else
		if data.rboxweps then
			AddBoxWeapons(data.rboxweps)
			-- if table.Count(data.rboxweps) > 0 then
			-- 	local tbl = {}
			-- 	for k,v in pairs(data.rboxweps) do
			-- 		local wep = weapons.Get(k)
			-- 		if wep and !wep.NZTotalBlacklist and !wep.NZPreventBox then -- Weapons are keys
			-- 			tbl[k] = tonumber(v) or 10 -- Set weight to value or 10
			-- 		else
			-- 			wep = weapons.Get(v) -- Weapons are values (old format)
			-- 			if wep and !wep.NZTotalBlacklist and !wep.NZPreventBox then
			-- 				tbl[v] = 10 -- Set weight to 10
			-- 			else
			-- 				-- No valid weapon on either key or value
			-- 				if tonumber(k) == nil then -- For every key that isn't a number (new format keys are classes)
			-- 					tbl[k] = 10
			-- 				end
			-- 				if tonumber(v) == nil then -- Or for every value that isn't a number (old format values are classes)
			-- 					tbl[v] = 10 -- Insert them anyway to make use of mismatch
			-- 				end
			-- 			end
			-- 		end
			-- 	end
			-- 	nzMapping.Settings.rboxweps = tbl
			-- else
			-- 	nzMapping.Settings.rboxweps = nil
			-- end
		end
	end

	-- DO NOT try to save Wunderfizz perks that aren't valid
	if data.wunderfizzperklist then
		for k,v in pairs(data.wunderfizzperklist) do
			if (!nzPerks.Data[k]) then
				data.wunderfizzperklist[k] = nil
				print("Removed invalid perk: " .. k)
			end
		end
	end
	nzMapping.Settings.wunderfizzperklist = data.wunderfizzperklist

	if data.poweruplist then
		for k,v in pairs(data.poweruplist) do
			if (!nzPowerUps.Data[k]) then
				data.poweruplist[k] = nil
				print("Removed invalid powerup: " .. k)
			end
		end
	end
	nzMapping.Settings.poweruplist = data.poweruplist

	if data.gamemodeentities then
		nzMapping.Settings.gamemodeentities = data.gamemodeentities or nil
	end

	nzMapping.Settings.zombiecollisions = data.zombiecollisions == nil and true or data.zombiecollisions

	-- Allow players to enable/disable zombie collisions realtime
	if (nzMapping.Settings.zombiecollisions != nil) then
		if (nzMapping.Settings.zombiecollisions == false) then
			for k,v in pairs(ents.GetAll()) do
				if (v:IsValidZombie()) then
					v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
				end
			end
		else
			for k,v in pairs(ents.GetAll()) do
				if (v:IsValidZombie()) then
					v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				end
			end
		end
	end

	if data.mapcategory then
		nzMapping.Settings.mapcategory = data.mapcategory or "Other"
	end
	if data.zombietype then
		nzMapping.Settings.zombietype = data.zombietype or "WaW"
	end
	if data.specialroundtype then
		nzMapping.Settings.specialroundtype = data.specialroundtype or "Hellhounds"
	end
	if data.bosstype then
		nzMapping.Settings.bosstype = data.bosstype or "Panzer"
	end

	nzMapping.Settings.zombietriggerkill = data.zombietriggerkill == nil and false or data.zombietriggerkill
	nzMapping.Settings.maxhealthround = data.maxhealthround == nil and 55 or data.maxhealthround
	nzMapping.Settings.maxzombiespeed = data.maxzombiespeed == nil and 200 or data.maxzombiespeed
	nzMapping.Settings.maxspeedround = data.maxspeedround == nil and 13 or data.maxspeedround
	nzMapping.Settings.startingspawns = data.startingspawns == nil and 24 or data.startingspawns
	nzMapping.Settings.spawnperround = data.spawnperround == nil and 0 or data.spawnperround
	nzMapping.Settings.maxspawns = data.maxspawns == nil and 24 or data.maxspawns

	nzMapping.Settings.enabledogs = data.enabledogs == nil and true or data.enabledogs
	nzMapping.Settings.automaxdogs = data.automaxdogs == nil and true or data.automaxdogs
	nzMapping.Settings.maxdogs = data.maxdogs == nil and 24 or data.maxdogs
	nzMapping.Settings.mixdogs = data.mixdogs == nil and true or data.mixdogs
	nzMapping.Settings.dogsperplayer = data.dogsperplayer == nil and 2 or data.dogsperplayer
	nzMapping.Settings.dogautorunspeed = data.dogautorunspeed == nil and true or data.dogautorunspeed
	nzMapping.Settings.dogmaxrunspeed = data.dogmaxrunspeed == nil and 200 or data.dogmaxrunspeed
	nzMapping.Settings.autodogrounds = data.autodogrounds == nil and true or data.autodogrounds
	nzMapping.Settings.dogroundminoffset = data.dogroundminoffset == nil and 6 or data.dogroundminoffset
	nzMapping.Settings.dogroundmaxoffset = data.dogroundmaxoffset == nil and 6 or data.dogroundmaxoffset
    nzMapping.Settings.dogspawnspeedmult = data.dogspawnspeedmult == nil and 1.4 or data.dogspawnspeedmult
    
	nzMapping.Settings.enablenovacrawlers = data.enablenovacrawlers == nil and true or data.enablenovacrawlers
	nzMapping.Settings.novacrawlerbatch = data.novacrawlerbatch == nil and 5 or data.novacrawlerbatch

	nzMapping.Settings.buildablesdrop = data.buildablesdrop == nil and true or data.buildablesdrop
	nzMapping.Settings.buildablesshare = data.buildablesshare == nil and false or data.buildablesshare
	nzMapping.Settings.buildablesmaxamount = data.buildablesmaxamount == nil and 1 or data.buildablesmaxamount
	nzMapping.Settings.buildablesforcerespawn = data.buildablesforcerespawn == nil and true or data.buildablesforcerespawn
	nzMapping.Settings.buildablesdisplayweppart = data.buildablesdisplayweppart == nil and false or data.buildablesdisplayweppart
	nzMapping.Settings.buildablesappearinbox = data.buildablesappearinbox == nil and false or data.buildablesappearinbox

	--nzMapping.Settings.zombiesperplayer = data.zombiesperplayer == nil and 0 or data.zombiesperplayer
	nzMapping.Settings.spawnsperplayer = data.spawnsperplayer == nil and 0 or data.spawnsperplayer
	NZZombiesMaxAllowed = nzMapping.Settings.startingspawns

	nzMapping.Settings.zombieeyecolor = data.zombieeyecolor == nil and Color(0, 255, 255, 255) or Color(data.zombieeyecolor.r, data.zombieeyecolor.g, data.zombieeyecolor.b)

    -- Forced on with no crouch jumping because NZR's defaults keep conflicting
    -- also after 30+ maps, there's never been one time where this needed to be changed.
	nzMapping.Settings.ac = true -- data.ac == nil and true or data.ac
	nzMapping.Settings.acwarn = data.acwarn == nil and true or data.acwarn
	nzMapping.Settings.acsavespot = data.acsavespot == nil and true or data.acsavespot
	nzMapping.Settings.acpreventboost = data.acpreventboost == nil and true or data.acpreventboost
	nzMapping.Settings.acpreventcjump = true -- data.acpreventcjump == nil and true or data.acpreventcjump
	nzMapping.Settings.actptime = data.actptime == nil and 5 or data.actptime
	nzMapping.Settings.modelpack = data.modelpack
	nzMapping.Settings.boxpreset = data.boxpreset

	-- More compact and less messy:
	for k,v in pairs(nzSounds.struct) do
		nzMapping.Settings[v] = data[v] or {}
	end

	nzMapping:SendMapData()
	nzSounds:RefreshSounds()

	timer.Simple(3, function()
		hook.Call("ConfigLoaded", nil, nil)
	end)
end
