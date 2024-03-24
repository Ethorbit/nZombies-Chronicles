DEFINE_BASECLASS( "player_default" )

local PLAYER = {}

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--
PLAYER.WalkSpeed 			= 210
PLAYER.RunSpeed				= 315
PLAYER.CanUseFlashlight     = true

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Bool", 0, "UsingSpecialWeapon")
	self.Player:NetworkVar("Entity", 0, "TeleporterEntity")
	self.Player:NetworkVar("Float", 1, "LastNovaGasTouch")

	self.Player:NetworkVar("Vector", 0, "LastDownedPosition")
	self.Player:NetworkVar("Vector", 1, "LastRevivedPosition")
	self.Player:NetworkVar("Vector", 2, "LastDeathPosition")
end

function PLAYER:Init()
	-- Don't forget Colours
	-- This runs when the player is first brought into the game
	-- print("create")
	self.Player:AddDefaultSpeeds()
end

function PLAYER:Loadout()
	-- Creation Tools
	self.Player:Give( "weapon_physgun" )
	self.Player:Give( "nz_multi_tool" )

	timer.Simple(0.1, function()
		if IsValid(self.Player) then
			if !self.Player:HasWeapon( "weapon_physgun" ) then
				self.Player:Give( "weapon_physgun" )
			end
			if !self.Player:HasWeapon( "nz_multi_tool" ) then
				self.Player:Give( "nz_multi_tool" )
			end
		end
	end)

end

function PLAYER:Spawn()
	self.Player:SetNextAllowedSprint(0) -- Sprinting system is actually disabled in Creative, but this feels right..
    self.Player:SetCustomCollisionCheck(false) -- lag fix /Ethorbit
	
    -- if we are in create or debuging make zombies target us
	if nzRound:InState(ROUND_CREATE) or GetConVar( "nz_zombie_debug" ):GetBool() then --TODO this is bullshit?
		self.Player:SetTargetPriority(TARGET_PRIORITY_PLAYER)
	end
	self.Player:SetUsingSpecialWeapon(false)
    self.Player:MoveToSpawn()
    -- Deprecated by above
    --local spawns = ents.FindByClass("player_spawns")
	--if #spawns > 0 then -- TP to player_spawns if it exists, otherwise do the normal spawning
	--	-- Just a copy paste of what sh_player_ingame does (for spawning out of Creative Mode)
	--	for k,v in pairs(player.GetAll()) do
	--		if v == self.Player then
	--			if IsValid(spawns[k]) then
	--				v:SetPos(spawns[k]:GetPos())
	--			else
	--				print("No spawn set for player: " .. v:Nick())
	--			end
	--		end
	--	end
	--end
end

player_manager.RegisterClass( "player_create", PLAYER, "player_default" )
