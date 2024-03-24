--
if SERVER then
	function FixDeathmachineBS(ply) -- Fixes how it's not visible and how you can accidentally cancel out by switching weps while grabbing
		if (IsValid(ply)) then
			ply.LastGrabbedDeathmachine = CurTime() + 1

			timer.Simple(1, function()
				if (IsValid(ply) and ply:Alive() and IsValid(ply:GetWeapon("nz_death_machine"))) then
					ply:SetActiveWeapon(ply:GetWeapon("nz_death_machine"))
					ply:GetWeapon("nz_death_machine"):ShootBullet(1, 1, 1)
				end
			end)

			local timerTag = ply:SteamID() .. "_deathmach"
			timer.Create(timerTag, 0.1, 60, function()
				if (!IsValid(ply) or IsValid(ply) and (!ply:Alive() or ply:Team() != TEAM_PLAYERS or !IsValid(ply:GetWeapon("nz_death_machine")) or !nzPowerUps:IsPlayerPowerupActive(ply, "deathmachine") or !ply.LastGrabbedDeathmachine or ply.LastGrabbedDeathmachine and CurTime() > ply.LastGrabbedDeathmachine)) then
					timer.Destroy(timerTag)
				else
					ply:SetActiveWeapon(ply:GetWeapon("nz_death_machine"))
					ply:SelectWeapon("nz_death_machine")
					ply:GetWeapon("nz_death_machine"):ShootBullet(1, 1, 1)
				end
			end)

			-- Remove powerup after ditching the minigun
			local fkinstupidtimer = ply:SteamID() .. "stupidswitchfixdm"
			timer.Create(fkinstupidtimer, 0.1, 900, function()
				if (!IsValid(ply) or IsValid(ply) and (!ply:Alive() or ply:Team() != TEAM_PLAYERS or nzPowerUps and !nzPowerUps:IsPlayerPowerupActive(ply, "deathmachine"))) then
					timer.Destroy(fkinstupidtimer)
				elseif (ply:GetActiveWeapon() != ply:GetWeapon("nz_death_machine") and ply.LastGrabbedDeathmachine and CurTime() > ply.LastGrabbedDeathmachine) then
					ply:RemovePowerUp("deathmachine")
					timer.Destroy(fkinstupidtimer)
				end
			end)
		end
	end

	util.AddNetworkString("RenderMaxAmmo")
	local plyMeta = FindMetaTable("Player")

	function plyMeta:GivePowerUp(id, duration)
		if duration and duration > 0 then
			if !nzPowerUps.ActivePlayerPowerUps[self] then nzPowerUps.ActivePlayerPowerUps[self] = {} end

			if (id == "deathmachine") then
				FixDeathmachineBS(self)
			end

			nzPowerUps.ActivePlayerPowerUps[self][id] = CurTime() + duration
			nzPowerUps:SendPlayerSync(self) -- Sync this player's powerups
		end
	end

	function plyMeta:RemovePowerUp(id, nosync)
		local PowerupData = nzPowerUps:Get(id)
		if PowerupData and PowerupData.expirefunc then
			PowerupData.expirefunc(id, self) -- Call expirefunc when manually removed
		end

		if !nzPowerUps.ActivePlayerPowerUps[self] then nzPowerUps.ActivePlayerPowerUps[self] = {} end
		nzPowerUps.ActivePlayerPowerUps[self][id] = nil
		if !nosync then nzPowerUps:SendPlayerSync(self) end -- Sync this player's powerups
	end

	function plyMeta:RemoveAllPowerUps()
		if !nzPowerUps.ActivePlayerPowerUps[self] then nzPowerUps.ActivePlayerPowerUps[self] = {} return end

		for k,v in pairs(nzPowerUps.ActivePlayerPowerUps[self]) do
			self:RemovePowerUp(k, true)
		end
		nzPowerUps:SendPlayerSync(self)
	end

	function nzPowerUps:Activate(id, ply, ent)
		if hook.Call("OnPlayerPickupPowerUp", nil, ply, id, ent) then return end

		local PowerupData = self:Get(id)

		if !PowerupData.global then
			if IsValid(ply) then
				if not nzPowerUps.ActivePlayerPowerUps[ply] or not nzPowerUps.ActivePlayerPowerUps[ply][id] then -- If you don't have the powerup
					PowerupData.func(id, ply)
				end
				ply:GivePowerUp(id, PowerupData.duration)
			end
		else
			if PowerupData.duration != 0 then
				-- Activate for a certain time
				if not self.ActivePowerUps[id] then
					PowerupData.func(id, ply)
				end
				self.ActivePowerUps[id] = CurTime() + PowerupData.duration
			else
				-- Activate Once
				PowerupData.func(id, ply)
			end
			-- Sync to everyone
			self:SendSync()

		end

		-- Notify
		if IsValid(ply) then
			nzSounds:PlayEnt("Grab", ply)
		--if PowerupData.announcement then
			--nzNotifications:PlaySound(PowerupData.announcement, 1)
		end

		if isstring(PowerupData.announcement) then
			local name = string.Replace(PowerupData.name, " ", "") -- Sound Events don't have spaces
			nzSounds:Play(name)
		end
	end

	function nzPowerUps:SpawnPowerUp(pos, specific)
		local choices = {}
		local total = 0

		-- Chance it
		if !specific then
			for k,v in pairs(self.Data) do
				if k != "ActivePowerUps" then
					choices[k] = v.chance
					total = total + v.chance
				end
			end
		end

		local id = specific and specific or nzMisc.WeightedRandom(choices)
		if !id or id == "null" then return end --  Back out

		local ent = ents.Create("drop_powerup")
		id = hook.Call("OnPowerUpSpawned", nil, id, ent) or id
		if !IsValid(ent) then return end -- If a hook removed the powerup

		-- Spawn it
		local PowerupData = self:Get(id)

		local pos = pos+Vector(0,0,50)

		ent:SetPowerUp(id)
		pos.z = pos.z - ent:OBBMaxs().z
		ent:SetModel(PowerupData.model)
		ent:SetPos(pos)
		ent:SetAngles(PowerupData.angle)
		ent:Spawn()
		nzSounds:PlayEnt("Spawn", ent)
		--ent:EmitSound("nz/powerups/power_up_spawn.wav")
	end

