local meleetypes = {
	[DMG_CLUB] = true,
	[DMG_SLASH] = true,
	[DMG_CRUSH] = true,
}

local function ZombieKillPoints(zombie, dmginfo, hitgroup)
	local attacker = dmginfo:GetAttacker()
	if zombie:IsValidZombie() and !zombie.givenpoints then
		if attacker:IsPlayer() and attacker:GetNotDowned() then
			if (attacker.lastKill and zombie == attacker.lastKill) then return end
			attacker.lastKill = zombie

			if (!zombie.ForceKilled and !attacker.lastKillTime or attacker.lastKillTime and CurTime() > attacker.lastKillTime) then
                zombie.givenpoints = true

                --attacker.lastKillTime = CurTime() + 0.01
				if meleetypes[dmginfo:GetDamageType()] then
					attacker:GivePoints(130)
				elseif hitgroup == HITGROUP_HEAD then
					attacker:GivePoints(100)
				else
					attacker:GivePoints(50)
				end


				--if (IsValid(attacker:GetActiveWeapon())) then
					--if (attacker:GetActiveWeapon():GetClass() == "tfa_paralyzer"
					--|| attacker:GetActiveWeapon():GetClass() == "tfa_jetgun") then
					--	attacker.lastKillTime = CurTime() + 0.5
					--end
				--end
			end
		end
	end
end

function nzEnemies:OnEnemyKilled(enemy, attacker, dmginfo, hitgroup)
	--  Prevent multiple "dyings" by making sure the zombie has not already been "killed"
	if enemy.MarkedForDeath then return end

	if attacker:IsPlayer() then
		--attacker:GivePoints(90)
		attacker:AddFrags(1)
		if attacker:HasPerk("vulture") then
			if math.random(10) == 1 then
				local drop = ents.Create("drop_vulture")
				drop:SetPos(enemy:GetPos() + Vector(0,0,50))
				drop:Spawn()
			end
		end
	end

	-- Run on-killed function to give points if the hook isn't blocking it
	-- if !hook.Call("OnZombieKilled", nil, enemy, attacker, dmginfo, hitgroup) then
	-- 	if enemy:IsValidZombie() then
	-- 		if attacker:IsPlayer() and attacker:GetNotDowned() then
	-- 			if meleetypes[dmginfo:GetDamageType()] then
	-- 				attacker:GivePoints(130)
	-- 			elseif hitgroup == HITGROUP_HEAD then
	-- 				attacker:GivePoints(100)
	-- 			else
	-- 				attacker:GivePoints(50)
	-- 			end
	-- 		end
	-- 	end
	-- end

	if nzRound:InProgress() then
		if (enemy.GetSpawner) then
			if enemy:GetSpawner() then
				local spawner_class = enemy:GetSpawner():GetClass()
				nzRound:SetZombiesKilled(nzRound:GetZombiesKilled(spawner_class) + 1, spawner_class)
			end
		end

		nzRound:SetZombiesKilled( nzRound:GetZombiesKilled() + 1 )

		-- Chance a powerup spawning
		if !nzPowerUps:IsPowerupActive("insta") and IsValid(enemy) then -- Don't spawn powerups during instakill
			if !nzPowerUps:GetPowerUpChance() then nzPowerUps:ResetPowerUpChance() end
			if math.Rand(0, 100) < nzPowerUps:GetPowerUpChance() then
				nzPowerUps:SpawnPowerUp(enemy:GetPos())
				nzPowerUps:ResetPowerUpChance()
			else
				nzPowerUps:IncreasePowerUpChance()
			end
		end

		print("Killed Enemy: " .. nzRound:GetZombiesKilled() .. "/" .. nzRound:GetZombiesMax() )
		if nzRound:IsSpecial() and nzRound:GetZombiesKilled() >= nzRound:GetZombiesMax() then
			nzPowerUps:SpawnPowerUp(enemy:GetPos(), "maxammo")
			--reset chance here?
		end
	end
	-- Prevent this function from running on this zombie again
	enemy.MarkedForDeath = true
end

