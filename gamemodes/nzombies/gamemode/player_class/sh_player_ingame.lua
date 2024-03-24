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
	self.Player:NetworkVar("Bool", 1, "Sprinting")
	self.Player:NetworkVar("Int", 0, "RoundBarricadePoints")

	-- Ammunition is not actually networked by the game from server-client
	-- Store these so that they can (For example) be accessed by Spectators
	self.Player:NetworkVar("Int", 1, "Spec_PrimaryAmmo")
	self.Player:NetworkVar("Int", 2, "Spec_SecondaryAmmo")
	self.Player:NetworkVar("Int", 3, "Spec_Clip1")
	self.Player:NetworkVar("Int", 4, "Spec_Clip2")
	self.Player:NetworkVar("Int", 5, "Spec_Nades")
	self.Player:NetworkVar("Int", 6, "Spec_NadesSpecial")

	self.Player:NetworkVar("Float", 1, "LastNovaGasTouch")
	self.Player:NetworkVar("Float", 2, "LastSpawned")

	self.Player:NetworkVar("Entity", 0, "WhosWhoEntity") -- Put this here so it is much faster to get their Who's Who clone, originally we'd loop through all the clones and compare their GetPerkOwner
	self.Player:NetworkVar("Entity", 1, "TeleporterEntity") -- So we can know what Teleporter is teleporting us

	self.Player:NetworkVar("Vector", 0, "LastDownedPosition")
	self.Player:NetworkVar("Vector", 1, "LastRevivedPosition")
	self.Player:NetworkVar("Vector", 2, "LastDeathPosition")
end

function PLAYER:Init()
	-- Don't forget Colours
	-- This runs when the player is first brought into the game and when they die during a round and are brought back
	self.Player:AddDefaultSpeeds()
	self.Player:SetRoundBarricadePoints(0)
end

if not ConVarExists("nz_failsafe_preventgrenades") then CreateConVar("nz_failsafe_preventgrenades", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}) end

function PLAYER:Loadout()
	--self:Give("tfa_down_weapon")

	-- Give ammo and guns
	if nzMapping.Settings.startwep and weapons.Get(nzMapping.Settings.startwep) then
		self.Player:Give( nzMapping.Settings.startwep )
	else
		self.Player:Give("nz_robotnik_bo1_1911")
		-- A setting does not exist, give default starting weapons
		-- for k,v in pairs(nzConfig.BaseStartingWeapons) do
		-- 	self.Player:Give( v )
		-- end
	end
	self.Player:GiveMaxAmmo()
--	self.Player:Give("tfa_fists")


	if !GetConVar("nz_papattachments"):GetBool() and FAS2_Attachments != nil then
		for k,v in pairs(FAS2_Attachments) do
			self.Player:FAS2_PickUpAttachment(v.key)
		end
	end

	--timer.Simple(2, function()
		if nzMapping.Settings.knifeclass and weapons.Get(nzMapping.Settings.knifeclass) then
			self.Player:Give(nzMapping.Settings.knifeclass)
		else
			self.Player:Give("nz_quickknife_crowbar")
		end

		-- We need this to disable the grenades for those that it causes problems with until they've been remade :(
		if !GetConVar("nz_failsafe_preventgrenades"):GetBool() then
			if nzMapping.Settings.nadeclass and weapons.Get(nzMapping.Settings.nadeclass) then
				self.Player:Give(nzMapping.Settings.nadeclass)
			else
				self.Player:Give("nz_grenade")
			end
		end
	--end)
end

function PLAYER:Spawn()
    self.Player:SetCustomCollisionCheck(false) -- lag fix /Ethorbit
    
    if (game.SinglePlayer()) then
		timer.Simple(1, function()
			if (IsValid(self.Player)) then
				self.Player:SetMaxHealth(100)
				self.Player:SetHealth(100)
				self.Player:SetArmor(0)
			end
		end)
	end

	self.Player:SetNextAllowedSprint(0)

	-- Ensure that their speeds don't come from Creative Mode
	self.Player:SetRunSpeed(self.Player:GetDefaultRunSpeed())
	self.Player:SetMaxRunSpeed(self.Player:GetDefaultRunSpeed())
	self.Player:SetWalkSpeed(self.Player:GetDefaultWalkSpeed())
	self.Player:InitStamina()
	--------------------------------------------------

	self.Player:SetRoundBarricadePoints(0)
	self.Player:SetLadderClimbSpeed(0)
	self.Player:SetMaxArmor(200) -- Hardcoded armor limit

	if nzMapping.Settings.startpoints then
		if !self.Player:CanAfford(nzMapping.Settings.startpoints) then
			self.Player:SetPoints(nzMapping.Settings.startpoints)
		end
	else
		if !self.Player:CanAfford(500) then -- Has less than 500 points
			-- Poor guy has no money, lets start him off
			self.Player:SetPoints(500)
		end
	end

	-- Reset their perks
	self.Player:RemovePerks()

	-- activate zombie targeting
	self.Player:SetTargetPriority(TARGET_PRIORITY_PLAYER)
    self.Player:MoveToSpawn()
    -- Deprecated by above
    --local spawns = ents.FindByClass("player_spawns")
	---- Get player number
	--for k,v in pairs(player.GetAll()) do
	--	if v == self.Player then
	--		if IsValid(spawns[k]) then
	--			v:SetPos(spawns[k]:GetPos())
	--		else
	--			print("No spawn set for player: " .. v:Nick())
	--		end
	--	end
	--end

	self.Player:SetUsingSpecialWeapon(false)
	self.Player:SetLastSpawned(CurTime())
end

player_manager.RegisterClass( "player_ingame", PLAYER, "player_default" )

-- Registers the down weapon based on config's starting weapon, this is what people are restricted to when they are down
