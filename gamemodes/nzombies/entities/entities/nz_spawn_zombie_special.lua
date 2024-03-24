AddCSLuaFile( )

ENT.Base = "nz_spawner_base" 
ENT.PrintName = "Special"

ENT.NZOnlyVisibleInCreative = true

-- Let's add the base classes to other spawners that we want the special spawner to use as well:
local DogBaseClass = baseclass.Get("nz_spawn_zombie_dog")
--local BossBaseClass = baseclass.Get("nz_spawn_zombie_boss")
-------------------------------------------------------------------------------------------

function ENT:OnInitialize()
	self:SetColor(Color(255, 0, 0)) -- Default zombie ent is green and we have the same model, let's make ourselves distinguishable
	
	if SERVER then
		Spawner:UpdateHooks(self)
	end
end

function ENT:GetSpawnerData() -- A list of the enemies this spawns, and the chances for us to spawn them
	return {["nz_zombie_special_dog"] = {chance = 100}}
end

function ENT:OnReset()
	DogBaseClass.OnReset(self)
end

function ENT:AddMaxZombies()
	--local original_count = nzRound:GetZombiesMax()
	DogBaseClass.AddMaxZombies(self)
end

function ENT:DoSpawnChance()
	DogBaseClass.DoSpawnChance(self)
end

function ENT:SetNextSpecialRound()
	DogBaseClass.SetNextSpecialRound(self)

	if (!nzRound:GetNextSpecialRound()) then
		nzRound:SetNextSpecialRound(0) -- Guess we just don't have a special round.
	end
end

function ENT:OnRoundPreparation(round_num)
	DogBaseClass.OnRoundPreparation(self, round_num)
end

function ENT:OnRoundStart(round_num) -- Begin spawning on special round
	DogBaseClass.OnRoundStart(self, round_num)
end

function ENT:SpawnedEntity(zombie) -- We spawned something
	if (zombie:GetClass() == "nz_zombie_special_dog") then
		DogBaseClass.SpawnedEntity(self, zombie)
	end
end

function ENT:OnZombieSpawned(zombie, spawner, is_respawn)
	if (zombie:GetClass() == "nz_zombie_walker") then
		self:DoSpawnChance()
	end
end

function ENT:GetDelay()
	return DogBaseClass.GetDelay(self) -- We'll just use the dog's spawn delay since that's most likely what will spawn
end