-- local DMG_ALL = bit.bor(DMG_GENERIC, DMG_CRUSH, DMG_BULLET, DMG_SLASH,
-- 				DMG_BURN, DMG_VEHICLE, DMG_FALL, DMG_BLAST, DMG_CLUB,
-- 				DMG_SHOCK, DMG_SONIC, DMG_ENERGYBEAM, DMG_PREVENT_PHYSICS_FORCE,
-- 				DMG_NEVERGIB, DMG_ALWAYSGIB, DMG_DROWN, DMG_PARALYZE,
-- 				DMG_NERVEGAS, DMG_POISON, DMG_RADIATION, DMG_DROWNRECOVER,
-- 				DMG_ACID, DMG_SLOWBURN, DMG_REMOVENORAGDOLL, DMG_PHYSGUN,
-- 				DMG_PLASMA, DMG_AIRBOAT, DMG_DISSOLVE, DMG_BLAST_SURFACE,
-- 				DMG_DIRECT, DMG_BUCKSHOT, DMG_SNIPER, DMG_MISSILEDEFENSE)

function GM:EntityTakeDamage(zombie, dmginfo)
	dmginfo:Reset(false)

	-- Traps have their own isolated damage logic
	-- if IsValid(attacker) and attacker.Trap then
	-- 	-- if IsValid(zombie) and zombie:IsValidZombie() and zombie:Health() > 0 then
	-- 	-- 	-- if zombie.NZBoss then -- Traps cannot hurt bosses..
	-- 	-- 	-- 	dmginfo:ScaleDamage(0)
	-- 	-- 	-- else
	-- 	-- 	-- 	return -- Traps should have their own damage configurations..
	-- 	-- 	-- end
	-- 	-- end
	-- end

	local dmgType = dmginfo:GetDamageType()
	local isBulletDamage = (bit.band(dmgType, DMG_BULLET) == DMG_BULLET)
						or (bit.band(dmgType, DMG_AIRBOAT) == DMG_AIRBOAT)

	-- Who's Who clones can't take damage!
	if zombie:GetClass() == "whoswho_downed_clone" then return true end

	-- Fix zombie invincibility
	if (zombie:IsValidZombie()) then
        -- If a zombie dies before it spawns, it will spawn as invincible
        -- Fix by Ethorbit after a month of head bashing. Save my head by keeping this here.
        if !zombie:GetSpawned() then
            dmginfo:SetDamage(0)
        return end

        if zombie.Alive and zombie:Alive() and zombie:Health() <= 0 then zombie:Kill(dmginfo) end -- No zombie should ever have under 0 health

		if (!zombie.GetMaxHealth or zombie:Health() > zombie:GetMaxHealth() and zombie:Health() - zombie:GetMaxHealth() > 50) then
			zombie:Kill(dmginfo)
		end

		-- -- For walkers
		-- if (zombie:GetClass() == "nz_zombie_walker" or zombie:GetClass() == "nz_zombie_special_burning") then
		-- 	if (zombie:Health() != 75 and zombie:Health() > nzRound:GetZombieHealth() and zombie:Health() - nzRound:GetZombieHealth() > 50) then
		-- 		zombie:Kill(dmginfo)
		-- 	end
		-- end

		-- -- For dogs
		-- if (zombie:GetClass() == "nz_zombie_special_dog") then
		-- 	if (zombie:Health() > nzRound:GetHellHoundHealth() and zombie:Health() - nzRound:GetHellHoundHealth() > 50) then
		-- 		zombie:Kill(dmginfo)
		-- 	end
		-- end

		-- -- For Panzers
		-- if (zombie:GetClass() == "nz_zombie_boss_panzer") then
		-- 	local round = nzRound:GetNumber()
		-- 	local equation = round * 75 + 500 and zombie:Health()
		-- 	if (round and zombie:Health() > equation and zombie:Health() - equation > 50) then
		-- 		zombie:Kill(dmginfo)
		-- 	end
		-- end
	end

	-- Handle MaxDamage logic as it actually does nothing in Garry's Mod and can be useful
	if (dmginfo:GetMaxDamage() > 0 and dmginfo:GetDamage() > dmginfo:GetMaxDamage()) then
		dmginfo:SetDamage(dmginfo:GetMaxDamage())
	end

	local attacker = dmginfo:GetAttacker()

	if IsValid(zombie) then
		-- if zombie:IsValidZombie() then
		-- 	hook.Run("OnZombieHit", zombie, dmginfo)
		-- end

		if zombie.NZBoss or zombie.NZBossType then
			if zombie.IsInvulnerable and zombie:IsInvulnerable() then return true end -- Bosses can still be invulnerable
			
			if dmginfo:GetDamage() >= zombie:GetMaxHealth() then -- Require wonder weapons to take 4 hits instead of 1 since we're a boss
                dmginfo:SetDamage(zombie:GetMaxHealth() / 4)
			end

			local data = nzRound:GetBossData(zombie.NZBossType) -- Just in case it was switched mid-game, use the id stored on zombie
			if data then -- If we got the boss data
				local hitgroup = util.QuickTrace( dmginfo:GetDamagePosition(), dmginfo:GetDamagePosition() ).HitGroup
				if zombie:Health() > dmginfo:GetDamage() then
					hook.Run("OnBossHit", zombie, dmginfo)
					if data.onhit then data.onhit(zombie, attacker, dmginfo, hitgroup) end
				elseif !zombie.MarkedForDeath then
					if data.deathfunc then data.deathfunc(zombie, attacker, dmginfo, hitgroup) end
					hook.Run("OnBossKilled", zombie, dmginfo)
					zombie.MarkedForDeath = true
				end
			end
		elseif zombie:IsValidZombie() then
			if zombie.IsInvulnerable and zombie:IsInvulnerable() then return true end
			local hitgroup = util.QuickTrace( dmginfo:GetDamagePosition( ), dmginfo:GetDamagePosition( ) ).HitGroup

			if (IsValid(attacker) and attacker:IsPlayer()) then
				local weapon = attacker:GetActiveWeapon()
			        zombie.NextPelletHurt = zombie.NextPelletHurt or {}
			        zombie.NextPelletHurt[weapon] = zombie.NextPelletHurt[weapon] or 0

				if (IsValid(weapon) and !weapon:IsSpecial() and weapon:IsTFA()) then
					local numShots = weapon:GetStat("Primary.NumShots")

				        -- Stupid shotgun damage workaround (FIX THIS TO HAVE ACCURACY ASAP)
					if isBulletDamage and numShots > 1 and CurTime() > zombie.NextPelletHurt[weapon] then
					       zombie.NextPelletHurt[weapon] = CurTime() + engine.TickInterval()
					       local dmgNum = weapon:GetStat("Primary.Damage")
					       --print("HURT BY PELLET")

						local shots_that_hit = math.random(1, numShots)
					        shots_that_hit = math.random(1, shots_that_hit)
					        --shots_that_hit = math.random(1, shots_that_hit)
					        --shots_that_hit = math.random(1, shots_that_hit)
					        --print("SHOTS:", shots_that_hit)

						local random_dmg = dmgNum * shots_that_hit

						if dmginfo:GetDamage() < random_dmg then
							dmginfo:SetDamage(random_dmg)
						end

						-- Add some range for shotguns so you can't just snipe across the map..
						local distance = (attacker:GetPos() - zombie:GetPos()):Length()
						local range = weapon:GetStat("Primary.DamageRange") or 1000
						if (range and distance > range) then
							local dmgScale = math.Clamp(range / distance, 0, 1)
							--print(dmgScale)
							dmginfo:ScaleDamage(dmgScale)
						end
					end

					if attacker:HasPerk("deadshot") then
						--local dmgType = dmginfo:GetDamageType()
						--local clipSize = weapon:GetStat("Primary.ClipSize")
						--local rpm = weapon:GetStat("Primary.RPM")
						local wepsAmmo = weapon:GetStat("Primary.OldAmmo")
						--local isShotgun = weapon.NZWeaponType == "shotgun" or (isBulletDamage and isnumber(numShots) and numShots > 1)
						--local isSemiAuto = weapon.NZWeaponType == "semiauto" or (isBulletDamage and !weapon:GetStat("Primary.Automatic") or isnumber(clipSize) and clipSize <= 2)
						--local isProjectile = weapon.NZWeaponType == "projectile" or (dmgType == DMG_BLAST or !isBulletDamage and dmgType != DMG_CLUB and dmgType != DMG_SLASH and dmgType != DMG_DIRECT)
						local isSniper = weapon.NZWeaponType == "sniper" or (isBulletDamage and isstring(wepsAmmo) and wepsAmmo == "nz_weapon_ammo_1") -- No idea why, but nz_weapon_ammo_1 is the sniper ammo name
						--local isFast = (isnumber(clipSize) and clipSize > 1 and isnumber(rpm) and rpm > 50)

						local function ForceHeadshot()
							if (!weapon.NoHeadshots) then
								--dmginfo:SetDamageCustom(999)
								dmginfo:SetForcedHeadshot(true)
								hitgroup = HITGROUP_HEAD
							end
						end

						if (math.random(100) <= (isSniper and 40 or 20)) then
							ForceHeadshot()
						end

						-- if (!isShotgun and (isSemiAuto or isSniper)) then
						-- 	if (!isSniper or (isSniper and !isFast)) then -- Pistol or slow sniper
						-- 		print(math.random(100) <= 80)

						-- 		if (math.random(100) <= 40) then
						-- 			ForceHeadshot()
						-- 			print("Forced semi auto headshot")
						-- 		end
						-- 	end

						-- 	if (isSniper and isFast) then -- Auto sniper
						-- 		if (math.random(100) <= 40) then
						-- 			ForceHeadshot()
						-- 			--print("Forced auto sniper headshot")
						-- 		end
						-- 	end
						-- end

						-- if (!isShotgun and !isSemiAuto and isBulletDamage and !isSniper) then
						-- 	if (math.random(100) <= 80) then
						-- 		ForceHeadshot()
						-- 		--print("Forced auto headshot")
						-- 	end
						-- end

						-- if (isShotgun and isSemiAuto) then
						-- 	if (math.random(100) <= 20) then
						-- 		ForceHeadshot()
						-- 		--print("Forced semi shotgun headshot")
						-- 	end
						-- end

						-- if (isShotgun and !isSemiAuto) then
						-- 	if (math.random(100) <= 20) then
						-- 		ForceHeadshot()
						-- 		--print("Forced auto shotgun headshot")
						-- 	end
						-- end

						-- if (isProjectile and dmgType != DMG_BURN) then
						-- 	if (math.random(100) <= 25) then
						-- 		ForceHeadshot()
						-- 		--print("Forced projectile headshot")
						-- 	end
						-- end
					end
				end
			end

			-- Insta-Kill compatibility
			if nzPowerUps:IsPowerupActive("insta") then
				--zombie:Kill(dmginfo)
				ZombieKillPoints(zombie, dmginfo, hitgroup)
				dmginfo:SetDamage(zombie:Health() * 2)
				nzEnemies:OnEnemyKilled(zombie, attacker, dmginfo, hitgroup)
			return end

			if (hitgroup == HITGROUP_HEAD) then
				local scaledHeadshot = false
				local wepOwner = dmginfo:GetAttacker()
				if (IsValid(wepOwner) and wepOwner:IsPlayer()) then
					local wep = wepOwner:GetActiveWeapon()
					if (IsValid(wep) and wep:IsWeapon() and !wep.NoHeadshots) then
						if (istable(wep.Primary) and isnumber(wep.Primary.DamageHeadshot) and (isBulletDamage or dmginfo:GetForcedHeadshot())) then
							dmginfo:ScaleDamage(wep.Primary.DamageHeadshot)
							scaledHeadshot = true
						end
					end
				end

				if (!scaledHeadshot) then
					if isBulletDamage then
						dmginfo:ScaleDamage(1.5)
					end
				end
			end

			-- if !dmginfo:GetForcedHeadshot() then

			-- end

			zombie:ScaleNPCDamage(zombie, hitgroup, dmginfo)

			if (IsValid(attacker) and attacker:IsPlayer()) then
				if attacker:HasPerk("dtap2") and isBulletDamage then
					dmginfo:ScaleDamage(2)
				end -- dtap2 bullet damage buff
			end

			-- Scale by percentage of zombie's health (if specified)
			if (dmginfo:GetDamagePercentage() > 0) then
				if (IsValid(zombie)) then
					local zombieHP = zombie:GetMaxHealth()
					if zombieHP then
						local percDmg = (zombieHP / (100 / dmginfo:GetDamagePercentage()))
						dmginfo:SetDamage(percDmg)
						dmginfo:SetMaxDamage(percDmg)
					end
				end
			end

			local hpLeft = math.floor(zombie:Health() - dmginfo:GetDamage())
			if (hpLeft <= 0) then --math.floor(zombie:Health() - dmginfo:GetDamage()) > 0
				ZombieKillPoints(zombie, dmginfo, hitgroup)
				nzEnemies:OnEnemyKilled(zombie, attacker, dmginfo, hitgroup)
			else
				--if zombie.HasTakenDamageThisTick then return end
				if IsValid(attacker) and attacker:IsPlayer() and attacker:GetNotDowned() and !hook.Call("OnZombieShot", nil, zombie, attacker, dmginfo, hitgroup) then
					if dmginfo:GetDamageType() == DMG_CLUB and attacker:HasPerk("widowswine") then
						local chance = math.random(1, 4)
						if (chance == 1) then
							zombie:ApplyWebFreeze(5)
						end
					end

					if (attacker.lastPoints == nil or CurTime() > attacker.lastPoints) then
						if (IsValid(attacker:GetActiveWeapon())) then
							if (zombie and (!zombie.nextsmallpoints or CurTime() > zombie.nextsmallpoints) and zombie:Health() > 0 and !nzPlayers.ZombieWasBurned(attacker, zombie)) then -- Prevent point spam
								zombie.nextsmallpoints = CurTime() + engine.TickInterval()

                                if dmginfo:GetDamageType() == DMG_BURN then
									nzPlayers.BurnZombie(attacker, zombie)
								end

								--nzPlayers.HurtZombie(attacker, zombie)
								attacker:GivePoints(10)
							end

							-- if (attacker:GetActiveWeapon():GetClass() == "tfa_paralyzer"
							-- || attacker:GetActiveWeapon():GetClass() == "tfa_jetgun") then
							-- 	attacker.lastPoints = CurTime() + 0.5
							-- 	attacker:GivePoints(10)
							-- elseif attacker:GetActiveWeapon():GetClass() == "nz_robotnik_waw_m2" then
							-- 	attacker.lastPoints = CurTime() + 0.2
							-- 	attacker:GivePoints(10)
							-- else
							-- 	--attacker.lastPoints = CurTime() + 0.03
							-- 	attacker:GivePoints(10)
							-- end
						end
					end

					--if (attacker:GetActiveWeapon():GetClass() != "")
				end
				--zombie.HasTakenDamageThisTick = true
				--  Prevent multiple damages in one tick (FA:S 2 Bullet penetration makes them hit 1 zombie 2-3 times per bullet)
				--timer.Simple(0, function() if IsValid(zombie) then zombie.HasTakenDamageThisTick = false end end)
			end
		end
	end
