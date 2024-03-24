-- Spawner Base developed by Ethorbit, think of it like TFA Base but for the zombie spawners of nZombies!

-- ALL (Serverside) Gmod & Gamemode hooks can be used as functions for your spawner (Kinda like MapScripts)
-- Some examples of helpful hooks to use:

-- function ENT:OnRoundPreparation(round_num)
-- end

-- function ENT:ElectricityOn()
-- end

-- How to use the spawner API? Simple.
-- When you want to start spawning do:
-- self:SetSpawnerAmount(number of spawns you want)

-- if self:CanActivate() then
--      self:SetActive(true)
-- end

-- And now your spawner will keep spawning the enemies until that amount has been reached.
-- Make sure to make use of the stuff below!
----------------------------------------------------------------------------------------------------------
AddCSLuaFile()

ENT.Base = "nz_spawn_zombie" -- Don't put this in your spawner, put ENT.Base = "nz_spawner_base" instead
ENT.PrintName = "My Spawner" -- Unique name to identify this spawner, used in stuff like the Creative Mode menu's Zombie Spawner tool
ENT.SpecialPrintName = nil -- Set this if your spawner is to be used in Special Rounds, it's what the nzRound:GetSpecialRoundType() is set to and what shows in the Map Settings for Special Round

function ENT:GetSpawnerData() -- A list of the enemies this spawns, and the chances for us to spawn them
	return {["nz_zombie_walker"] = {chance = 100}}
end

function ENT:GetDelay() -- The millisecond delay before can spawn again, anything over 5 seconds is complete overkill and will stall rounds as players wait
    return 1.25
end

----------------------------------------------------------------------------------
--  Add custom user/config settings for this spawner here:
-- (ALL spawners already have a submenu for editing flags and stuff, so don't add support for those)
-- Study https://wiki.facepunch.com/gmod/Editable_Entities to learn how you can add settings!

-- ENT.Editable = true

-- function ENT:OnSetupDataTables() -- Use this instead of SetupDataTables
-- 	--self:NetworkVar( "Bool", 1, "MyBoolean", {KeyName = "nz_spawn_dog_myboolean", Edit = {title = "My Boolean!", type = "Boolean", order = 1} } )
-- end

-- function ENT:SetCustomSettings(settings) -- These are what were saved from the config file, simply index the settings associated with this entity, and ALWAYS sanity check it
-- 	-- if (settings.MyBoolean != nil) then
-- 	-- 	self:SetMyBoolean(settings.MyBoolean)
-- 	-- end
-- end

-- function ENT:GetCustomSettings() -- Return what we want saved into configs, so that next time it's sent to us via SetCustomSettings()
-- 	-- return {
-- 	-- 	["MyBoolean"] = self:GetMyBoolean()
-- 	-- }
-- end
------------------------------------------------------------------------------------------------------

function ENT:SpawnedEntity(ent) -- We spawned something
end

function ENT:OnInitialize() -- Use this instead of ENT:Initialize()
end

function ENT:OnThink() -- Use this instead of ENT:Think()
end

function ENT:OnReset() -- When all NZ spawners need to go back to their default states
end

--------------------------------------------------------------------------------
-- Still not sure? Please take a look at how existing spawners were coded
-- located in the entities/ folder, prefixed with nz_zombie_spawn
-- You can also set ENT.Base to one of those classes if you're making
-- something that shares many traits with an existing spawner.
--------------------------------------------------------------------------------
