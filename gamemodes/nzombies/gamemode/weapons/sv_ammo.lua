-- Functions
-- Ammo tracking (saving/restoring) added by: Ethorbit

-- Somehow there's code where Pack-a-punch MAGICALLY remembers ammo,
-- but since I'm not a fucking wizard I'm just going to add this functionality in
-- and not waste any more of my life trying to figure out how pack-a-punch does it
nzWeps.TrackedAmmo = nzWeps.TrackedAmmo or {}

function nzWeps:TrackAmmo(ply, class)
	local wep = ply:GetWeapon(class)
	if IsValid(wep) and !wep:IsSpecial() then
		-- So my idea was if this weapon gets removed
		-- then that's when we should remember its ammo
		local oldRemove = wep.OnRemove
		wep.OnRemove = function(...)
			if IsValid(ply) then
				local primary_ammo = ply:GetAmmoCount(wep:GetPrimaryAmmoType() or wep.Primary.Ammo)
				local secondary_ammo = ply:GetAmmoCount(wep.Secondary and wep.Secondary.Ammo or "")
				local clip_size1 = (wep.Clip1 and wep:Clip1()) or nil
				local clip_size2 = (wep.Clip2 and wep:Clip2()) or nil

				nzWeps.TrackedAmmo[ply] = nzWeps.TrackedAmmo[ply] or {}
				nzWeps.TrackedAmmo[ply][class] = {
					["defaultclip"] = primary_ammo or 0,
					["secondaryammo"] = secondary_ammo or 0,
					["clipsize1"] = clip_size1 or 0,
					["clipsize2"] = clip_size2 or 0
				}
			end

			oldRemove(...)
		end
	end
end

function nzWeps:GetTrackedAmmo(ply, class)
	return nzWeps.TrackedAmmo[ply] and nzWeps.TrackedAmmo[ply][class] or nil
end

-- Reset the tracked ammos:
hook.Add("OnRoundEnd", "NZ.ResetTrackedGunAmmos", function()
	nzWeps.TrackedAmmo = {}
end)

hook.Add("PlayerDeath", "NZ.ResetTrackedGunAmmoOnDeath", function(ply)
	nzWeps.TrackedAmmo[ply] = {}
end)

hook.Add("OnPlayerDropOut", "NZ.ResetTrackedGunAmmoOnDropOut", function(ply)
	nzWeps.TrackedAmmo[ply] = {}
end)
-------------------------------------------------------------------------------

function nzWeps:CalculateMaxAmmo(class, pap)
	local wep = isentity(class) and class:IsWeapon() and class or weapons.Get(class)
	if !wep then return end

	if wep.Primary then -- Skip all this stupid bullshit and just use the MaxAmmo property defined in the weapon..
		if wep.Primary.MaxAmmo then
			return wep.Primary.MaxAmmo
		end
	end

	local clip = wep.Primary.ClipSize

	if pap then
		clip = math.Round((clip *1.5)/5)* 5
		return clip * 10 <= 500 and clip * 10 or clip * math.ceil(500/clip) -- Cap the ammo to stop at the clip that passes 500 max
	else
		return clip * 10 <= 300 and clip * 10 or clip * math.ceil(300/clip) -- 300 max for non-pap weapons
	end
end

function nzWeps:GiveMaxAmmoWep(ply, class, papoverwrite)

	for k,v in pairs(ply:GetWeapons()) do
		-- If the weapon entity exist, just give ammo on that
		if v:GetClass() == class then v:GiveMaxAmmo(papoverwrite) return end
	end

	-- Else we'll have to refer to the old system (for now, this should never happen)
	local wep = weapons.Get(class)
	if !wep then return end

	-- Weapons can have their own Max Ammo functions that are run instead
	if wep.NZMaxAmmo then wep:NZMaxAmmo() return end

	if !wep.Primary then return end

	local ammo_type = wep.Primary.Ammo
	local max_ammo = nzWeps:CalculateMaxAmmo(class, (IsValid(ply:GetWeapon(class)) and ply:GetWeapon(class):HasNZModifier("pap")) or papoverwrite)

	local curr_ammo = ply:GetAmmoCount( ammo_type )
	local give_ammo = max_ammo - curr_ammo

	--print(give_ammo)

	-- Just for display, since we're setting their ammo anyway
	ply:GiveAmmo(give_ammo, ammo_type)
	ply:SetAmmo(max_ammo, ammo_type)

end

local usesammo = {
	["grenade"] = "nz_grenade",
	["specialgrenade"] = "nz_specialgrenade",
}