end

-- hook.Add("EntityTakeDamage", "NZ_HitFuncBreakable", function(target, dmginfo)
-- 	--print(target)
-- end)

local function OnRagdollCreated( ent )
	if ( ent:GetClass() == "prop_ragdoll" ) then
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end
hook.Add("OnEntityCreated", "nzEnemies_OnEntityCreated", OnRagdollCreated)

-- Increase max zombies alive per round
hook.Add("OnRoundPreparation", "NZIncreaseSpawnedZombies", function()
	if (!nzRound or !nzRound:GetNumber()) then return end
	if (nzRound:GetNumber() == 1 or nzRound:GetNumber() == -1) then return end -- Game just begun or it's round infinity

	local perround = nzMapping.Settings.spawnperround != nil and nzMapping.Settings.spawnperround or 0

	if (NZZombiesMaxAllowed == nil and nzMapping.Settings.startingspawns) then
		NZZombiesMaxAllowed = nzMapping.Settings.startingspawns
	end

	local startSpawns = nzMapping.Settings.startingspawns
	if !nzMapping.Settings.startingspawns then
		NZZombiesMaxAllowed = 35
		startSpawns = 35
	end

	local maxspawns = nzMapping.Settings.maxspawns
	if (maxspawns == nil) then
		maxspawns = 35
	end

	local newmax = startSpawns + (nzRound:GetNumber() * perround)
	if (newmax < maxspawns) then
		NZZombiesMaxAllowed = newmax
		print("Max zombies allowed at once: " .. NZZombiesMaxAllowed)
	else
		if (NZZombiesMaxAllowed != maxspawns) then
			print("Max zombies allowed at once capped at: " .. maxspawns)
			NZZombiesMaxAllowed = maxspawns
		end
	end
end)

