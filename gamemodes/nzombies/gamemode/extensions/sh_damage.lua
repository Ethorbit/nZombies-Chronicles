-- Damage extensions by: Ethorbit, makes dealing with damage a breeze
-- Customized DamageInfo() -------------------------------------
-- Since DamageInfos share the damage table, you index cTakeDmgInfo inside your getters and setters instead of 'self'
local cTakeDmgInfo = FindMetaTable("CTakeDamageInfo")

-- Add our custom dmginfo methods along with default values
local dmginfo_custom_methods = {
	["DamagePercentage"] = 0,
	["ForcedHeadshot"] = false,
	["IsAfterburnDamage"] = false
}

-- Auto add getters and setters, place them above if you don't want this to do it automatically
for funcName,_ in pairs(dmginfo_custom_methods) do
	local getFuncName = "Get" .. funcName
	local setFuncName = "Set" .. funcName

	if !cTakeDmgInfo[getFuncName] then
		cTakeDmgInfo[getFuncName] = function()
			return cTakeDmgInfo[funcName]
		end
	end

	if !cTakeDmgInfo[setFuncName] then
		cTakeDmgInfo[setFuncName] = function(dmginfo, val)
			cTakeDmgInfo[funcName] = val
		end
	end
end

local meleetypes = {
	[DMG_CLUB] = true,
	[DMG_SLASH] = true,
	[DMG_CRUSH] = true,
}

function cTakeDmgInfo:GetIsMeleeDamage() -- TODO: Make this a getter and setter like above that all melee weapons that deal damage utilize
	return meleetypes[self:GetDamageType()]
end
function cTakeDmgInfo:SetIsMeleeDamage() end -- Just in case of mistakes

local explosiontypes = {
	[DMG_BLAST] = true,
	[DMG_BLAST_SURFACE] = true
}

function cTakeDmgInfo:GetIsExplosionDamage() -- So this was actually a mistake, because dTakeDmgInfo.IsExplosionDamage is a thing already and works WAY better. -> Only use if you can improve this. Keeping for compatibility..
	local dmgType = self:GetDamageType()
	return bit.band(dmgType, DMG_BLAST) == DMG_BLAST or bit.band(dmgType, DMG_BLAST_SURFACE) == DMG_BLAST_SURFACE
end

function cTakeDmgInfo:GetIsBulletDamage()
	local dmgType = self:GetDamageType()
	return bit.band(dmgType, DMG_BULLET) == DMG_BULLET
end

function cTakeDmgInfo:GetIsShotgunDamage()
	local wep = self:GetInflictor()
	return self:GetDamageType() == DMG_BUCKSHOT or (IsValid(wep) and wep.Primary and wep.Primary.NumShots and wep.Primary.NumShots > 2)
end

function cTakeDmgInfo:Reset(override)
	for funcName, value in pairs(dmginfo_custom_methods) do
		local setFunc = self["Set" .. funcName]
		local getFunc = self["Get" .. funcName]
		if !setFunc or !getFunc then return end

		if override or getFunc() == nil then
			setFunc(self, value)
		end
	end
end
