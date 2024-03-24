nzPerks.ValidBottles = nzPerks.ValidBottles or {"nz_perk_bottle"}

function nzPerks:NewBottle(perk_id, weapon_class) -- Added by Ethorbit for perks with custom bottle weapons support
    local data = nzPerks.Data

    if data.perk_id then
        data.perk_id.bottle_ent = weapon_class
		nzSpecialWeapons:AddSpecialWeapon(weapon_class)
		nzConfig.AddWeaponToBlacklist(weapon_class)
		nzPerks.ValidBottles[weapon_class] = true
    end
end

function nzPerks:GetBottles(nocopy) -- Added by Ethorbit now that there can be more than 1 bottle entity
	return nocopy and nzPerks.ValidBottles or table.Copy(nzPerks.ValidBottles)
end

function nzPerks:NewPerk(id, data)
	if SERVER then
		//Sanitise any client data.
	else
		data.Func = nil
	end
	nzPerks.Data[id] = data
end

function nzPerks:Get(id)
	return nzPerks.Data[id]
end

function nzPerks:GetByName(name)
	for _, perk in pairs(nzPerks.Data) do
		if perk.name == name then
			return perk
		end
	end

	return nil
end

function nzPerks:GetList()
	local tbl = {}

	for k,v in pairs(nzPerks.Data) do
		tbl[k] = v.name
	end

	return tbl
end

function nzPerks:GetIcons()
	local tbl = {}

	for k,v in pairs(nzPerks.Data) do
		tbl[k] = v.icon
	end

	return tbl
end

function nzPerks:GetBottleMaterials()
	local tbl = {}

	for k,v in pairs(nzPerks.Data) do
		tbl[k] = v.material
	end

	return tbl
end

nzPerks:NewPerk("jugg", {
	name = "Juggernog",
	off_model = "models/alig96/perks/jugg/jugg_off.mdl",
	on_model = "models/alig96/perks/jugg/jugg_on.mdl",
	price = 2500,
	material = "models/perk_bottle/c_perk_bottle_jugg",
	icon = Material("perk_icons/jugg.png", "smooth unlitgeneric"),
	color = Color(255, 100, 100),
	func = function(self, ply, machine)
			ply:SetMaxHealth(210)
			ply:SetHealth(210)
	end,
	lostfunc = function(self, ply)
		ply:SetMaxHealth(100)
		if ply:Health() > 100 then ply:SetHealth(100) end
	end,
})

nzPerks:NewPerk("dtap", {
	name = "Double Tap",
	off_model = "models/alig96/perks/doubletap/doubletap_off.mdl",
	on_model = "models/alig96/perks/doubletap/doubletap_on.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_dtap",
	icon = Material("perk_icons/dtap.png", "smooth unlitgeneric"),
	color = Color(255, 255, 100),
	func = function(self, ply, machine)
		-- for k,v in pairs(ply:GetWeapons()) do
		-- 	v:ApplyNZModifier("dtap")
		-- end

		-- local tbl = {}
		-- for k,v in pairs(ply:GetWeapons()) do
		-- 	if v:IsFAS2() then
		-- 		table.insert(tbl, v)
		-- 	end
		-- end
		-- if tbl[1] != nil then
		-- 	for k,v in pairs(tbl) do
		-- 		v:ApplyNZModifier("dtap")
		-- 	end
		-- end
	end,
	lostfunc = function(self, ply)
		if !ply:HasPerk("dtap2") then
			local tbl = {}
			for k,v in pairs(ply:GetWeapons()) do
				if v:IsFAS2() then
					table.insert(tbl, v)
				end
			end
			if tbl[1] != nil then
				for k,v in pairs(tbl) do
					v:RevertNZModifier("dtap")
				end
			end
		end
	end,
})

nzPerks:NewPerk("revive", {
	name = "Quick Revive",
	off_model = "models/alig96/perks/revive/revive_off.mdl",
	on_model = "models/alig96/perks/revive/revive_on.mdl",
	price = 1500,
	material = "models/perk_bottle/c_perk_bottle_revive",
	icon = Material("perk_icons/revive.png", "smooth unlitgeneric"),
	color = Color(100, 100, 255),
	func = function(self, ply, machine)
			if #player.GetAllPlaying() <= 1 then
				if !ply.SoloRevive or ply.SoloRevive < 3 or !IsValid(machine) then
					ply:ChatPrint("You got Quick Revive (Solo)!")
				else
					ply:ChatPrint("You can only get Quick Revive Solo 3 times.")
					return false
				end
			end
	end,
	lostfunc = function(self, ply)

	end,
})

