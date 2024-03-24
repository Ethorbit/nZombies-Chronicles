-- Moved from server to shared by Ethorbit 
-- Players should have the ability to know about wonder weapon stuff

local soloweapons = soloweapons
local wonderweapons = wonderweapons
if (!istable(soloweapons)) then soloweapons = {} end
if (!istable(wonderweapons)) then wonderweapons = {} end

-- Wonder Weapon system does NOT apply to weapons like Monkey Bombs or Ray Gun
-- ONLY to those that you can only have 1 of at a time

function nzWeps:AddSoloPlayerWeapon(class)
	soloweapons[class] = true
end

function nzWeps:AddWonderWeapon(class)
	wonderweapons[class] = true
end

function nzWeps:RemoveWonderWeapon(class)
	wonderweapons[class] = nil
end

function nzWeps:IsWonderWeapon(class)
	return wonderweapons[class] or false
end

function nzWeps:GetHeldWonderWeapons(ply) -- No arguments means all players
	local tbl = {}
	
	local function Handle(wep)
		if wonderweapons[wep:GetClass()] then
			table.insert(tbl, wep:GetClass())
		end
	end
	
	if IsValid(ply) and ply:IsPlayer() then
		for k,v in pairs(ply:GetWeapons()) do
			Handle(v)
		end
	else
		for k,v in pairs(player.GetAll()) do
			for k2,v2 in pairs(v:GetWeapons()) do
				Handle(v2)
			end
		end
	end
	
	return tbl
end

function nzWeps:IsSoloWeaponInUse(class)
	return nzWeps:IsWonderWeaponOut(class, true)
end

function nzWeps:IsWonderWeaponOut(class, ignorewonder)
	local wepOut = false
	if (wonderweapons[class] or ignorewonder) then
		local tWonderWeps = nzWeps:GetAllReplacements(class)
		table.insert(tWonderWeps, weapons.Get(class))

		local function Handle(class)
			for _,v in pairs(tWonderWeps) do
				if (istable(v) and v.ClassName and v.ClassName == class) then
					return true
				end 
			end

			return false
		end

		for k,v in pairs(player.GetAll()) do
			for k2,v2 in pairs(v:GetWeapons()) do
				local vclass = v2:GetClass()
				local hasWep = Handle(vclass)
				if (hasWep) then
					wepOut = true
					break
				end
			end
		end

		for _,v in pairs(ents.FindByClass("pap_weapon_fly")) do -- Gotta check weapons inside pack-a-punch
			local hasWep = Handle(v:GetWeaponClass())
			if (hasWep) then
				wepOut = true
				break
			end
		end
		
		for _,v in pairs(ents.FindByClass("random_box_windup")) do -- Gotta check active random boxes
			local hasWep = Handle(v:GetWepClass())
			if (hasWep) then
				wepOut = true
				break
			end
		end

		for _,v in pairs(ents.FindByClass("whoswho_downed_clone")) do -- Gotta check Who's Who clones
			for _,b in pairs(v.OwnerData.weps) do
				local hasWep = Handle(b.class)
				if (hasWep) then
					wepOut = true
					break
				end
			end
		end
	end
	return wepOut
end

-- Now let's add some!
nzWeps:AddWonderWeapon("freeze_gun")
nzWeps:AddWonderWeapon("wunderwaffe")
nzWeps:AddWonderWeapon("weapon_hoff_thundergun")
nzWeps:AddWonderWeapon("weapon_teslagun")

local function SetWonderWeps()
	for k,v in pairs(weapons.GetList()) do
		--if v.NZWonderWeapon then print(v.ClassName) end
		-- Add Wonder Weapons to the list
		if v.NZWonderWeapon then nzWeps:AddWonderWeapon(v.ClassName) end

		-- (Added by Ethorbit) it allows previous versions of the weapon to NOT be wonder weapons, but a specific version to only allow one
		if v.NZOnlyAllowOnePlayerToUse then 
			if !nzWeps:Unreplaced(v.ClassName) then -- Solo weapon was designed to be used on a normal weapon's replacement (PaP'd version), so if it's not then just mark it as a Wonder Weapon
				nzWeps:AddWonderWeapon(v.ClassName)
			else
				nzWeps:AddSoloPlayerWeapon(v.ClassName) 
			end
		end

		-- If it has a PaP replacement, blacklist that weapon so it can't be gotten in the box
		if v.NZPaPReplacement then nzConfig.AddWeaponToBlacklist(v.NZPaPReplacement) end
		-- Total blacklisted weapons also need to be added to the box blacklist
		if v.NZTotalBlacklist then nzConfig.AddWeaponToBlacklist(v.ClassName) end
	end	
end

-- We can also add all weapons which have SWEP.NZWonderWeapon = true set in their files
hook.Add("InitPostEntity", "nzRegisterWonderWeaponsByKey", function()
	SetWonderWeps()
end)
SetWonderWeps()

-- More wonder weapons should be added by map scripts for their map - if you think you have one that should officially apply to all maps, add me