-- Reset max spawned zombies allowed on end of game
hook.Add("OnRoundEnd", "NZResetSpawnedZombies", function()
	if nzMapping.Settings.startingspawns then
		NZZombiesMaxAllowed = nzMapping.Settings.startingspawns
	else
		NZZombiesMaxAllowed = 35
	end
end)

-- Allow bosses to pass through zombie walls
-- It's 2023 and I commented it out now because they can go through zombie walls regardless.
-- Not sure what changed, but hey less ShouldCollide hooks are always wonderful.
--hook.Add("ShouldCollide", "AllowBossesThroughZombieStuff", function(ent1, ent2)
--	if (SERVER) then
--		if (ent1:IsValid() and ent2:IsValid()) then
--			if (ent1:GetClass() == "invis_wall_zombie") then
--				if (ent2.NZBoss) then
--					return false
--				end
--			end
--
--			if (ent2:GetClass() == "invis_wall_zombie") then
--				if (ent1.NZBoss) then
--					return false
--				end
--			end
--		end
--	end
--end)

-- Ability to check for zombies inside "deadly" trigger_hurt(s) (A trigger meant to kill NPCs)
TriggerPositions = !istable(TriggerPositions) and {} or TriggerPositions
hook.Add("OnRoundStart", "FixTriggers", function()
	timer.Simple(2, function()
		TriggerPositions = {}

		for _,v in pairs(ents.FindByClass("trigger_hurt")) do
			local flags = v:GetSpawnFlags()
			local proceed = (bit.band(flags, 2) == 2 or bit.band(flags, 64) == 64)
			if (proceed) then
				local mins, maxs = v:GetCollisionBounds()
				TriggerPositions[v:EntIndex()] = {}
				TriggerPositions[v:EntIndex()]["Pos"] = v:GetPos()
				TriggerPositions[v:EntIndex()]["Mins"] = mins
				TriggerPositions[v:EntIndex()]["Maxs"] = maxs

				if (v:GetKeyValues().StartDisabled == 1) then
					TriggerPositions[v:EntIndex()]["Enabled"] = false
				else
					TriggerPositions[v:EntIndex()]["Enabled"] = true
				end
			end
		end

		PrintTable(TriggerPositions)
	end)
end)