nzPerks:NewPerk("speed", {
	name = "Speed Cola",
	off_model = "models/alig96/perks/speed/speed_off.mdl",
	on_model = "models/alig96/perks/speed/speed_on.mdl",
	price = 3000,
	material = "models/perk_bottle/c_perk_bottle_speed",
	icon = Material("perk_icons/speed.png", "smooth unlitgeneric"),
	color = Color(100, 255, 100),
	func = function(self, ply, machine)
		local tbl = {}
		for k,v in pairs(ply:GetWeapons()) do
			if v:NZPerkSpecialTreatment() then
				table.insert(tbl, v)
			end
		end
		if tbl[1] != nil then
			--local str = ""
			for k,v in pairs(tbl) do
				v:ApplyNZModifier("speed")
				--str = str .. v.ClassName .. ", "
			end
		end
	end,
	lostfunc = function(self, ply)
		local tbl = {}
		for k,v in pairs(ply:GetWeapons()) do
			if v:NZPerkSpecialTreatment() then
				table.insert(tbl, v)
			end
		end
		if tbl[1] != nil then
			for k,v in pairs(tbl) do
				v:RevertNZModifier("speed")
			end
		end
	end,
})

nzPerks:NewPerk("pap", {
	name = "Pack-a-Punch",
	off_model = "models/alig96/perks/packapunch/packapunch.mdl", //Find a new model.
	on_model = "models/alig96/perks/packapunch/packapunch.mdl",
	price = 0,
	specialmachine = true, -- Prevents players from getting the perk when they buy it
	nobuy = true, -- A "Buy" event won't run when this is used (we do that ourselves in its function)
	-- We don't use materials
	icon = Material("vulture_icons/pap.png", "smooth unlitgeneric"),
	color = Color(200, 220, 220),
	condition = function(self, ply, machine)
		if !IsValid(machine) or !IsValid(ply) then return false end -- Don't let the ghost grab things I guess?
		local wep = ply:GetActiveWeapon()

		-- They can't upgrade a weapon if there's currently a weapon in our slot
		if IsValid(machine.papfly) then return false end

		-- Upgrading current weapon
		if (!IsValid(wep)) then return false end
		if (wep:IsSpecial()) then return false end
		if (IsValid(wep)) then
			local replacement = nzWeps:GetReplacement(wep:GetClass())
			if replacement and replacement.NZOnlyAllowOnePlayerToUse and nzWeps:IsSoloWeaponInUse(replacement.ClassName) then return false end

			local is_replaceable = nzWeps:IsReplaceable(wep:GetClass())
			if is_replaceable and wep:HasNZModifier("pap") and wep:CanRerollPaP() and !wep.NZPaPReplacement then return false end
			if (!wep:HasNZModifier("pap") or wep:CanRerollPaP()) and !machine:GetBeingUsed() then
				local reroll = false
				if (wep:HasNZModifier("pap") and wep:CanRerollPaP()) then
					if (!wep.AllowReRollAtts and !is_replaceable) then return false end
					reroll = true
				end
				local cost = reroll and 2000 or 5000
				return ply:GetPoints() >= cost
			-- else
			-- 	ply:PrintMessage( HUD_PRINTTALK, "This weapon is already Pack-a-Punched")
			-- 	return false
			end
		end
	end,
	func = function(self, ply, machine)
		local wep = ply:GetActiveWeapon()

		local reroll = false
		if wep:HasNZModifier("pap") and wep:CanRerollPaP() then
			reroll = true
		end
		local cost = reroll and 2000 or 5000

		ply:Buy(cost, machine, function()
			hook.Call("OnPlayerBuyPackAPunch", nil, ply, wep, machine)

			ply:Give("nz_packapunch_arms")

			machine:SetBeingUsed(true)
			machine:EmitSound("nz/machines/pap_up.wav")
			local class = wep:GetClass()

			local e = EffectData()
			e:SetEntity(machine)
			local ang = machine:GetAngles()
			e:SetOrigin(machine:GetPos() + ang:Up()*35 + ang:Forward()*20 - ang:Right()*2)
			e:SetMagnitude(3)
			util.Effect("pap_glow", e, true, true)

			wep:Remove()
			local wep = ents.Create("pap_weapon_fly")
			machine.papfly = wep
			local startpos = machine:GetPos() + ang:Forward()*30 + ang:Up()*25 + ang:Right()*-3
			wep:SetPos(startpos)
			wep:SetAngles(ang + Angle(0,90,0))
			wep.WepClass = class
			wep:Spawn()
			local weapon = weapons.Get(class)
			local model = (weapon and weapon.WM or weapon.WorldModel) or "models/weapons/w_rif_ak47.mdl"
			if !util.IsValidModel(model) then model = "models/weapons/w_rif_ak47.mdl" end
			wep:SetModel(model)
			wep.machine = machine
			wep.Owner = ply
			wep:SetMoveType( MOVETYPE_FLY )

			--wep:SetNotSolid(true)
			--wep:SetGravity(0.000001)
			--wep:SetCollisionBounds(Vector(0,0,0), Vector(0,0,0))
			timer.Simple(0.5, function()
				if IsValid(wep) then
					wep:SetLocalVelocity(ang:Forward()*-30)
				end
			end)
			timer.Simple(1.8, function()
				if IsValid(wep) then
					wep:SetMoveType(MOVETYPE_NONE)
					wep:SetLocalVelocity(Vector(0,0,0))
				end
			end)
			timer.Simple(3, function()
				if IsValid(wep) and IsValid(machine) then
					local weapon = weapons.Get(class)
					if weapon and weapon.NZPaPReplacement and weapons.Get(weapon.NZPaPReplacement) then
						local pos, ang = wep:GetPos(), wep:GetAngles()
						wep:Remove()
						wep = ents.Create("pap_weapon_fly") -- Recreate a new entity with the replacement class instead
						machine.papfly = wep
						wep:SetPos(pos)
						wep:SetAngles(ang)
						wep.WepClass = weapon.NZPaPReplacement
						wep:Spawn()
						wep.TriggerPos = startpos

						local replacewep = weapons.Get(weapon.NZPaPReplacement)
						local model = (replacewep and replacewep.WM or replacewep.WorldModel) or "models/weapons/w_rif_ak47.mdl"
						if !util.IsValidModel(model) then model = "models/weapons/w_rif_ak47.mdl" end
						wep:SetModel(model) -- Changing the model and name
						wep.machine = machine
						wep.Owner = ply
						wep:SetMoveType( MOVETYPE_FLY )
					end

					--print(wep, wep.WepClass, wep:GetModel())

					machine:EmitSound("nz/machines/pap_ready.wav")
					wep:SetCollisionBounds(Vector(0,0,0), Vector(0,0,0))
					wep:SetMoveType(MOVETYPE_FLY)
					wep:SetGravity(0.000001)
					wep:SetLocalVelocity(ang:Forward()*30)
					--print(ang:Forward()*30, wep:GetVelocity())
					wep:CreateTriggerZone(reroll)
					--print(reroll)
				end
			end)
			timer.Simple(4.2, function()
				if IsValid(wep) then
					--print("YDA")
					--print(wep:GetMoveType())
					--print(ang:Forward()*30, wep:GetVelocity())
					wep:SetMoveType(MOVETYPE_NONE)
					wep:SetLocalVelocity(Vector(0,0,0))
				end
			end)
			timer.Simple(10, function()
				if IsValid(wep) then
					wep:SetMoveType(MOVETYPE_FLY)
					wep:SetLocalVelocity(ang:Forward()*-2)
				end
			end)
			timer.Simple(25, function()
				if IsValid(wep) then
					wep:Remove()
					if IsValid(machine) then
						machine:SetBeingUsed(false)
					end
				end
			end)

			timer.Simple(2, function() ply:RemovePerk("pap") end)
			return true
		end)
	end,
	lostfunc = function(self, ply)

	end,
})

