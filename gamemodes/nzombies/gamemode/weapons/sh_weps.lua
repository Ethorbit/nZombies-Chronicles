-- Added by Ethorbit to make playing PaP shoot sounds easier
-- PaP Sound chooser will override this upon selection and
-- weapons will play this through Sound("NZ_PaP_Shoot_Sound")
sound.Add({
	name = "NZ_PaP_Shoot_Sound",
	channel = CHAN_WEAPON,
	volume = 0.6,
	level = 60,
	pitch = {80, 110},
	sound = "nzr/effects/pap_laser_shot_0.wav"
})

-- Auto Reload and FOV is in function_override/sh_meta.lua /Ethorbit
local wepMeta = FindMetaTable("Weapon")

-- function wepMeta:NZMaxAmmo() -- Replaced TFA's version with Chtidino's
--
-- 	local ammo_type = self:GetPrimaryAmmoType() or self.Primary.Ammo
--
--     if SERVER then
--         self.Owner:SetAmmo( self.Primary.MaxAmmo, ammo_type )
-- 		self:SetClip1( self.Primary.ClipSize )
--     end
-- end

function wepMeta:GetPaP() -- Moved from TFA Base here, as this is where it actually belongs /Ethorbit
	return ( self.HasNZModifier and self:HasNZModifier("pap") ) or self.pap or false
end

function wepMeta:IsPaP() -- Moved from TFA Base here, as this is where it actually belongs /Ethorbit
	return self:GetPaP()
end

function nzWeps:GetAllOtherVariants(class) -- Gets all other weapon variants of the passed weapon class, created by Ethorbit
	--local startTime = os.clock()

	local wep_class = !isentity(class) and class or class:GetClass()
	if !wep_class then return {} end

	local unpapd_wep = nzWeps:Unreplaced(wep_class)

	if !unpapd_wep then -- Unreplaced returned nil because this already is the most downgraded version of the weapon
		unpapd_wep = wep_class
	elseif unpapd_wep.ClassName then
		unpapd_wep = unpapd_wep.ClassName
		if !unpapd_wep then return {} end
	end


	local tbl = {}
	-- Add all upgrades that aren't what we passed in
	if unpapd_wep != wep_class then
		tbl[1] = unpapd_wep
	end

	for _,wepTbl in pairs(self:GetAllReplacements(unpapd_wep)) do
		if wepTbl.ClassName and wepTbl.ClassName != wep_class then
			tbl[#tbl + 1] = wepTbl.ClassName
		end
	end

	--print(os.clock() - startTime) -- Another developer can speed all these functions up if they want, currently this runs at 0.001 for ANY weapon

	return tbl
end

function nzWeps:GetReplacement(class) -- The weapon that the one provided turns into when PaP'd, created by Ethorbit
	local selectedWep = weapons.Get(class)
	local replacement = ""
	if istable(selectedWep) then
		replacement = selectedWep.NZPaPReplacement
	end

	if (isstring(replacement)) then return weapons.Get(replacement) end
end

function wepMeta:GetReplacement() -- The weapon that the one provided turns into when PaP'd, created by Ethorbit
	return nzWeps:GetReplacement(self:GetClass())
end

function nzWeps:Unreplaced(class) -- Get the weapon an upgraded weapon is when it's not PaP'd, created by Ethorbit
	local unreplaced = nzWeps:GetReplaceChild(class)
	if unreplaced then
		for i = 1, 100 do -- While loop not needed, but feel free to turn this into one
			local nextUnreplaced = nzWeps:GetReplaceChild(unreplaced.ClassName)
			if (istable(nextUnreplaced)) then
				unreplaced = nextUnreplaced
			else
				break
			end
		end
		return unreplaced
	end
end

function nzWeps:IsReplaceable(class) -- Due to Unreplaced and GetReplaceChild, this function is actually slow. Use it sparingly! Created by Ethorbit
	local unrep = nzWeps:Unreplaced(class)
	return istable(unrep) and nzWeps:GetReplacement(unrep.ClassName)
end

function nzWeps:GetAllReplacements(class) -- All weapons that this one can turn into when PaPing, created by Ethorbit
	local replacements = {}
	local newClass = nzWeps:GetReplacement(class)

	for i = 1, 100 do -- While loop not needed, but feel free to turn this into one
		if !istable(newClass) then break end
		local shouldStop = false
		for _,v in pairs(replacements) do
			if (v.ClassName == newClass.ClassName) then
				shouldStop = true
				break
			end
		end

		if (shouldStop) then break end -- Could stop repeating the same values over and over if both weapons reference eachother as replacements
		table.insert(replacements, newClass)
		newClass = nzWeps:GetReplacement(newClass.ClassName)
	end

	return replacements
end

function wepMeta:GetAllReplacements() -- All weapons that this one can turn into when PaPing, created by Ethorbit
	return nzWeps:GetAllReplacements(self:GetClass())
end

function nzWeps:GetReplaceChild(class) -- What this weapon was before it was turned into another weapon via PaPing, created by Ethorbit
	local replacedBy = nil
	for _,v in pairs(weapons.GetList()) do
		if (isstring(v.NZPaPReplacement)) then
			if (v.NZPaPReplacement == class) then
				replacedBy = v
			end
		end
	end

	return replacedBy
end

function wepMeta:GetReplaceChild() -- What this weapon was before it was turned into another weapon via PaPing, created by Ethorbit
	return nzWeps:ReplacedBy(self:GetClass())
end

function wepMeta:NZPerkSpecialTreatment( )
	if self:IsFAS2() or self:IsCW2() or self:IsTFA() then
		return true
	end

	return false
end

function wepMeta:IsFAS2()
	if self.Category == "FA:S 2 Weapons" or self.Base == "fas2_base" then
		return true
	else
		local base = weapons.Get(self.Base)
		if base and base.Base == "fas2_base" then
			return true
		end
	end

	return false
end

function wepMeta:IsCW2()
	if self.Category == "CW 2.0" or self.Base == "cw_base" then
		return true
	else
		local base = weapons.Get(self.Base)
		if base and base.Base == "cw_base" then
			return true
		end
	end

	return false
end

function wepMeta:IsTFA()
	if self.Category == "TFA" or self.Base == "tfa_gun_base" or string.sub(self:GetClass(), 1, 3) == "tfa" then
		return true
	else
		local base = weapons.Get(self.Base)
		if base and base.Base == "tfa_gun_base" then
			return true
		end
	end

	return false
end

function wepMeta:CanRerollPaP()
	return (self.OnRePaP or (self.Attachments and ((self:IsCW2() and CustomizableWeaponry) or self:IsTFA()) or self:IsFAS2()))
end

local old = wepMeta.GetPrintName
function wepMeta:GetPrintName()
	local name = old(self)
	if !name or name == "" then name = self:GetClass() end
	if self:HasNZModifier("pap") then -- string.sub(name, 1, 8) != "Upgraded"  -- stops duplicate Upgraded text, but is hard on performance
		name = self.NZPaPName or nz.Display_PaPNames[self:GetClass()] or nz.Display_PaPNames[name] or "Upgraded "..name
	end
	return name
end

-- Cancel sprint on reload, don't allow sprint until reload is finished:
