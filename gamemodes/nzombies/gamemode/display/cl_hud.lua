--
nzDisplay = nzDisplay or AddNZModule("Display")
nzDisplay.IsSmallScreen = function()
	return ScrW() < 1100
end

function nzDisplay:GetPlayer(mode) -- Gets local player or the player the local player is spectating, created by Ethorbit for better HUD support
 	if !LocalPlayer():IsSpectating() then return LocalPlayer() end
 	if mode and LocalPlayer():GetObserverMode() != mode then return LocalPlayer() end -- They only care about who we're spectating if we're in a certain spectator mode
	local targ = LocalPlayer():GetObserverTarget()
	return (IsValid(targ) and targ:IsPlayer() and targ) or LocalPlayer()
end

local bloodline_points = Material("bloodline_score2.png", "unlitgeneric smooth")
local bloodline_gun = Material("cod_hud.png", "unlitgeneric smooth")

--[[local bloodDecals = {
	Material("decals/blood1"),
	Material("decals/blood2"),
	Material("decals/blood3"),
	Material("decals/blood4"),
	Material("decals/blood5"),
	Material("decals/blood6"),
	Material("decals/blood7"),
	Material("decals/blood8"),
	nil
}]]

local spawn_icon_cache = spawn_icon_cache or {}
function nzDisplay.GetSpawnIcon(model) -- Zet0r's bigbrain spawnicon hack, taken from nZombies Unlimited
	-- Return cached version if it exists
	local res = spawn_icon_cache[model]
	if res then return res end

	-- Hasn't been cached yet, do it now
	spawn_icon_cache[model] = Material("spawnicons/"..string.gsub(model,".mdl",".png"), "unlitgeneric smooth")

	-- local returnVal = spawn_icon_cache[model]
	--
	-- if (returnVal:IsError()) then
	-- (UH what can we do to fix this??? This can happen, especially with addons like Outfitter)
	-- 	spawn_icon_cache[model] =
	-- end

	return spawn_icon_cache[model]
end

local command_bind_cache = command_bind_cache or {}
function nzDisplay.GetKeyFromCommand(command) -- Added by Ethorbit so we can stop hardcoding "E" in to the pressing text
	if command_bind_cache[command] then return command_bind_cache[command] end

	-- Not cached, do it now
	local bind = input.LookupBinding(command)
	if !bind or #bind == 0 then
		bind = "[UNBOUND]"
	end

	command_bind_cache[command] = string.upper(bind)
	return command_bind_cache[command]
end

local healthIcon = Material("nzc/hud/healthheart.png")
local armorIcon = Material("nzc/hud/shield.png")
local hpColor = Color(255, 255, 255)
local hpLowColor = Color(255, 0, 0)
local hpHudEnabled = CreateClientConVar("nzc_health_hud", 1, true, false, "Enable/Disable the health & armor display")

local function HealthHud() -- Made by Ethorbit to make the Health/Armor HUD look better, ^ materials by: Berb (Thanks to him for that!)
	if (hpHudEnabled:GetInt() == 1 or hpHudEnabled:GetInt() == 2) then
		local player = nzDisplay:GetPlayer()
		local small_screen = nzDisplay.IsSmallScreen()

		if (IsValid(player) and player:Alive() and player:GetNotDowned()) then
			local icon_scale = (!small_screen and 38 or 30)

			if (hpHudEnabled:GetInt() == 1) then -- HP and Armor
				surface.SetDrawColor(255, 100, 100)
				surface.SetMaterial(healthIcon)
				surface.DrawTexturedRect(35, ScrH() - (!small_screen and 50 or 40), icon_scale, icon_scale)
				surface.SetFont(!small_screen and "BigHP" or "SmallHP")

				if (player:HasPerk("jugg") and player:Health() <= 60 or player:Health() <= 50) then
					surface.SetTextColor(hpLowColor)
				else
					surface.SetTextColor(hpColor)
				end

				surface.SetTextPos(!small_screen and 85 or 75, ScrH() - (!small_screen and 53 or 43))
				surface.DrawText(player:Health())

				if (player:Armor() > 0) then
					surface.SetDrawColor(100, 100, 255)
					surface.SetMaterial(armorIcon)
					surface.DrawTexturedRect(!small_screen and 180 or 160, ScrH() - (!small_screen and 50 or 40), icon_scale, icon_scale)

					surface.SetTextPos(!small_screen and 230 or 200, ScrH() - (!small_screen and 53 or 43))
					surface.DrawText(player:Armor())
				end
			elseif (hpHudEnabled:GetInt() == 2) then -- Armor only
				surface.SetFont(!small_screen and "BigHP" or "SmallHP")
				surface.SetTextColor(hpColor)

				if (player:Armor() > 0) then
					surface.SetDrawColor(100, 100, 255)
					surface.SetMaterial(armorIcon)
					surface.DrawTexturedRect(35, ScrH() - (!small_screen and 50 or 40), icon_scale, icon_scale)

					surface.SetTextPos(!small_screen and 85 or 75, ScrH() - (!small_screen and 53 or 43))
					surface.DrawText(player:Armor())
				end
			end
		end
	end
