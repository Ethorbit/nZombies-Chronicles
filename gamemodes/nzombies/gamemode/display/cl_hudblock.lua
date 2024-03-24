local blockedhuds = {
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

local nzc_health_hud = GetConVar("nzc_health_hud")
local function UpdateHideHud()
	if (nzc_health_hud and nzc_health_hud:GetInt() == 3) then -- They wanna see the default HL2 HUD for some reason...
		blockedhuds["CHudHealth"] = false
		blockedhuds["CHudBattery"] = false
	else
		blockedhuds["CHudHealth"] = true
		blockedhuds["CHudBattery"] = true
	end
end

cvars.RemoveChangeCallback("nzc_health_hud", "HL2DefaultHudUpdater")
cvars.AddChangeCallback("nzc_health_hud", function()
	UpdateHideHud()
end, "HL2DefaultHudUpdater")
UpdateHideHud()

hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if blockedhuds[name] then return false end
	if name == "CHudWeaponSelection" then return !nzRound:InProgress() and !nzRound:InState(ROUND_GO) end -- Has it's own value
	--if name == "CHudHealth" then return !GetConVar("nz_bloodoverlay"):GetBool() end -- Same
end )