hook.Add("AcceptInput", "SeeIfEnabled", function(ent, input, activator, caller, value)
	if (istable(TriggerPositions) and istable(TriggerPositions[ent:EntIndex()])) then
		if (input == "Toggle" and ent:GetClass() == "trigger_hurt") then
			print(ent:GetName())
			local val = TriggerPositions[ent:EntIndex()]["Enabled"]
			if (val == nil) then val = false end
			TriggerPositions[ent:EntIndex()]["Enabled"] = !val
			print(TriggerPositions[ent:EntIndex()]["Enabled"])
		end

		if (input == "Enable" and ent:GetClass() == "trigger_hurt") then
			TriggerPositions[ent:EntIndex()]["Enabled"] = true
		end

		if (input == "Disable" and ent:GetClass() == "trigger_hurt") then
			TriggerPositions[ent:EntIndex()]["Enabled"] = false
		end
	end
end)

function IsInDeadlyTrigger(zombie)
	local returnVal = false

	for _,v in pairs(ents.FindByClass("invis_damage_wall")) do
		if (returnVal) then break end

		if (v:GetKillZombies()) then
			for _,b in pairs(ents.FindInBox(v:GetPos(), v:GetPos() + v:GetMaxBound())) do
				if (b == zombie) then
					returnVal = true
					break
				end
			end
		end
	end

	if (nzMapping.Settings.zombietriggerkill) then
		if (istable(TriggerPositions)) then
			for _,v in pairs(TriggerPositions) do
				if (returnVal) then break end

				for _,b in pairs(ents.FindInBox(v["Pos"] + v["Mins"], v["Pos"] + v["Maxs"])) do
					if (b == zombie and v["Enabled"]) then
						returnVal = true
						break
					end
				end
			end
		end
	end

	return returnVal
end

-- function TestTriggers()
-- 	hook.Call("InitPostEntity", nil, nil)
-- end
