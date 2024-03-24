AddCSLuaFile( )

ENT.Base = "nz_spawner_base"
ENT.PrintName = "Nova Crawler"

nzRound:AddSpecialRoundType("Nova Crawlers")

ENT.NZOnlyVisibleInCreative = true

function ENT:OnReset()
	self.zombieskilled = 0
end

function ENT:GetSpawnerData() -- A list of the enemies this spawns, and the chances for us to spawn them
	return {["nz_zombie_special_nova"] = {chance = 100}}
end

function ENT:OnInitialize()
	self:SetModel("models/roach/bo1_overhaul/quadcrawler.mdl")

	self:SetSequence(self:LookupSequence("idle"))
	self:PhysicsInitBox(self:GetModelBounds())
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	self:SetColor(Color(255, 0, 0))
end

function ENT:SpawnBatch()
	if self != self.Updater then return end

	if self:CanActivate() then
		local amount = nzMapping.Settings.novacrawlerbatch --+ (#player.GetAllPlayingAndAlive() - 1)
		nzRound:SetZombiesMax(nzRound:GetZombiesMax() + amount)
		self:SetSpawnerAmount(self:GetSpawnerAmount() + amount)
		self:SetActive(true)
	end
end

function ENT:OnZombieKilled(zombie) -- Spawn a batch of crawlers for every 24 zombies killed
	if !nzMapping.Settings.enablenovacrawlers then return end
	if (nzElec:IsOn() and !nzRound:IsSpecial() and nzRound:GetState() != ROUND_CREATE) then
		self.zombieskilled = self.zombieskilled + 1

		if IsValid(zombie) and zombie.GetSpawner and zombie:GetSpawner() == self then
			-- Check if there's any zombies other than us.
			-- If not, kill the rest and end the round.
			local other_zombies = false

			for _,v in pairs(Spawner:GetAll()) do
				if v:GetClass() != self:GetClass() and #v:GetZombies() > 0 then
					other_zombies = true
					break
				end
			end

			if !other_zombies then
				-- Kill the rest to end the round!
				for _,crawler in pairs(self:GetZombies()) do
					local dmg = DamageInfo()
					dmg:SetDamage(crawler:Health() * 2)
					dmg:SetAttacker(Entity(0))
					crawler:TakeDamageInfo(dmg)
				end
			end
		end

		if (self.zombieskilled >= 24) then
			self.zombieskilled = 0
			self:SpawnBatch()
		end
	end
end

function ENT:OnRoundStart(round_num)
	if !nzMapping.Settings.enablenovacrawlers then return end
	if self != self.Updater then return end

	timer.Simple(5, function()
		if !IsValid(self) then return end

		if (nzElec:IsOn()) then -- Nova Crawlers only start coming after the Power is activated
			if (nzRound:IsSpecial()) then return end -- Avoid Dog Rounds

			self:SpawnBatch()
		end
	end)
end

function ENT:GetDelay()
	local delay = hook.Run("NovaCrawlerSpawnDelay", self)
	if delay then return delay end

	if nzEnemies:TotalAlive() == 0 then return 0.8 end
	return math.random(3, 11)

	-- if nzRound:TimeElapsed() < 5 or nzEnemies:TotalAlive() == 0 then -- Make sure a few spawn in at the beginning
	-- 	return 0.2
	-- end

	-- -- From BO1's Source Code  -  (quads will start to slowly spawn and then gradually spawn faster)
	-- if (nzRound:TimeElapsed() < 15) then
	-- 	return math.random(30,45)
	-- elseif (nzRound:TimeElapsed() < 25) then
	-- 	return math.random(15,30)
	-- elseif (nzRound:TimeElapsed() < 35) then
	-- 	return math.random(10,15)
	-- else
	-- 	return math.random(5,10)
	-- end
end