nzPerks:NewPerk("dtap2", {
	name = "Double Tap 3.0",
	off_model = "models/alig96/perks/doubletap2/doubletap2_off.mdl",
	on_model = "models/alig96/perks/doubletap2/doubletap2.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_dtap2",
	icon = Material("perk_icons/dtap2.png", "smooth unlitgeneric"),
	color = Color(255, 255, 100),
	func = function(self, ply, machine)
		ply:ChatPrint("[Double Tap] Firerate cannot increase, but you still deal 2X bullet damage.")

		-- for k,v in pairs(ply:GetWeapons()) do
		-- 	v:ApplyNZModifier("dtap")
		-- end

		-- local tbl = {}
		-- for k,v in pairs(ply:GetWeapons()) do
		-- 	if v:IsFAS2() then
		-- 		table.insert(tbl, v)
		-- 	end
		-- end
		-- if tbl[1] != nil then
		-- 	for k,v in pairs(tbl) do
		-- 		v:ApplyNZModifier("dtap")
		-- 	end
		-- end
	end,
	lostfunc = function(self, ply)
		if !ply:HasPerk("dtap") then
			for k,v in pairs(ply:GetWeapons()) do
				v:RevertNZModifier("dtap")
			end

			-- local tbl = {}
			-- for k,v in pairs(ply:GetWeapons()) do
			-- 	if v:IsFAS2() then
			-- 		table.insert(tbl, v)
			-- 	end
			-- end
			-- if tbl[1] != nil then
			-- 	for k,v in pairs(tbl) do
			-- 		v:RevertNZModifier("dtap")
			-- 	end
			-- end
		end
	end,
})