end

function nzPowerUps:IsPowerupActive(id)

	local time = self.ActivePowerUps[id]

	if time != nil then
		-- Check if it is still within the time.
		if CurTime() > time then
			-- Expired
			self.ActivePowerUps[id] = nil
		else
			return true
		end
	end

	return false

end

function nzPowerUps:IsPlayerPowerupActive(ply, id)
	-- Return ends that SHOULD'VE existed before..
	if (!self.ActivePlayerPowerUps) then return end
	if (!self.ActivePlayerPowerUps[ply]) then return end
	if (!self.ActivePlayerPowerUps[ply][id]) then return end

	local time = self.ActivePlayerPowerUps[ply][id]

	if time then
		-- Check if it is still within the time.
		if CurTime() > time then
			-- Expired
			self.ActivePlayerPowerUps[ply][id] = nil
		else
			return true
		end
	end

	return false

end

function nzPowerUps:AllActivePowerUps()

	return self.ActivePowerUps

end

function nzPowerUps:NewPowerUp(id, data)
	if SERVER then
		-- Sanitise any client data.
	else
		data.Func = nil
	end
	self.Data[id] = data
end

-- nzPowerUps.ShuffledPowerUps = {}

-- function nzPowerUps:Shuffle()
-- 	local poweruplist = table.Copy(nzMapping.Settings.poweruplist) or {}
--
-- 	-- Deathmachine needs power
-- 	if (!nzElec.Active) then
-- 		poweruplist["deathmachine"] = nil
-- 	end
--
-- 	-- Carpenter needs more than 5 windows broken
-- 	local windows = ents.FindByClass("breakable_entry")
-- 	if (#windows >= 5) then
-- 		local windows_broken = 0
--
-- 		for _,window in pairs(windows) do
-- 			if (window:GetNumPlanks() <= 0) then
-- 				windows_broken = windows_broken + 1
-- 			end
-- 		end
--
-- 		if (windows_broken < 5) then
-- 			poweruplist["carpenter"] = nil
-- 		end
-- 	end
--
-- 	-- Firesale needs Mystery Box to have moved at least once
-- 	if !nzRound:GetBoxHasMoved() then
-- 		poweruplist["firesale"] = nil
-- 	end
--
-- 	self.ShuffledPowerUps = table.GetKeys(poweruplist)
--
-- 	for i = 1, #self.ShuffledPowerUps do
--         local rand = math.random(#self.ShuffledPowerUps)
--         self.ShuffledPowerUps[i], self.ShuffledPowerUps[rand] = self.ShuffledPowerUps[rand], self.ShuffledPowerUps[i]
-- 	end
-- end

-- function nzPowerUps:GetShuffled()
-- 	return self.ShuffledPowerUps
-- end
--
-- function nzPowerUps:GetNext()
-- 	if (#nzPowerUps:GetShuffledPowerUps() <= 0) then
-- 		self:Shuffle()
-- 	end
--
-- 	return self.Data[self.ShuffledPowerUps[1]]
-- end

function nzPowerUps:GetList()
	local tbl = {}

	for k,v in pairs(nzPowerUps.Data) do
		tbl[k] = v.name
	end

	return tbl
end

function nzPowerUps:Get(id)
	return self.Data[id]
end

-- Double Points
nzPowerUps:NewPowerUp("dp", {
	name = "Double Points",
	model = "models/nzpowerups/hidden_double_points.mdl",
	global = true, -- Global means it will appear for any player and will refresh its own time if more
	angle = Angle(25,0,0),
	scale = 1,
	chance = 5,
	duration = 30,
	announcement = "nz/powerups/double_points.mp3",
	func = function(self, ply)
		nzSounds:PlayFileCS("nzr/announcer/powerups/ambience/double_points_loop.wav")
	end,
	expirefunc = function()
		nzSounds:StopFileCS("nzr/announcer/powerups/ambience/double_points_loop.wav")
		nzSounds:PlayFileCS("nzr/announcer/powerups/ambience/double_points_end.wav")
	end,
})

-- Max Ammo
nzPowerUps:NewPowerUp("maxammo", {
	name = "Max Ammo",
	model = "models/nzpowerups/hidden_maxammo.mdl",
	global = true,
	angle = Angle(0,0,25),
	scale = 1.5,
	chance = 5,
	duration = 0,
	func = (function(self, ply)
		nzSounds:Play("MaxAmmo")
		--nzNotifications:PlaySound("chron/nz/powerups/max_ammo.mp3", 2)
		-- Give everyone ammo
		for k,v in pairs(player.GetAll()) do
			v:GiveMaxAmmo()
		end

		net.Start("RenderMaxAmmo")
		net.Broadcast()
	end),
})

-- Insta Kill
nzPowerUps:NewPowerUp("insta", {
	name = "Insta Kill",
	model = "models/nzpowerups/hidden_instakill.mdl",
	global = true,
	angle = Angle(0,0,0),
	scale = 1,
	chance = 5,
	duration = 30,
	announcement = "nz/powerups/insta_kill.mp3",
	func = function(self, ply)
		nzSounds:PlayFileCS("nzr/announcer/powerups/ambience/insta_kill_loop.wav")
	end,
	expirefunc = function()
		nzSounds:StopFileCS("nzr/announcer/powerups/ambience/insta_kill_loop.wav")
		nzSounds:PlayFileCS("nzr/announcer/powerups/ambience/insta_kill_end.wav")
	end,
})

-- Nuke
nzPowerUps:NewPowerUp("nuke", {
	name = "Nuke",
	model = "models/nzpowerups/hidden_nuke.mdl",
	global = true,
	angle = Angle(10,0,0),
	scale = 1,
	chance = 5,
	duration = 0,
	announcement = "chron/nz/powerups/nuke.wav",
	func = (function(self, ply)
		nzPowerUps:Nuke(ply:GetPos())
	end),
})

local function RemoveActiveBoxes()
	local tbl = ents.FindByClass("random_box_spawns")
	for k,v in pairs(tbl) do
		local box = v.FireSaleBox
		if IsValid(box) then
			box:StopSound("nz_firesale_jingle")
			if box.MarkForRemoval then
				box:MarkForRemoval()
				box.FireSaling = false
			else
				box:Remove()
			end
		end
	end
end

-- Fire Sale
nzPowerUps:NewPowerUp("firesale", {
	name = "Fire Sale",
	model = "models/nzpowerups/hidden_fire_sale.mdl",
	global = true,
	angle = Angle(45,0,0),
	scale = 0.75,
	chance = 1,
	duration = 30,
	announcement = "nz/powerups/fire_sale_announcer.wav",
	func = (function(self, ply)
		RemoveActiveBoxes()
		nzPowerUps:FireSale()
	end),
	expirefunc = function()
		RemoveActiveBoxes()
	end,
})

-- Carpenter
nzPowerUps:NewPowerUp("carpenter", {
	name = "Carpenter",
	model = "models/nzpowerups/hidden_carpenter.mdl",
	global = true,
	angle = Angle(45,0,0),
	scale = 1,
	chance = 5,
	duration = 0,
	func = (function(self, ply)
		--nzNotifications:PlaySound("nz/powerups/carpenter.wav", 0)
		nzSounds:Play("Carpenter")
		nzPowerUps:Carpenter()
	end),
})

-- Zombie Blood
nzPowerUps:NewPowerUp("zombieblood", {
	name = "Zombie Blood",
	model = "models/nzpowerups/hidden_zombie_blood.mdl",
	global = false, -- Only applies to the player picking it up and time is handled individually per player
	angle = Angle(0,0,0),
	scale = 1,
	chance = 2,
	duration = 30,
	announcement = "nz/powerups/zombie_blood.wav",
	func = (function(self, ply)
		local hookName = "ZombieBlood" .. ply:EntIndex()
		hook.Add("Think", hookName, function()
			if (IsValid(ply) and ply:IsInCreative() or !IsValid(ply) or (IsValid(ply) and (ply:Team() != TEAM_PLAYERS or !ply:Alive()))) then
				hook.Remove("Think", hookName)
			else
				if (ply:IsInCreative() or ply:Team() == TEAM_PLAYERS) then
					if ply:GetNotDowned() then -- Going down should handle priority already, maybe this might fix an exploit?
						ply:SetTargetPriority(TARGET_PRIORITY_NONE)
					end
				end
			end
		end)
	end),
	expirefunc = function(self, ply) -- ply is only passed if the powerup is non-global
		local hookName = "ZombieBlood" .. ply:EntIndex()
		hook.Remove("Think", hookName)

		if (ply:IsInCreative() or ply:Team() == TEAM_PLAYERS) then
			ply:SetTargetPriority(TARGET_PRIORITY_PLAYER)
		end
	end,
})

-- Death Machine
nzPowerUps:NewPowerUp("deathmachine", {
	name = "Death Machine",
	model = "models/nzpowerups/hidden_death_machine.mdl",
	global = false, -- Only applies to the player picking it up and time is handled individually per player
	angle = Angle(0,0,0),
	scale = 1,
	chance = 2,
	duration = 30,
	announcement = "nz/powerups/deathmachine.mp3",
	func = (function(self, ply)
		ply.UsedDeathmachine = false
		ply:SetUsingSpecialWeapon(true)
		ply:Give("nz_death_machine")
		ply:SelectWeapon("nz_death_machine")

		FixDeathmachineBS(ply)
	end),
	expirefunc = function(self, ply) -- ply is only passed if the powerup is non-global
		ply:SetUsingSpecialWeapon(false)
		ply:StripWeapon("nz_death_machine")
		ply:EquipPreviousWeapon()
	end,
})
