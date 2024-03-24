-- Main Tables (Refactored by Ethorbit to make this a hell of a lot less redundant)
nzConfig = nzConfig or AddNZModule("Config")
nzConfig.Vars = nzConfig.Vars or {}

nzConfig.GetVar = function(name)
	return nzConfig.Vars[name]
end

nzConfig.DefineVar = function(var, val, flags, desc, min, max)
	if not ConVarExists(var) then
		local convar = CreateConVar(var, val, flags, desc, min, max)
		nzConfig.Vars[var] = convar

		hook.Run("NZ.VarInitialized", var, convar)

		cvars.AddChangeCallback(var, function(name, oldVal, newVal)
 			hook.Run("NZ.VarChanged", name, oldVal, newVal)
		end)
	end
end

nzConfig.DefineClientVar = function(...) -- Params ^^
	if CLIENT then
		nzConfig.DefineVar(...)
	end
end

nzConfig.DefineServerVar = function(...) -- Params   ^^
	if SERVER then
		nzConfig.DefineVar(...)
	end
end

-- Defaults
nzConfig.DefineVar("nz_randombox_whitelist", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
nzConfig.DefineVar("nz_downtime", 45, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_nav_grouptargeting", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
--define_convar("nz_round_special_interval", 6, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_round_prep_time", 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_randombox_maplist", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_round_dropins_allow", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_barricade_classic", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_max_player_health", 300, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_max_player_armor", 150, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_points", 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_points_cap_start", 50, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_points_cap_per_round", 50, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_points_cap_max", 500, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_zombie_amount_base", 6, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_zombie_amount_scale", 0.35, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_zombie_health_base", 150, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_zombie_health_scale", 1.1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
--nzConfig.DefineVar("nz_difficulty_max_zombies_alive", 35, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_max_zombies", 3, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_barricade_planks_max", 6, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_powerup_chance", 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
--nzConfig.DefineVar("nz_difficulty_powerup_max_per_round", 4, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_powerup_required_round_points_base", 2000, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_powerup_required_round_points_scale", 1.14, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_difficulty_perks_max", 4, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_point_notification_clientside", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED})
nzConfig.DefineVar("nz_zombie_lagcompensated", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
nzConfig.DefineVar("nz_spawnpoint_update_rate", 4, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})

nzConfig.DefineVar("nz_maxragdolls", 10, {FCVAR_ARCHIVE}, "Max amount of ragdolls allowed to exist at any time.", 0, 8000)
nzConfig.DefineVar("nz_ragdollremovetime", 1, {FCVAR_ARCHIVE}, "How many seconds it takes to fade and remove ragdolls that are over the maxragdoll limit.", 0, 30)

nzConfig.DefineVar("nz_log_sql_queries", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Logs all successful nZombies SQL queries. You can use this to see what's saving/loading from the database.")

local mapvoteFlags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}
nzConfig.DefineVar("nz_mapvote_item_limit", 30, mapvoteFlags, "Max amount of items that can show in the Map Vote")
nzConfig.DefineVar("nz_mapvote_time_limit", 30, mapvoteFlags, "The time everyone has to choose a map")
nzConfig.DefineVar("nz_mapvote_config_time_limit", 20, mapvoteFlags, "The time everyone has to choose a config for a map")
nzConfig.DefineVar("nz_mapvote_unlock_round", 12, mapvoteFlags, "The MapVote unlocks after this round, dying after it will automatically initiate it.")
nzConfig.DefineVar("nz_mapvote_allow_current_map", 1, mapvoteFlags, "Allow the current map to be voted for.")
nzConfig.DefineVar("nz_mapvote_auto_change_no_players", 0, mapvoteFlags, "Auto changes to a random map after a duration when nobody is on.")
nzConfig.DefineVar("nz_mapvote_auto_change_no_players_minutes", 1800, mapvoteFlags, "Consecutive minutes of nobody online before auto changing")

nzConfig.DefineClientVar("nz_custom_fov_enabled", 0, {FCVAR_ARCHIVE}, "Enables/Disables customizable nZombies FOV")
nzConfig.DefineClientVar("nz_custom_fov", 75, {FCVAR_ARCHIVE}, "Set a custom FOV (Only works if nz_custom_fov_enabled is on)")
nzConfig.DefineClientVar("nz_draw_distance", -1, {FCVAR_USERINFO, FCVAR_ARCHIVE}, "Sets the max distance the world can render.")
nzConfig.DefineClientVar("nz_weapon_auto_reload", 1, {FCVAR_USERINFO, FCVAR_ARCHIVE}, "Auto reloads your weapon after firing the last shot")
nzConfig.DefineClientVar("nz_round_sounds", 1, {FCVAR_ARCHIVE}, "Whether or not to play round changing sounds.")
nzConfig.DefineClientVar("nz_gameover_music", 1, {FCVAR_ARCHIVE}, "Whether or not to play gameover music.")
nzConfig.DefineClientVar("nz_zombie_eyes", 1, {FCVAR_ARCHIVE}, "Enable/Disable the rendering of zombie eyes")
nzConfig.DefineClientVar("nz_holiday_events", 1, {FCVAR_ARCHIVE}, "Toggle nZombies holiday cosmetic events (Mostly affects zombie appearance)")
nzConfig.DefineClientVar("nz_allow_copyright_audio", 0, {FCVAR_ARCHIVE}, "Toggles copyrighted audio. There is no guarantee there will be zero copyrighted audio, this simply overrides audio we have identified as copyrighted.")

local xpFlags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}
local commentSuffix = " (Only works if XP-Tools is installed on the server)"
nzConfig.DefineVar("nz_xp_from_zombies_allowed", 1, xpFlags, "Can players gain XP from killing non-boss zombies?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_reviving_allowed", 1, xpFlags, "Can players gain XP from reviving?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_doors_allowed", 1, xpFlags, "Can players gain XP from purchasing doors? Amount scales depending on the price of the door." .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_barriers_allowed", 1, xpFlags, "Can players gain XP from repairing barriers?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_powerups_allowed", 1, xpFlags, "Can players gain XP from picking up powerups?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_box_allowed", 1, xpFlags, "Can players gain XP from purchasing the Mystery Box?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_boss_allowed", 1, xpFlags, "Can players gain XP from defeating bosses?" .. commentSuffix)
nzConfig.DefineVar("nz_xp_from_map_records_allowed", 1, xpFlags, "Can players gain XP from beating map records?" .. commentSuffix)

nzConfig.DefineVar("nz_xp_amount_from_zombies", 12, xpFlags, "XP received per non-boss zombie." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_reviving", 90, xpFlags, "XP received per revive." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_barriers", 10, xpFlags, "XP received per board repaired." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_powerups", 20, xpFlags, "XP received per powerup grabbed." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_box", 14, xpFlags, "XP received from purchasing Mystery Box." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_boss", 120, xpFlags, "XP received from defeating a boss." .. commentSuffix)
nzConfig.DefineVar("nz_xp_amount_from_map_records", 180, xpFlags, "XP received from beating a map's record." .. commentSuffix)

nzConfig.DefineClientVar("nz_xp_hudtype", 1, {FCVAR_ARCHIVE}, "1 for bottom, 2 for distracting top" .. commentSuffix)
nzConfig.DefineClientVar("nz_xp_visuals", 1, {FCVAR_ARCHIVE}, "Enable/Disable the XP-Tools visuals" .. commentSuffix)
nzConfig.DefineClientVar("nz_xp_bar_shrink_amount", 0.0, {FCVAR_ARCHIVE}, "Changes the horizontal scale of the XP bar, but only if the nz_xp_hudtype is on 1 or less." .. commentSuffix)
--nzConfig.DefineClientVar("nz_levelup_sound", )
--nzConfig.DefineVar(CLIENT and "nz_client_ragdolltime" or "nz_server_ragdolltime", 30, {FCVAR_ARCHIVE}, CLIENT and "How long clientside Zombie ragdolls will stay in the map." or "How long serverside Zombie ragdolls will stay in the map.")
--nzConfig.DefineVar("nz_rtv_time", 45, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})
--nzConfig.DefineVar("nz_rtv_enabled", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE})

-- Zombie table - Moved to shared area for client collision prediction (barricades)


-- We should keep zombie-specific parameters in zombie-specific files
-- Grouping everything into a single separate file is stupid and messy.
-- /Ethorbit
nzConfig.ValidEnemies = nzConfig.ValidEnemies or {}
nzConfig.AddValidEnemy = function(class, val)
    nzConfig.ValidEnemies[class] = val
end

-- Random Box

nzConfig.WeaponBlackList = {}
function nzConfig.AddWeaponToBlacklist( class, remove )
	nzConfig.WeaponBlackList[class] = remove and nil or true
end

nzConfig.AddWeaponToBlacklist( "weapon_base" )
nzConfig.AddWeaponToBlacklist( "weapon_fists" )
nzConfig.AddWeaponToBlacklist( "weapon_flechettegun" )
nzConfig.AddWeaponToBlacklist( "weapon_medkit" )
nzConfig.AddWeaponToBlacklist( "weapon_dod_sim_base" )
nzConfig.AddWeaponToBlacklist( "weapon_dod_sim_base_shot" )
nzConfig.AddWeaponToBlacklist( "weapon_dod_sim_base_snip" )
nzConfig.AddWeaponToBlacklist( "weapon_sim_admin" )
nzConfig.AddWeaponToBlacklist( "weapon_sim_spade" )
nzConfig.AddWeaponToBlacklist( "fas2_base" )
nzConfig.AddWeaponToBlacklist( "fas2_ammobox" )
nzConfig.AddWeaponToBlacklist( "fas2_ifak" )
nzConfig.AddWeaponToBlacklist( "nz_multi_tool" )
nzConfig.AddWeaponToBlacklist( "nz_grenade" )
nzConfig.AddWeaponToBlacklist( "nz_perk_bottle" )
nzConfig.AddWeaponToBlacklist( "nz_quickknife_crowbar" )
nzConfig.AddWeaponToBlacklist( "nz_tool_base" )
nzConfig.AddWeaponToBlacklist( "nz_one_inch_punch" ) -- Nope! You gotta give this with special map scripts

nzConfig.AddWeaponToBlacklist( "cw_base" )

nzConfig.WeaponWhiteList = {
	"fas2_", "m9k_", "cw_",
}

if SERVER then

	nzConfig.RoundData = {} -- We don't actually use this anymore since 2021, the spawners have code in themselves for what enemies to spawn and when as well as other logic
	--nzConfig.RoundData[1] = {["nz_zombie_walker"] = 100}

	--[[
	-- EXAMPLE of a round zombie config:
	nzConfig.RoundData[ROUNDNUMBER] = {
		-- define normal zombies and theri spawn chances
		normalTypes = {
			["nz_zombie_walker"] = {
				chance = 100,
			},
		},
		-- (optional) how many normal zombies will spawn this wil overwrite the default curves
		normalCount = 50,

		-- (optional) modify teh count witha  function ratehr than a fixed amount
		-- if both normalCount and normalCountMod are set the gamemode will ignore normalCount
		normalCountMod = function(original) return orignal / 2 end,

		-- (optional) spawn delay
		-- this will spawn the zombies in a 3 second intervall
		normalDelay = 3,

		-- special zombies (different spawnpoint usually in front of barricades)
		-- this will spawn 10 hellhounds in additon to the normal zombies
		specialTypes = {
			["nz_zombie_special_dog"] = {
				chance = 100,
			},

		},
		-- (optional) not required but recommended if this is not set teh zombie amount will be doubled
		specialCount = 10
		-- (optional) flag this round as special (this will trigger fog etc.)
		special = true
	}
	]]--

	-- nzConfig.RoundData[1] = {
	-- 	normalTypes = {
	-- 		["nz_zombie_walker"] = {
	-- 			chance = 100,
	-- 		},
	-- 	},
	-- }
	-- nzConfig.RoundData[2] = {
	-- 	normalTypes = {
	-- 		["nz_zombie_walker"] = {
	-- 			chance = 100,
	-- 		},
	-- 	},
	-- }
	-- nzConfig.RoundData[13] = {
	-- 	normalTypes = {
	-- 		["nz_zombie_walker"] = {
	-- 			chance = 75,
	-- 		},
	-- 		["nz_zombie_special_burning"] = {
	-- 			chance = 25,
	-- 		},
	-- 	},
	-- }
	-- nzConfig.RoundData[14] = {
	-- 	normalTypes = {
	-- 		["nz_zombie_walker"] = {
	-- 			chance = 100,
	-- 		},
	-- 	},
	-- }
	-- nzConfig.RoundData[23] = {
	-- 	normalTypes = {
	-- 		["nz_zombie_walker"] = {
	-- 			chance = 90,
	-- 		},
	-- 		["nz_zombie_special_burning"] = {
	-- 			chance = 10,
	-- 		},
	-- 	},
	-- }

	-- Player Class
	nzConfig.BaseStartingWeapons = {"fas2_glock20"} -- "fas2_p226", "fas2_ots33", "fas2_glock20" "weapon_pistol"
	-- nzConfig.CustomConfigStartingWeps = true -- If this is set to false, the gamemode will avoid using custom weapons in configs

end