local plymeta = FindMetaTable("Player")
function plymeta:GiveMaxAmmo(papoverwrite)
	for k,v in pairs(self:GetWeapons()) do
		if !v:IsSpecial() then
			v:GiveMaxAmmo()
		else
			local wepdata = v.NZSpecialWeaponData
			if wepdata then
				local ammo = usesammo[v:GetSpecialCategory()] or wepdata.AmmoType
				local maxammo = wepdata.MaxAmmo

				if ammo and maxammo then
					self:SetAmmo(maxammo, GetNZAmmoID(ammo) or ammo) -- Special weapon ammo or just that ammo
				end
			end
		end
	end
end

function plymeta:SaveGrenadeAmmo()
	nzWeps.TrackedAmmo = nzWeps.TrackedAmmo or {}
	nzWeps.TrackedAmmo[self] = nzWeps.TrackedAmmo[self] or {}

	local normal_ammotype = GetNZAmmoID("grenade")
	local special_ammotype = GetNZAmmoID("specialgrenade")
	local normal_ammo = normal_ammotype and self:GetAmmoCount(normal_ammotype) or 0
	local special_ammo = special_ammotype and self:GetAmmoCount(special_ammotype) or 0

	nzWeps.TrackedAmmo[self].Grenades = {
		["normal"] = normal_ammo,
		["special"] = special_ammo
	}
end

function plymeta:GetSavedGrenadeAmmo()
	return nzWeps.TrackedAmmo and nzWeps.TrackedAmmo[self] and nzWeps.TrackedAmmo[self].Grenades or nil
end

function plymeta:RestoreGrenadeAmmo()
	timer.Simple(0.1, function() -- Wait for anything else to potentially set the grenade ammo
		if IsValid(self) then
			local ammos = self:GetSavedGrenadeAmmo()
			if ammos then
				local normal_ammotype = GetNZAmmoID("grenade")
				local special_ammotype = GetNZAmmoID("specialgrenade")

				if normal_ammotype and ammos.normal then
					self:SetAmmo(ammos.normal, normal_ammotype)
				end

				if special_ammotype and ammos.special then
					self:SetAmmo(ammos.special, special_ammotype)
				end
			end
		end
	end)
end

local meta = FindMetaTable("Weapon")

function meta:RestoreTrackedAmmo() -- Sets the ammo to what was tracked (but ONLY if it was tracked)
	if self:IsSpecial() then return end

	timer.Simple(0.1, function() -- We wait for TFA/NZ/etc to do whatever ammo changes they want
		if IsValid(self) then
			local owner = self:GetOwner()
			if IsValid(owner) then
				local data = nzWeps:GetTrackedAmmo(self:GetOwner(), self:GetClass())

				if data then
					if data.defaultclip then
						owner:SetAmmo(data.defaultclip, self:GetPrimaryAmmoType() or self.Primary.Ammo)
					end

					if data.secondaryammo then
						local sec_ammo_type = self.Secondary and self.Secondary.Ammo or nil
						if sec_ammo_type then
							owner:SetAmmo(data.secondaryammo, sec_ammo_type)
						end
					end

					if data.clipsize1 then
						self:SetClip1(data.clipsize1)
					end

					if data.clipsize2 then
						self:SetClip2(data.clipsize2)
					end
				end
			end
		end
	end)
end

function meta:CalculateMaxAmmo(papoverwrite)
	if !self.Primary then return 0 end
	if self.Primary.MaxAmmo then return self.Primary.MaxAmmo end -- Added by Ethorbit, WHY WAS THIS NOT IN NZ CLASSIC??
	local clip = self.Primary and self.Primary.ClipSize or self.Primary.ClipSize_Orig
	if !clip then return 0 end
	-- When calculated directly on a weapon entity, its clipsize will already have changed from PaP
	if self:HasNZModifier("pap") or papoverwrite then
		return clip * 10 <= 500 and clip * 10 or clip * math.ceil(500/clip) -- Cap the ammo to stop at the clip that passes 500 max
	else
		return clip * 10 <= 300 and clip * 10 or clip * math.ceil(300/clip) -- 300 max for non-pap weapons
	end
end

function meta:GiveMaxAmmo(papoverwrite)
	--if papoverwrite != nil then
		if self.NZMaxAmmo then self:NZMaxAmmo() return end -- self:NZMaxAmmo(papoverwrite)

	--end

	local ply = self.Owner
	if !IsValid(ply) then return end

	local ammo_type = self:GetPrimaryAmmoType() or self.Primary.Ammo

	local max_ammo = 0
	if self:GetClass() == "nz_grenade" then
		max_ammo = 4
		ammo_type = "nz_grenade"
	else
		max_ammo = self:CalculateMaxAmmo(papoverwrite)
	end


	local curr_ammo = ply:GetAmmoCount( ammo_type )
	local give_ammo = max_ammo - curr_ammo

	-- Just for display, since we're setting their ammo anyway
	ply:GiveAmmo(give_ammo, ammo_type)
	ply:SetAmmo(max_ammo, ammo_type)
end