end

CreateClientConVar( "nz_hud_points_show_names", "1", true, false )

local function StatesHud()
	if GetConVar("cl_drawhud"):GetBool() then
		local text = ""
		local font = "nz.display.hud.main"
		local w = ScrW() / 2
		if nzRound:InState( ROUND_WAITING ) then
			text = "Waiting for players. Type /ready to ready up."
			font = "nz.display.hud.small"
		elseif nzRound:InState( ROUND_CREATE ) then
			text = "Creative Mode"
		elseif nzRound:InState( ROUND_GO ) then
			text = "Game Over"
		end
		draw.SimpleText(text, font, w, ScrH() * 0.85, Color(200, 0, 0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local tbl = {Entity(3), Entity(1), Entity(3), Entity(4), Entity(5),}

local function ScoreHud() -- Heavily modified by Ethorbit, more accurate to COD and better Multiplayer support
	if GetConVar("cl_drawhud"):GetBool() then
		if nzRound:InProgress() then

			local scale = (ScrW() / 1920 + 1) / 2
			local offset = 0

			local small_screen = nzDisplay.IsSmallScreen()

			local display_tbl = player.GetAll()
			--display_tbl[0] = LocalPlayer() -- (Uncomment for local player always first) Fastest way to inject ourselves as the first value

			for k,v in pairs(display_tbl) do
				if offset >= (ScrH() - 350) then break end
				--if (Uncomment for local player always first) v == LocalPlayer() and k != 0 then continue end

				local hp = v:Health()
				if hp == 0 then hp = "Dead" elseif nzRevive.Players[v:EntIndex()] then hp = "Downed" else hp = hp .. " HP"  end
				if v:GetPoints() >= 0 then
					local text = ""
					local nameoffset = 0
					if GetConVar("nz_hud_points_show_names"):GetBool() then
						local nick
						if #v:Nick() >= 20 then
							nick = string.sub(v:Nick(), 1, 20)  -- limit name to 20 chars
						else
							nick = v:Nick()
						end
						text = nick
						nameoffset = 10
					end

					local font = !small_screen and "nz.display.hud.small" or "nz.display.hud.tiny"

					surface.SetFont(font)

					local textW, textH = surface.GetTextSize(text)

					if LocalPlayer() == v then
						offset = offset + textH + 19 -- change this if you change the size of nz.display.hud.medium
					else
						offset = offset + textH + 19
					end

					surface.SetDrawColor(200,200,200)

					if (!isfunction(player.GetColorByIndex)) then return end
					local index = v:EntIndex()
					local color = player.GetColorByIndex(v:EntIndex())
					local blood = player.GetBloodByIndex(v:EntIndex())
					--for i = 0, 8 do
						--surface.SetMaterial(bloodDecals[((index + i - 1) % #bloodDecals) + 1 ])
						surface.SetMaterial(blood)
						local hScale = !small_screen and 45 or 35
						surface.DrawTexturedRect(ScrW() - textW - (!small_screen and 195 or 135), ScrH() - 270 * scale - offset, textW + (!small_screen and 150 or 90), hScale)
					--end
					--surface.DrawTexturedRect(ScrW() - 325*scale - numname * 10, ScrH() - 285*scale - (30*k), 250 + numname*10, 35)
					if text then draw.SimpleText(text, font, ScrW() - textW - (!small_screen and 60 or 40), ScrH() - 255 * scale - offset, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end

					if LocalPlayer() == v then
						font = !small_screen and "nz.display.hud.medium" or "nz.display.hud.smaller"
					end

					draw.SimpleText(v:GetPoints(), font, ScrW() - textW - (!small_screen and 60 or 37) - nameoffset, ScrH() - 255 * scale - offset, color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					v.PointsSpawnPosition = {x = ScrW() - textW - 170, y = ScrH() - 255 * scale - offset}

					local pmpath = nzDisplay.GetSpawnIcon(v:GetModel())
					if !pmpath:IsError() then
						surface.SetMaterial(pmpath)
						surface.SetDrawColor(255, 255, 255)
						local iconSize = !small_screen and 35 or 25
						surface.DrawTexturedRect(ScrW() - (!small_screen and 40 or 30), (ScrH() - 255 * scale - offset) - 10, iconSize, iconSize)
						surface.SetDrawColor(color)
					end
				end
			end
		end
	end
end

local function GunHud() -- Spectator support added by Ethorbit
	if GetConVar("cl_drawhud"):GetBool() then
		if !LocalPlayer():IsNZMenuOpen() then
			local small_screen = nzDisplay.IsSmallScreen()
			local player = nzDisplay:GetPlayer()
			local isSpecPly = LocalPlayer():IsSpectating()

			if (IsValid(player)) then
				local wep = player:GetActiveWeapon()
				local w,h = ScrW(), ScrH()
				local scale = ((w/1920)+1)/2

				if !NZSelectedGunHUD then
					NZSelectedGunHUD = bloodline_gun
				end

				surface.SetMaterial(NZSelectedGunHUD)
				surface.SetDrawColor(200,200,200)
				surface.DrawTexturedRect(w - 630*scale, h - 225*scale, 600*scale, 225*scale)
				if IsValid(wep) then
					if wep:GetClass() == "nz_multi_tool" then
						draw.SimpleTextOutlined(nzTools.ToolData[wep.ToolMode].displayname or wep.ToolMode, "nz.display.hud.small", w - 240*scale, h - 125*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 2, color_black)
						draw.SimpleTextOutlined(nzTools.ToolData[wep.ToolMode].desc or "", "nz.display.hud.smaller", w - 240*scale, h - 90*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, color_black)
						
					else
						local name = wep:GetPrintName()
						local x = 250
						local y = 165
						if wep:GetPrimaryAmmoType() != -1 then
							local clip
							if wep.Primary and wep.Primary.ClipSize and wep.Primary.ClipSize != -1 then
								local xdammo = !isSpecPly and wep:Ammo1() or player:GetNWInt("Spec_PrimaryAmmo")
								draw.SimpleTextOutlined("/".. xdammo, "nz.display.hud.ammo2", ScrW() - 310*scale - 2, ScrH() - 87*scale, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 0, color_black)
								draw.SimpleTextOutlined("/".. xdammo, "nz.display.hud.ammo2", ScrW() - 310*scale - 5, ScrH() - 90*scale, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 0, color_black)
								clip = !isSpecPly and wep:Clip1() or player:GetNWInt("Spec_Clip1")
								x = 315
								y = 155
							elseif (wep.Ammo1) then
								clip = !isSpecPly and wep:Ammo1() or player:GetNWInt("Spec_PrimaryAmmo")
							end
							draw.SimpleTextOutlined(clip, "nz.display.hud.ammo", ScrW() - x*scale - 2	, ScrH() - 82*scale, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 0, color_black)
							draw.SimpleTextOutlined(clip, "nz.display.hud.ammo", ScrW() - x*scale - 5 , ScrH() - 85*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 0, color_black)
							x = x - 50
						end

						draw.SimpleTextOutlined(name, "nz.display.hud.small", ScrW() - x*scale, ScrH() - 160*scale, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 0, color_black)
						draw.SimpleTextOutlined(name, "nz.display.hud.small", ScrW() - x*scale - 2	, ScrH() - 162*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 0, color_white)
						x = 270
						if wep:GetSecondaryAmmoType() != -1 then
							local clip
							if wep.Secondary and wep.Secondary.ClipSize and wep.Secondary.ClipSize != -1 then
								draw.SimpleTextOutlined("/"..wep:Ammo2(), "nz.display.hud.ammo4", ScrW() - x*scale, ScrH() - y*scale, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 2, color_black)
								clip = !isSpecPly and wep:Clip2() or player:GetNWInt("Spec_Clip2")
								x = x + 3
							else
								clip = !isSpecPly and wep:Ammo2() or player:GetNWInt("Spec_SecondaryAmmo")
							end

							draw.SimpleTextOutlined(clip, "nz.display.hud.ammo3", ScrW() - x*scale, ScrH() - y*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 2, color_black)
							x = x + 80
						end

						--[[if clip >= 0 then
							draw.SimpleTextOutlined(name, "nz.display.hud.small", ScrW() - 390*scale, ScrH() - 120*scale, Color(255,255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
							draw.SimpleTextOutlined(clip, "nz.display.hud.ammo", ScrW() - 315*scale, ScrH() - 115*scale, Color(255,255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
							draw.SimpleTextOutlined("/"..wep:Ammo1(), "nz.display.hud.ammo2", ScrW() - 310*scale, ScrH() - 120*scale, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
						else
							draw.SimpleTextOutlined(name, "nz.display.hud.small", ScrW() - 250*scale, ScrH() - 120*scale, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 2, color_black)
						end]]
					end
				end
			end
		end
	end
end

local max_ammo = Material("chron/perk_icons/maxammo.png", "unlitgeneric smooth")
local powerup_death_machine_icon = Material("nzc/powerup_huds/sam/death_machine.png", "unlitgeneric smooth")
local powerup_zombie_blood_icon = Material("nzc/powerup_huds/sam/zombie_blood.png", "unlitgeneric smooth")
local powerup_double_points_icon = Material("nzc/powerup_huds/sam/doublepointsicon.png", "unlitgeneric smooth")
local powerup_insta_kill_icon = Material("nzc/powerup_huds/sam/insta_kill.png", "unlitgeneric smooth")
local powerup_firesale_icon = Material("nzc/powerup_huds/sam/fire_sale.png", "unlitgeneric smooth")
local fadeouttime = nil
local fadeout = 0
local totalWidth = 0

net.Receive("RenderMaxAmmo", function() -- Max Ammo animation by Ethorbit, requested by DoorMatt and icons were created by Sam
	local alpha = 0
	local fadeout = 0
	local fadeouttime = nil

	hook.Add("HUDPaint", "NZMaxAmmoImg", function()
		if fadeouttime == nil then fadeouttime = CurTime() + 3 end -- We want the max ammo to fade out after 5 seconds..

		if CurTime() < fadeouttime and alpha < 255 then
			alpha = alpha + 50
		end

		if CurTime() > fadeouttime then
			if CurTime() > fadeout then
				fadeout = CurTime() + 0.05
				alpha = alpha - 100
			end
		end

		surface.SetMaterial(max_ammo)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawTexturedRect(ScrW() / 2 - 280 / 2, 50, 280, 180)
	end)

	timer.Simple(5, function()
		hook.Remove("HUDPaint", "NZMaxAmmoImg")
	end)
end)

-- Change:
local powerup_icon_width = 60
local powerup_icon_height = 60
local powerup_width_spacing = 70
local powerup_height_spacing = 45
local powerup_font = "nz.display.hud.main"
local powerup_font_height_spacing = 80

local function PowerUpsHud() -- Heavily modified by Ethorbit for centered powerup icons, custom icons, spectator support and  better optimization
	if nzRound:InProgress() or nzRound:InState(ROUND_CREATE) then
		---------icon--------------
		local icon_tbl = {}

		if (!NZCustomPowerupsHUD) then NZCustomPowerupsHUD = {} end
		for k,v in pairs(nzPowerUps.ActivePowerUps) do
			if nzPowerUps:IsPowerupActive(k) then
				if k == "dp" then
					if !NZCustomPowerupsHUD["doublepoints"] then
						NZCustomPowerupsHUD["doublepoints"] = powerup_double_points_icon
					end

					icon_tbl[#icon_tbl + 1] = {NZCustomPowerupsHUD["doublepoints"], v}
				end

				if k == "insta" then
					if !NZCustomPowerupsHUD["instakill"] then
						NZCustomPowerupsHUD["instakill"] = powerup_insta_kill_icon
					end

					icon_tbl[#icon_tbl + 1] = {NZCustomPowerupsHUD["instakill"], v}
				end

				if k == "firesale" then
					if !NZCustomPowerupsHUD["firesale"] then
						NZCustomPowerupsHUD["firesale"] = powerup_firesale_icon
					end

					icon_tbl[#icon_tbl + 1] = {NZCustomPowerupsHUD["firesale"], v}
				end
			end
		end

		local player = nzDisplay:GetPlayer()
		if !nzPowerUps.ActivePlayerPowerUps[player] then nzPowerUps.ActivePlayerPowerUps[player] = {} end
		for k,v in pairs(nzPowerUps.ActivePlayerPowerUps[player]) do
			if nzPowerUps:IsPlayerPowerupActive(player, k) then
				if k == "zombieblood" then
					if !NZCustomPowerupsHUD["zombieblood"] then
						NZCustomPowerupsHUD["zombieblood"] = powerup_zombie_blood_icon
					end

					icon_tbl[#icon_tbl + 1] = {NZCustomPowerupsHUD["zombieblood"], v}
				end

				if k == "deathmachine" then
					if !NZCustomPowerupsHUD["deathmachine"] then
						NZCustomPowerupsHUD["deathmachine"] = powerup_death_machine_icon
					end

					icon_tbl[#icon_tbl + 1] = {NZCustomPowerupsHUD["deathmachine"], v}
				end

				local powerupData = nzPowerUps:Get(k)
			end
		end

		-- Now that we know the powerups that are active for us, we can render them as centered on the bottom of the screen.
		local powerup_count = #icon_tbl
		local powerup_width_spacing = (powerup_count > 1 and powerup_width_spacing or 0)
		local total_width = (powerup_icon_width * powerup_count) + (powerup_width_spacing * (powerup_count ))
		local iterated = 0

		for k,v in pairs(icon_tbl) do
			local material = v[1]
			local time = v[2]
			local center = (ScrW() / 2)
			-- my brain fucking hurts
			local move_back_amount = (powerup_icon_width * k)

			if powerup_count > 1 and k != iterated  then
				move_back_amount = move_back_amount + ((powerup_width_spacing * k) / 1.5)
			end

			local pos = (center - move_back_amount) + (total_width / 2)

			surface.SetMaterial(material)
			surface.SetDrawColor(255,255,255)
			surface.DrawTexturedRect(pos, ScrH() - (powerup_icon_height + powerup_height_spacing), powerup_icon_width, powerup_icon_height)
			surface.SetFont(powerup_font)

			local text = tostring(math.Round(time - CurTime()))
			local text_width,_ = surface.GetTextSize(text)

			-- I am tired and can't figure out how to do dynamic text for any font
			-- with my limited time. If a developer wants to do this, have fun!

			-- Hint: the pos + 25 is hardcoded, fix it.
			draw.SimpleText(text, powerup_font, (pos + 25), (ScrH() - (powerup_icon_height)) - powerup_font_height_spacing, Color(255, 255, 255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			iterated = iterated + 1
		end
	end
end

local Laser = Material( "cable/redlaser" )
function nzDisplay.DrawLinks( ent, link )

	local tbl = {}
	-- Check for zombie spawns
	for k, v in pairs(ents.GetAll()) do
		if v:IsBuyableProp()  then
			if nzDoors.PropDoors[k] != nil then
				if v.link == link then
					table.insert(tbl, Entity(k))
				end
			end
		elseif v:IsDoor() then
			if nzDoors.MapDoors[v:doorIndex()] != nil then
				if nzDoors.MapDoors[v:doorIndex()].link == link then
					table.insert(tbl, v)
				end
			end
		elseif v:GetClass() == "nz_spawn_zombie_normal" then
			if v:GetLink() == link then
				table.insert(tbl, v)
			end
		end
	end


	--  Draw
	if tbl[1] != nil then
		for k,v in pairs(tbl) do
			render.SetMaterial( Laser )
			render.DrawBeam( ent:GetPos(), v:GetPos(), 20, 1, 1, Color( 255, 255, 255, 255 ) )
		end
	end
end

local PointsNotifications = {}
local function PointsNotification(ply, amount)
	if !IsValid(ply) then return end
	local data = {ply = ply, amount = amount, diry = math.random(-20, 20), time = CurTime()}
	table.insert(PointsNotifications, data)
	--PrintTable(data)
end

net.Receive("nz_points_notification", function()
	local amount = net.ReadInt(20)
	local ply = net.ReadEntity()

	PointsNotification(ply, amount)
end)


-- TODO: fix rare bug where point numbers stop rendering /Ethorbit
local function DrawPointsNotification()

	if GetConVar("nz_point_notification_clientside"):GetBool() then
		for k,v in pairs(player.GetAll()) do
			if v:GetPoints() >= 0 then
				if !v.LastPoints then v.LastPoints = 0 end
				if v:GetPoints() != v.LastPoints then
					PointsNotification(v, v:GetPoints() - v.LastPoints)
					v.LastPoints = v:GetPoints()
				end
			end
		end
	end

	local font = "nz.display.hud.points"

	for k,v in pairs(PointsNotifications) do
		local fade = math.Clamp((CurTime()-v.time), 0, 1)
		if !v.ply.PointsSpawnPosition then return end
		if v.amount >= 0 then
			draw.SimpleText(v.amount, font, v.ply.PointsSpawnPosition.x - 50*fade, v.ply.PointsSpawnPosition.y + v.diry*fade, Color(255,255,0,255-255*fade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(v.amount, font, v.ply.PointsSpawnPosition.x - 50*fade, v.ply.PointsSpawnPosition.y + v.diry*fade, Color(255,0,0,255-255*fade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
		if fade >= 1 then
			table.remove(PointsNotifications, k)
		end
	end
end

-- Now handled via perks individual icon table entries
--[[local perk_icons = {
	["jugg"] = Material("perk_icons/jugg.png", "smooth unlitgeneric"),
	["speed"] = Material("perk_icons/speed.png", "smooth unlitgeneric"),
	["dtap"] = Material("perk_icons/dtap.png", "smooth unlitgeneric"),
	["revive"] = Material("perk_icons/revive.png", "smooth unlitgeneric"),
	["dtap2"] = Material("perk_icons/dtap2.png", "smooth unlitgeneric"),
	["staminup"] = Material("perk_icons/staminup.png", "smooth unlitgeneric"),
	["phd"] = Material("perk_icons/phd.png", "smooth unlitgeneric"),
	["deadshot"] = Material("perk_icons/deadshot.png", "smooth unlitgeneric"),
	["mulekick"] = Material("perk_icons/mulekick.png", "smooth unlitgeneric"),
	["cherry"] = Material("perk_icons/cherry.png", "smooth unlitgeneric"),
	["tombstone"] = Material("perk_icons/tombstone.png", "smooth unlitgeneric"),
	["whoswho"] = Material("perk_icons/whoswho.png", "smooth unlitgeneric"),
	["vulture"] = Material("perk_icons/vulture.png", "smooth unlitgeneric"),

	-- Only used to see PaP through walls with Vulture Aid
	["pap"] = Material("vulture_icons/pap.png", "smooth unlitgeneric"),
}]]

local function PerksHud() -- Improved by Ethorbit
	local scale = (ScrW()/1920 + 1)/2
	local w = -20
	local size = 50
	local player = nzDisplay:GetPlayer()

	if (IsValid(player) and player.GetPerks) then
		for k,v in pairs(player:GetPerks()) do
			--surface.SetMaterial(nzPerks:Get(v).icon)
			if (istable(NZCustomPerksHUD) and NZCustomPerksHUD[v]) then
				surface.SetMaterial(NZCustomPerksHUD[v])
				surface.SetDrawColor(255,255,255)
				if (v == "tombstone") then
					surface.DrawTexturedRect(w + k*(size*scale + 10), ScrH() - 250, size*scale, size*scale)
				else
					surface.DrawTexturedRect(w + k*(size*scale + 10), ScrH() - 245, size*scale, size*scale)
				end
			else
				surface.SetMaterial(nzPerks:Get(v).icon)
				surface.SetDrawColor(255,255,255)
				surface.DrawTexturedRect(w + k*(size*scale + 10), ScrH() - 245, size*scale, size*scale)
			end
		end
	end
end

local vulture_textures = {
	["wall_buys"] = Material("vulture_icons/wall_buys.png", "smooth unlitgeneric"),
	["random_box"] = Material("vulture_icons/random_box.png", "smooth unlitgeneric"),
	["wunderfizz_machine"] = Material("vulture_icons/wunderfizz.png", "smooth unlitgeneric"),
}

local function VultureVision()
	if !LocalPlayer():HasPerk("vulture") then return end
	local scale = (ScrW()/1920 + 1)/2

	for k,v in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 700)) do
		local target = v:GetClass()
		if vulture_textures[target] then
			local data = v:WorldSpaceCenter():ToScreen()
			if data.visible then
				surface.SetMaterial(vulture_textures[target])
				surface.SetDrawColor(255,255,255,150)
				surface.DrawTexturedRect(data.x - 15*scale, data.y - 15*scale, 30*scale, 30*scale)
			end
		elseif target == "perk_machine" then
			local data = v:WorldSpaceCenter():ToScreen()
			if data.visible then
				if (istable(NZCustomPerksHUD) and NZCustomPerksHUD[v:GetPerkID()]) then
					local icon = NZCustomPerksHUD[v:GetPerkID()]
					if icon then
						surface.SetMaterial(icon)
						surface.SetDrawColor(255,255,255,150)
						surface.DrawTexturedRect(data.x - 15*scale, data.y - 15*scale, 30*scale, 30*scale)
					end
				end
			end
		end
	end
end

local round_white = 0
local round_alpha = 255
local round_num = 0
local infmat = Material("materials/round_-1.png", "smooth")
local function RoundHud() -- Improved by Ethorbit, round 6 bug fixed by NapalmBurner
	if (round_num == 0 and LocalPlayer():IsSpectating() and #player.GetAllPlaying() > 0) then
		round_num = nzRound:GetNumber()
	end

	local small_screen = nzDisplay.IsSmallScreen()
    local text = ""
    local font = !small_screen and "nz.display.hud.rounds" or "nz.display.hud.rounds.small"
	local w = 35

	local h

	local player = nzDisplay:GetPlayer()
	if !player:IsPlayer() then return end

	if (hpHudEnabled) then
		if (!IsValid(player)) then
			h = ScrH() - 35
		else
			local hudInt = hpHudEnabled:GetInt()
			if ((hudInt != 4 and hudInt != 2) or (hudInt == 2 and player:Armor() > 0)) then
				h = ScrH() - 65
			else
				h = ScrH() - 35
			end

			if (!player:GetNotDowned() or !player:Alive()) then
				h = ScrH() - 35
			end
		end
	end

    local round = round_num
    local col = Color(100 + round_white*55, round_white, round_white,round_alpha)
    if round == -1 then
        --text = "∞"
        surface.SetMaterial(infmat)
        surface.SetDrawColor(col.r,round_white,round_white,round_alpha)
        surface.DrawTexturedRect(w - 25, h - 100, 200, 100)
        return
    elseif round < 6 then
        for i = 1, round do
            if i == 5 or i == 6 then
                text = text.." "
            else
                text = text.."i"
            end
        end
		if round >= 5 then
			if !small_screen then
				if (hudInt and hudInt == 4) then
					draw.TextRotatedScaled( "i", w + 122, h - 190, col, font, 60, 1, 1.45 )
				else
					draw.TextRotatedScaled( "i", w + 100, h - 160, col, font, 60, 1, 1.45 )
				end
			else
				if (hudInt and hudInt == 4) then
					draw.TextRotatedScaled( "i", w + 82, h - 120, col, font, 60, 1, 1.35 )
				else
					draw.TextRotatedScaled( "i", w + 60, h - 90, col, font, 60, 1, 1.35 )
				end
			end
        end
        --if round >= 10 then
        --    draw.TextRotatedScaled( "i", w + 220, h - 150, col, font, 60, 1, 1.45 )
        --end
    else
        text = round
    end
    draw.SimpleText(text, font, w, h + 20, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

end

local roundchangeending = false
local prevroundspecial = false
local function StartChangeRound()

	print(nzRound:GetNumber(), nzRound:IsSpecial())

	local lastround = nzRound:GetNumber()

	if lastround >= 1 then
		if prevroundspecial then
			--surface.PlaySound("nz/round/special_round_end.wav")
			nzSounds:Play("SpecialRoundEnd")
		else
			--surface.PlaySound("nz/round/round_end.mp3")
			nzSounds:Play("RoundEnd")
		end
	elseif lastround == -2 then
		surface.PlaySound("nz/round/round_-1_prepare.mp3")
	else
		round_num = 0
	end

	roundchangeending = false
	round_white = 0
	local round_charger = 0.25
	local alphafading = false
	local haschanged = false
	hook.Add("HUDPaint", "nz_roundnumWhiteFade", function()
		if !alphafading then
			round_white = math.Approach(round_white, round_charger > 0 and 255 or 0, round_charger*350*FrameTime())
			if round_white >= 255 and !roundchangeending then
				alphafading = true
				round_charger = -1
			elseif round_white <= 0 and roundchangeending then
				hook.Remove("HUDPaint", "nz_roundnumWhiteFade")
			end
		else
			round_alpha = math.Approach(round_alpha, round_charger > 0 and 255 or 0, round_charger*350*FrameTime())
			if round_alpha >= 255 then
				if haschanged then
					round_charger = -0.25
					alphafading = false
				else
					round_charger = -1
				end
			elseif round_alpha <= 0 then
				if roundchangeending then
					round_num = nzRound:GetNumber()
					round_charger = 0.5
					if round_num == -1 then
						--surface.PlaySound("nz/easteregg/motd_round-03.wav")
					elseif nzRound:IsSpecial() then
						--surface.PlaySound("nz/round/special_round_start.wav")
						nzSounds:Play("SpecialRoundStart")
						prevroundspecial = true
					else
						--surface.PlaySound("nz/round/round_start.mp3")
						nzSounds:Play("RoundStart")
						prevroundspecial = false
					end
					haschanged = true
				else
					round_charger = 1
				end
			end
		end
	end)

end

local function EndChangeRound()
	roundchangeending = true
end

local grenade_icon = Material("grenade-256.png", "unlitgeneric smooth")
local function DrawGrenadeHud()
	local player = nzDisplay:GetPlayer()
	if (IsValid(player)) then
		local num = player:GetAmmoCount(GetNZAmmoID("grenade") or -1)
		local numspecial = player:GetAmmoCount(GetNZAmmoID("specialgrenade") or -1)
		if (player != LocalPlayer()) then
			num = player:GetNWInt("Spec_Nades")
			numspecial = player:GetNWInt("Spec_NadesSpecial")
		end

		local scale = (ScrW()/1920 + 1)/2

		--print(num)
		if num > 0 then
			surface.SetMaterial(grenade_icon)
			surface.SetDrawColor(255,255,255)
			for i = num, 1, -1 do
				--print(i)
				surface.DrawTexturedRect(ScrW() - 250*scale - i*10*scale, ScrH() - 90*scale, 30*scale, 30*scale)
			end
		end
		if numspecial > 0 then
			surface.SetMaterial(grenade_icon)
			surface.SetDrawColor(255,100,100)
			for i = numspecial, 1, -1 do
				--print(i)
				surface.DrawTexturedRect(ScrW() - 300*scale - i*10*scale, ScrH() - 90*scale, 30*scale, 30*scale)
			end
		end
		--surface.DrawTexturedRect(ScrW()/2, ScrH()/2, 100, 100)
	end
end

-- Hooks
hook.Add("HUDPaint", "HPArmorHUD", HealthHud)
hook.Add("HUDPaint", "pointsNotifcationHUD", DrawPointsNotification )
hook.Add("HUDPaint", "roundHUD", StatesHud )
hook.Add("HUDPaint", "scoreHUD", ScoreHud )
hook.Add("HUDPaint", "gunHUD", GunHud )
hook.Add("HUDPaint", "powerupHUD", PowerUpsHud )
hook.Add("HUDPaint", "perksHUD", PerksHud )
hook.Add("HUDPaint", "vultureVision", VultureVision )
hook.Add("HUDPaint", "roundnumHUD", RoundHud )
hook.Add("HUDPaint", "grenadeHUD", DrawGrenadeHud )

hook.Add("OnRoundPreparation", "BeginRoundHUDChange", StartChangeRound)
hook.Add("OnRoundStart", "EndRoundHUDChange", EndChangeRound)

local blockedweps = {
	["nz_revive_morphine"] = true,
	["nz_packapunch_arms"] = true,
	["nz_perk_bottle"] = true,
}

function GM:HUDWeaponPickedUp( wep )

	if ( !IsValid( LocalPlayer() ) || !LocalPlayer():Alive() ) then return end
	if ( !IsValid( wep ) ) then return end
	if ( !isfunction( wep.GetPrintName ) ) then return end
	if blockedweps[wep:GetClass()] then return end

	local pickup = {}
	pickup.time			= CurTime()
	pickup.name			= wep:GetPrintName()
	pickup.holdtime		= 5
	pickup.font			= "DermaDefaultBold"
	pickup.fadein		= 0.04
	pickup.fadeout		= 0.3
	pickup.color		= Color( 255, 200, 50, 255 )

	surface.SetFont( pickup.font )
	local w, h = surface.GetTextSize( pickup.name )
	pickup.height		= h
	pickup.width		= w

	if ( self.PickupHistoryLast >= pickup.time ) then
		pickup.time = self.PickupHistoryLast + 0.05
	end

	table.insert( self.PickupHistory, pickup )
	self.PickupHistoryLast = pickup.time

	if wep.NearWallEnabled then wep.NearWallEnabled = false end
	if wep:IsFAS2() then wep.NoNearWall = true end

end

local function ParseAmmoName(str)
	local pattern = "nz_weapon_ammo_(%d)"
	local slot = tonumber(string.match(str, pattern))
	if slot then
		for k,v in pairs(LocalPlayer():GetWeapons()) do
			if v:GetNWInt("SwitchSlot", -1) == slot then
				if v.Primary and v.Primary.OldAmmo then
					return "#"..v.Primary.OldAmmo.."_ammo"
				end
				local wep = weapons.Get(v:GetClass())
				if wep and wep.Primary and wep.Primary.Ammo then
					return "#"..wep.Primary.Ammo.."_ammo"
				end
				return v:GetPrintName() .. " Ammo"
			end
		end
	end
	return str
end

function GM:HUDAmmoPickedUp( itemname, amount )
	if ( !IsValid( LocalPlayer() ) || !LocalPlayer():Alive() ) then return end

	itemname = ParseAmmoName(itemname)

	-- Try to tack it onto an exisiting ammo pickup
	if ( self.PickupHistory ) then
		for k, v in pairs( self.PickupHistory ) do
			if ( v.name == itemname ) then
				v.amount = tostring( tonumber( v.amount ) + amount )
				v.time = CurTime() - v.fadein
				return
			end
		end
	end

	local pickup = {}
	pickup.time			= CurTime()
	pickup.name			= itemname
	pickup.holdtime		= 5
	pickup.font			= "DermaDefaultBold"
	pickup.fadein		= 0.04
	pickup.fadeout		= 0.3
	pickup.color		= Color( 180, 200, 255, 255 )
	pickup.amount		= tostring( amount )

	surface.SetFont( pickup.font )
	local w, h = surface.GetTextSize( pickup.name )
	pickup.height	= h
	pickup.width	= w

	local w, h = surface.GetTextSize( pickup.amount )
	pickup.xwidth	= w
	pickup.width	= pickup.width + w + 16

	if ( self.PickupHistoryLast >= pickup.time ) then
		pickup.time = self.PickupHistoryLast + 0.05
	end

	table.insert( self.PickupHistory, pickup )
	self.PickupHistoryLast = pickup.time
end