nzPerks:NewPerk("staminup", {
	name = "Stamin-Up",
	off_model = "models/alig96/perks/staminup/staminup_off.mdl",
	on_model = "models/alig96/perks/staminup/staminup.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_stamin",
	icon = Material("perk_icons/staminup.png", "smooth unlitgeneric"),
	color = Color(200, 255, 100),
	func = function(self, ply, machine)
		local new_walk_speed = ply:GetWalkSpeed("staminup")
		local new_run_speed = ply:GetRunSpeed("staminup")

		if new_walk_speed then
			ply:SetWalkSpeed(new_walk_speed)
		end

		if new_run_speed then
			ply:SetRunSpeed(new_run_speed)
			ply:SetMaxRunSpeed(new_run_speed)
		end

		ply:SetStamina(225)
		ply:SetMaxStamina(300)
	end,
	lostfunc = function(self, ply)
		local new_walk_speed = ply:GetWalkSpeed("default")
		local new_run_speed = ply:GetRunSpeed("default")

		if new_walk_speed then
			ply:SetWalkSpeed(new_walk_speed)
		end

		if new_run_speed then
			ply:SetRunSpeed(new_run_speed)
			ply:SetMaxRunSpeed(new_run_speed)
		end

		ply:SetStamina(100)
		ply:SetMaxStamina(100)
	end,
})

nzPerks:NewPerk("phd", {
	name = "PhD Flopper",
	off_model = "models/alig96/perks/phd/phdflopper_off.mdl",
	on_model = "models/alig96/perks/phd/phdflopper.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_phd",
	icon = Material("perk_icons/phd.png", "smooth unlitgeneric"),
	color = Color(255, 50, 255),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("deadshot", {
	name = "Deadshot Daiquiri 2.0",
	off_model = "models/alig96/perks/deadshot/deadshot_off.mdl",
	on_model = "models/alig96/perks/deadshot/deadshot.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_deadshot",
	icon = Material("perk_icons/deadshot.png", "smooth unlitgeneric"),
	color = Color(150, 200, 150),
	func = function(self, ply, machine)
		ply:ChatPrint("[Deadshot 2.0] Headshot chances: 40% snipers, 20% everything else.") -- , 25% (projectiles)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("mulekick", {
	name = "Mule Kick",
	off_model = "models/alig96/perks/mulekick/mulekick_off.mdl",
	on_model = "models/alig96/perks/mulekick/mulekick.mdl",
	price = 4000,
	material = "models/perk_bottle/c_perk_bottle_mulekick",
	icon = Material("perk_icons/mulekick.png", "smooth unlitgeneric"),
	color = Color(100, 200, 100),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
		for k,v in pairs(ply:GetWeapons()) do
			if v:GetNWInt("SwitchSlot") == 3 then
				ply:StripWeapon(v:GetClass())
			end
		end
	end,
})

nzPerks:NewPerk("tombstone", {
	name = "Tombstone Soda",
	off_model = "models/alig96/perks/tombstone/tombstone_off.mdl",
	on_model = "models/alig96/perks/tombstone/tombstone.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_tombstone",
	icon = Material("perk_icons/tombstone.png", "smooth unlitgeneric"),
	color = Color(30, 200, 30),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("whoswho", {
	name = "Who's Who",
	off_model = "models/alig96/perks/whoswho/whoswho_off.mdl",
	on_model = "models/alig96/perks/whoswho/whoswho.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_whoswho",
	icon = Material("perk_icons/whoswho.png", "smooth unlitgeneric"),
	color = Color(100, 100, 255),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("cherry", {
	name = "Electric Cherry",
	off_model = "models/alig96/perks/cherry/cherry_off.mdl",
	on_model = "models/alig96/perks/cherry/cherry.mdl",
	price = 2000,
	material = "models/perk_bottle/c_perk_bottle_cherry",
	icon = Material("perk_icons/cherry.png", "smooth unlitgeneric"),
	color = Color(50, 50, 200),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("vulture", {
	name = "Vulture Aid Elixir",
	off_model = "models/alig96/perks/vulture/vultureaid_off.mdl",
	on_model = "models/alig96/perks/vulture/vultureaid.mdl",
	price = 3000,
	material = "models/perk_bottle/c_perk_bottle_vulture",
	icon = Material("perk_icons/vulture.png", "smooth unlitgeneric"),
	color = Color(255, 100, 100),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})

nzPerks:NewPerk("wunderfizz", {
	name = "Der Wunderfizz", -- Nothing more is needed, it is specially handled
	specialmachine = true,
})

nzPerks:NewPerk("widowswine", {
	name = "Widow's Wine",
	model = "models/yolojoenshit/bo3perks/widows_wine/mc_mtl_p7_zm_vending_widows_wine.mdl",
	off_skin = 1,
	on_skin = 0,
	price = 4000,
	material = "models/perk_bottle/c_perk_bottle_widowswine",
	icon = Material("perk_icons/widows_wine.png", "smooth unlitgeneric"),
	color = Color(255, 50, 200),
	func = function(self, ply, machine)
	end,
	lostfunc = function(self, ply)
	end,
})
