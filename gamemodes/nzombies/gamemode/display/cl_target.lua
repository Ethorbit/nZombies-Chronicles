--
nzTarget = {}
local SavedSoloRevs = SavedSoloRevs == nil and 0 or SavedSoloRevs
net.Receive("NZSetSoloRevives", function()
	SavedSoloRevs = net.ReadInt(5)
end)

nzTarget.TraceEnts = {
	["wall_buys"] = function(ent)
		local wepclass = ent:GetWepClass()
		local price = ent:GetPrice()
		local wep = weapons.Get(wepclass)
		if !wep then return "INVALID WEAPON" end
		local name = wep.PrintName
		local ammo_price = math.Round((price - (price % 10))/2)
		local text = ""

		local replacementWep = nil
		local hasReplacement = false
		for _,v in pairs(nzWeps:GetAllReplacements(wepclass)) do
			if isstring(v.ClassName) and LocalPlayer():HasWeapon(v.ClassName) then
				hasReplacement = true
				replacementWep = LocalPlayer():GetWeapon(v.ClassName)
			end
		end

		if !LocalPlayer():HasWeapon( wepclass ) and !hasReplacement and wepclass != "nz_grenade" then
			text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy " .. name .." for " .. price .. " points."
		elseif string.lower(wep.Primary.Ammo) != "none" then
			local function showText(newPrice)
				text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy " .. wep.Primary.Ammo .."  Ammo refill for " .. newPrice .. " points."
			end

			if wepclass == "nz_grenade" then
				local nade = LocalPlayer():GetItem("grenade")
				if (LocalPlayer():HasPerk("widowswine") and (!nade or nade and nade.price < 4000)) then
					showText(4000)
				elseif (nade and ammo_price < nade.price) then
					showText(nade.price)
				else
					showText(ammo_price)
				end
			else
				local wep = LocalPlayer():GetWeapon( wepclass )
				if (!IsValid(wep) and IsValid(replacementWep)) then
					for _,v in pairs(nzWeps:GetAllReplacements(wepclass)) do
						if (isstring(v.ClassName) and LocalPlayer():HasWeapon(v.ClassName)) then
							wep = LocalPlayer():GetWeapon(v.ClassName)
						end
					end
				end

				if IsValid(wep) and wep:HasNZModifier("pap") or hasReplacement then
					text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy " .. wep.Primary.Ammo .."  Ammo refill for " .. 4500 .. " points."
				else
					text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy " .. wep.Primary.Ammo .."  Ammo refill for " .. ammo_price .. " points."
				end
			end
		else
			text = "You already have this weapon."
		end

		if (!LocalPlayer():GetNotDowned()) then
			text = "You cannot buy this when down."
		end

		return text
	end,
	["breakable_entry"] = function(ent)
		if ent:GetHasPlanks() and ent:GetNumPlanks() < GetConVar("nz_difficulty_barricade_planks_max"):GetInt() then
			local text = "Hold " .. nzDisplay.GetKeyFromCommand("+use") .. " to rebuild the barricade."

			if (!LocalPlayer():GetNotDowned()) then
				text = "You cannot rebuild this when down."
			end

			return text
		end
	end,
	["random_box"] = function(ent)
		if !ent:GetOpen() then
			local text = nzPowerUps:IsPowerupActive("firesale") and "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy a random weapon for 10 points." or "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy a random weapon for 950 points."

			if (!LocalPlayer():GetNotDowned()) then
				text = "You cannot buy this when down."
			end

			return text
		end
	end,
	["random_box_windup"] = function(ent)
		if !ent:GetWinding() and ent:GetWepClass() != "nz_box_teddy" then
			local wepclass = ent:GetWepClass()
			local wep = weapons.Get(wepclass)
			local name = "UNKNOWN"
			if wep != nil then
				name = wep.PrintName
			end
			if name == nil then name = wepclass end
			name = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to take " .. name .. " from the box."

			if (!LocalPlayer():GetNotDowned()) then
				name = "You cannot take this when down."
			end

			return name
		end
	end,
	["perk_machine"] = function(ent)
		local text = ""
		if !ent:IsOn() then
			text = "No Power."
		elseif ent:GetBeingUsed() then
			text = "Currently in use."
		else
			if ent:GetPerkID() == "pap" then
				local wep = LocalPlayer():GetActiveWeapon()
				local replacement = IsValid(wep) and nzWeps:GetReplacement(wep:GetClass())
				if IsValid(wep) and replacement and replacement.NZOnlyAllowOnePlayerToUse and nzWeps:IsSoloWeaponInUse(replacement.ClassName) then
					text = "Only one player is allowed to have this upgraded at a time."
				else
					if IsValid(wep) and wep:HasNZModifier("pap") then
						if wep.NZRePaPText then
							text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to "..wep.NZRePaPText.." for 2000 points."
						elseif wep:CanRerollPaP() then
							if wep.AllowReRollAtts and !nzWeps:IsReplaceable(wep:GetClass()) then
								text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to reroll attachments for 2000 points."
							elseif !wep.NZRePaPText and !wep.NZPaPReplacement then -- Replaceable weapons can be PaP-exploited for more ammo
								text = "Weapon fully upgraded."
							else
								text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to upgrade weapon for 2000 points."
							end
						else
							text = "This weapon is already upgraded."
						end
					else
						if (wep.IsSpecial and wep:IsSpecial()) then
							text = "You cannot pack-a-punch this."
						else
							text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy Pack-a-Punch for 5000 points."
						end
					end
				end
			else
				local perkData = nzPerks:Get(ent:GetPerkID())

				-- Its on
				if (perkData.name == "Quick Revive" and SavedSoloRevs and SavedSoloRevs >= 3 and #player.GetAllPlaying() <= 1) then
					text = "No revives left."
				elseif (#LocalPlayer():GetPerks() >= GetConVar("nz_difficulty_perks_max"):GetInt()) then
					text = "Too many perks."
				else
					text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy " .. perkData.name .. " for " .. ent:GetPrice() .. " points."
				end
				-- Check if they already own it
				if LocalPlayer():HasPerk(ent:GetPerkID()) then
					text = "You already own this perk."
				end
			end

			if (!LocalPlayer():GetNotDowned()) then
				text = "You cannot buy this when down."
			end
		end

		return text
	end,
	["player_spawns"] = function() if nzRound:InState( ROUND_CREATE ) then return "Player Spawn" end end,
	["nz_spawn_zombie_normal"] = function() if nzRound:InState( ROUND_CREATE ) then return "Zombie Spawn" end end,
	["nz_spawn_zombie_special"] = function() if nzRound:InState( ROUND_CREATE ) then return "Zombie Special Spawn" end end,
	["pap_weapon_trigger"] = function(ent)
		local wepclass = ent:GetWepClass()
		local wep = weapons.Get(wepclass)
		local name = "UNKNOWN"
		if wep != nil then
			--name = nz.Display_PaPNames[wepclass] or nz.Display_PaPNames[wep.PrintName] or "Upgraded "..wep.PrintName
			-- ^^^ ok who wrote this gross crap, please stop
			name = wep.NZPaPName or "Upgraded "..wep.PrintName
		end
		name = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to take " .. name .. " from the machine."

		if (!LocalPlayer():GetNotDowned()) then
			name = "You cannot take this when down."
		end

		return name
	end,
	["wunderfizz_machine"] = function(ent)
		local text = ""
		if !ent:IsOn() then
			text = "The Wunderfizz Orb is currently at another location."
		elseif ent:GetBeingUsed() then
			if ent:GetUser() == LocalPlayer() and ent:GetPerkID() != "" and !ent:GetIsTeddy() then
				if #LocalPlayer():GetPerks() >= GetConVar("nz_difficulty_perks_max"):GetInt() then
					text = "You have too many perks."
				else
					text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to take "..nzPerks:Get(ent:GetPerkID()).name.." from Der Wunderfizz."
				end
			else
				text = "Currently in use."
			end
		else
			if #LocalPlayer():GetPerks() >= GetConVar("nz_difficulty_perks_max"):GetInt() then
				text = "You have too many perks."
			else
				text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to buy Der Wunderfizz for " .. ent:GetPrice() .. " points."
			end
		end

		if (!LocalPlayer():GetNotDowned()) then
			text = "You cannot buy this when down."
		end

		return text
	end,
	["nz_teleporter"] = function(ent)
		local text = ""
		if !ent:GetUseable() then return text end

		if !nzElec:IsOn() then
			text = "No Power."
		elseif ent:GetBeingUsed() then
			text = "Currently in use."
		elseif ent:GetOnCooldown() then
			text = "Teleporter on cooldown!"
		else
			if #ent:GetDestinationsUnlocked() <= 0 then
				text = "A door must be unlocked for this."
			else
				-- Its on
				text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to Teleport for " .. ent:GetPrice() .. " points."
			end
		end

		if !LocalPlayer():GetNotDowned() then
			text = "You cannot use this when down."
		end

		if LocalPlayer():IsInCreative() then
			text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to Test Teleporter"
		elseif #ent:GetDestinations() <= 0 then
			text = "This cannot be used, it is improperly configured."
		end

		return text
	end,
}

nzTarget.GetTarget = function()
	local tr =  {
		start = EyePos(),
		endpos = EyePos() + LocalPlayer():GetAimVector()*150,
		filter = function(ent) return ent != LocalPlayer() and !ent.NZDisallowText end,
		mask = MASK_ALL
	}
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	if (!trace.HitNonWorld) then return end

	return trace.Entity
end

nzTarget.GetDoorText = function(ent)
	local door_data = ent:GetDoorData()
	local text = ""

	if door_data and tonumber(door_data.price) == 0 and nzRound:InState(ROUND_CREATE) then
		if tobool(door_data.elec) then
			text = "This door will open when electricity is turned on."
		else
			text = "This door will open on game start."
		end
	elseif door_data and tonumber(door_data.buyable) == 1 then
		local price = tonumber(door_data.price)
		local req_elec = tobool(door_data.elec)
		local link = door_data.link

		if ent:IsLocked() then
			if req_elec and !IsElec() then
				text = "You must turn on the electricity first!"
			elseif door_data.text then
				text = door_data.text
			elseif price != 0 then
				--print("Still here", nz.nzDoors.Data.OpenedLinks[tonumber(link)])
				text = "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to open for " .. price .. " points."
			end

			if (!LocalPlayer():GetNotDowned()) then
				text = "You cannot buy this when down."
			end
		end
	elseif ent:GetClass() != "wall_block" and ent.Base != "wall_block" and door_data and tonumber(door_data.buyable) != 1 and nzRound:InState( ROUND_CREATE ) then
		text = "This door is locked and cannot be bought in-game."
		--PrintTable(door_data)
	end

	return text
end

nzTarget.GetText = function(ent)

	if !IsValid(ent) then return "" end

	if ent.GetNZTargetText then return ent:GetNZTargetText() end

	local class = ent:GetClass()
	local text = ""

	local neededcategory, deftext, hastext = ent:GetNWString("NZRequiredItem"), ent:GetNWString("NZText"), ent:GetNWString("NZHasText")
	local itemcategory = ent:GetNWString("NZItemCategory")

	if neededcategory != "" then
		local hasitem = LocalPlayer():HasCarryItem(neededcategory)
		text = hasitem and hastext != "" and hastext or deftext
	elseif deftext != "" then
		text = deftext
	elseif ent:IsPlayer() then
		if !ent.GetTeleporterEntity or (ent.GetTeleporterEntity and !IsValid(ent:GetTeleporterEntity())) then -- Do not show their name if they are teleporting
			if ent:GetNotDowned() then
				text = ent:Nick() .. " - " .. ent:Health() .. " HP"
			else
				if (!LocalPlayer():IsSpectating() && LocalPlayer():GetNotDowned()) then
					text = "Hold " .. nzDisplay.GetKeyFromCommand("+use") .. " to revive "..ent:Nick()
				else
					text = ent:Nick() .. " - Downed"
				end
			end
		end
	elseif ent:IsDoor() or ent:IsButton() or ent:GetClass() == "class C_BaseEntity" or ent:IsBuyableProp() then
		text = nzTarget.GetDoorText(ent)
	else
		text = nzTarget and nzTarget.TraceEnts[class] and nzTarget.TraceEnts[class](ent)
	end

	return text
end

nzTarget.GetMapScriptEntityText = function()
	local text = ""

	for k,v in pairs(ents.FindByClass("nz_script_triggerzone")) do
		local dist = v:NearestPoint(EyePos()):Distance(EyePos())
		if dist <= 1 then
			text = nzTarget.GetDoorText(v)
			break
		end
	end

	return text
end

local function DrawTargetID( text )

	if !text then return end

	local font = "nz.display.hud.small"
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )

	local MouseX, MouseY = gui.MousePos()

	if ( MouseX == 0 && MouseY == 0 ) then

		MouseX = ScrW() / 2
		MouseY = ScrH() / 2

	end

	local x = MouseX
	local y = MouseY

	x = x - w / 2
	y = y + 30

	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText( text, font, x+1, y+1, Color(255,255,255,255) )
end


function GM:HUDDrawTargetID()

	local ent = nzTarget.GetTarget()

	if ent != nil then
		DrawTargetID(nzTarget.GetText(ent))
	else
		DrawTargetID(nzTarget.GetMapScriptEntityText())
	end

end
