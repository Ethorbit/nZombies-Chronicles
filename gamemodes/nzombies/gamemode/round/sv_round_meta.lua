--pool network strings
-- util.AddNetworkString( ", nzRoundNumber" )
-- util.AddNetworkString( ", nzRoundState" )
-- util.AddNetworkString( ", nzRoundSpecial" )
-- util.AddNetworkString( "nzPlayerReadyState" )
-- util.AddNetworkString( "nzPlayerPlayingState" )
-- Commented by Ethorbit because these are already in the sh_sync

nzRound.Number = nzRound.Number or 0 -- Default for reloaded scenarios
nzRound.ZombiesKilled = nzRound.ZombiesKilled or {}
nzRound.PlayerSpawnsTbl = nzRound.PlayerSpawnsTbl or {}
nzRound.PlayerSpawns = nzRound.PlayerSpawns or {}
nzRound.PlayerSpawnsCount = nzRound.PlayerSpawnsCount or 0

function nzRound:ResetPlayerSpawns()
    nzRound.PlayerSpawnsTbl = ents.FindByClass("player_spawns")
    
    -- We'd better add this or else config creators won't be able to spawn on a map that has no config yet!
    if #nzRound.PlayerSpawnsTbl == 0 then
        nzRound.PlayerSpawnsTbl = ents.FindByClass("info_player_*")
    end
    
    for i = 1, #nzRound.PlayerSpawnsTbl do
        local rand = math.random(#nzRound.PlayerSpawnsTbl)
        self.PlayerSpawnsTbl[i], self.PlayerSpawnsTbl[rand] = self.PlayerSpawnsTbl[rand], self.PlayerSpawnsTbl[i]
    end

    self.PlayerSpawnsCount = 0
    self.PlayerSpawns = {}
    self:UpdatePlayerSpawns()
end

-- Ethorbit's spawn algorithm so NZ can stop fucking forcing config creators to create a specific number of player spawns...
function nzRound:UpdatePlayerSpawns()
    if #self.PlayerSpawnsTbl == 0 then
        self:ResetPlayerSpawns()
    return end

    for _,ply in pairs(player.GetAll()) do
        if !nzRound.PlayerSpawns[ply] then
            nzRound.PlayerSpawns[ply] = self.PlayerSpawnsTbl[(self.PlayerSpawnsCount % #self.PlayerSpawnsTbl) + 1]
            self.PlayerSpawnsCount = self.PlayerSpawnsCount + 1
        end
    end
end

function nzRound:GetPlayerSpawns()
    return nzRound.PlayerSpawns
end

function nzRound:GetPlayerSpawn(ply)
    return nzRound.PlayerSpawns[ply]
end

function nzRound:ClearZombiesKilled()
	self.ZombiesKilled = {}
end

function nzRound:GetZombiesKilled(spawner_class) -- Modified by Ethorbit for better flexibility
	if (spawner_class) then
		return self.ZombiesKilled[spawner_class] or 0
	else
		return self.ZombiesKilled["Round"] or 0
	end
end

function nzRound:SetZombiesKilled(num, spawner_class) -- Modified by Ethorbit for better flexibility
	if (spawner_class) then
		self.ZombiesKilled[spawner_class] = num
	else
		self.ZombiesKilled["Round"] = num
	end

	nzRound:SendZombiesKilled(num)
	hook.Run("NZ.UpdateZombiesKilled", num)
end

function nzRound:GetZombiesMax()
	return self.ZombiesMax or 0
end

function nzRound:SetZombiesMax( num )
	self.ZombiesMax = num
	self:SendZombiesMax(num) -- Added by Ethorbit for better clientside support
	hook.Run("NZ.UpdateZombiesMax", num)

	-- net.Start("update_prog_bar_max")
	-- net.WriteUInt(nzRound:GetZombiesMax(), 32)
	-- net.Broadcast()
	--
	-- net.Start("update_prog_bar_killed")
	-- net.WriteUInt(nzRound:GetZombiesKilled(), 32)
	-- net.Broadcast()
end

-- Powerup stuff added by Ethorbit for more accurate COD details
function nzRound:GetPowerUpsToSpawn()
	return self.PowerupsToSpawn
end

function nzRound:SetPowerUpsToSpawn(num)
	self.PowerupsToSpawn = num
end

function nzRound:SetPowerUpsGrabbed(num)
	self.PowerUpsGrabbed = num
end

function nzRound:GetPowerUpsGrabbed()
	return self.PowerUpsGrabbed
end

function nzRound:SetPowerUpPointsRequired(num)
	self.PowerupPointsRequired = num
end

function nzRound:GetPowerUpPointsRequired()
	return self.PowerupPointsRequired
end

function nzRound:GetZombiesToSpawn()
	return self.ZombiesToSpawn
end
function nzRound:SetZombiesToSpawn(num)
	self.ZombiesToSpawn = num
end
function nzRound:GetZombiesSpawned()
	return self.ZombiesMax - self.ZombiesToSpawn
end

function nzRound:GetZombieHealth()
	return self.ZombieHealth or 0
end

function nzRound:SetZombieHealth( num )
	self.ZombieHealth = num
	self:SendZombieHealth(num) -- Added by Ethorbit for better clientside support
end

function nzRound:GetHellHoundHealth()
	return self.ZombieHellHoundHealth
end

function nzRound:SetHellHoundHealth( num )
	self.ZombieHellHoundHealth = num
end

function nzRound:GetPanzerHealth()
	return self.PanzerHealth
end

function nzRound:SetPanzerHealth(num)
	self.PanzerHealth = num
end

-- function nzRound:GetNormalSpawner()
-- 	return self.hNormalSpawner
-- end

-- function nzRound:SetNormalSpawner(spawner)
-- 	self.hNormalSpawner = spawner
-- end

-- function nzRound:GetSpecialSpawner()
-- 	return self.hSpecialSpawner
-- end

-- function nzRound:SetSpecialSpawner(spawner)
-- 	self.hSpecialSpawner = spawner
-- end

function nzRound:GetZombieSpeeds()
	return self.ZombieSpeeds or {}
end

function nzRound:SetZombieSpeeds( tbl )
	self.ZombieSpeeds = tbl
	self:SendZombieSpeeds(tbl) -- Added by Ethorbit for better clientside support
end

function nzRound:SetGlobalZombieData( tbl )
	self:SetZombiesMax(tbl.maxzombies or 5)
	self:SetZombieHealth(tbl.health or 75)
	self:SetHellHoundHealth(tbl.hellhoundhealth or 75)
	self:SetSpecial(tbl.special or false)
end

function nzRound:InState( state )
	return self:GetState() == state
end

function nzRound:IsSpecial()
	if nzRound:GetSpecialRoundType() == "Hellhounds" and !nzMapping.Settings.enabledogs then return false end

	return self.SpecialRound or false
end

function nzRound:SetSpecial( bool )
	self.SpecialRound = bool or false
	self:SendSpecialRound( self.SpecialRound )
end

function nzRound:InProgress()
	return self:GetState() == ROUND_PREP or self:GetState() == ROUND_PROG
end

function nzRound:SetState( state )

	local oldstate = self.RoundState
	self.RoundState = state

	self:SendState( state )

	hook.Call("OnRoundChangeState", nzRound, state, oldstate)

end

function nzRound:GetState()

	return self.RoundState

end

function nzRound:SetNumber( number )
	self.Number = number

	self:SendNumber( number )

end

function nzRound:IncrementNumber()

	self:SetNumber( self:GetNumber() + 1 )

end

function nzRound:GetNumber()

	return self.Number

end

function nzRound:AutoSpawnRadius()
	local val = 2500

	local spawns = #ents.FindByClass("player_spawns") > 0 and ents.FindByClass("player_spawns") or ents.FindByClass("info_player_start")
	if spawns then
		local startPoint = spawns[1]:GetPos()

		if startPoint then
			local farthest_zombie_spawn_dist = nil

			for k,v in pairs(ents.FindByClass("nz_spawn_zombie_normal")) do
				if (!farthest_zombie_spawn_dist or startPoint:Distance(v:GetPos()) > farthest_zombie_spawn_dist) then -- This zombie position is currently the farthest
					farthest_zombie_spawn_dist = startPoint:Distance(v:GetPos())
				end
			end

			if farthest_zombie_spawn_dist then
				val = math.Clamp(math.Round(farthest_zombie_spawn_dist / 2.2), 1300, math.huge)
				val = val == 1300 and 0 or val
			end
		end
	end

	return val
end

function nzRound:GetSpawnRadius()
	return #player.GetAllPlaying() > 1 and self.fSpawnRadiusMP or self.fSpawnRadiusSP
end

function nzRound:SetTotalPoints(num)
	self.TotalPoints = num
end

function nzRound:GetTotalPoints()
	return self.TotalPoints or 0
end

function nzRound:SetSpawnRadiusMP(radius)
	self.fSpawnRadiusMP = radius
end

function nzRound:GetSpawnRadiusMP()
	return self.fSpawnRadiusMP
end

function nzRound:SetSpawnRadiusSP(radius)
	self.fSpawnRadiusSP = radius
end

function nzRound:UpdateSpawnRadius()
	local spawn_radius_ent = ents.FindByClass("edit_spawn_radius")[1]
	if (!spawn_radius_ent) then -- There is no custom spawn radius in the config, decide automatically
		if (!self:GetSpawnRadiusSP()) then
			self:SetSpawnRadiusSP(2500)
		end

		if (self:GetSpawnRadiusSP() != 0) then -- 0 means infinite, it should only be INCREASED for Multiplayer
			self:SetSpawnRadiusMP(math.Clamp(self:GetSpawnRadiusSP() + 1000, 1000, 3000))
		else
			self:SetSpawnRadiusMP(self:GetSpawnRadiusSP())
		end
	else -- Custom spawn radius exists, use its values
		self:SetSpawnRadiusSP(spawn_radius_ent:GetRadius())

		if (spawn_radius_ent:GetHasMultiplayerRadius()) then
			self:SetSpawnRadiusMP(spawn_radius_ent:GetMultiplayerRadius())
		else
			self:SetSpawnRadiusMP(self:GetSpawnRadiusSP())
		end
	end
end

function nzRound:GetSpawnRadiusSP()
	return self.fSpawnRadiusSP
end

function nzRound:GetBarricadePointCap()
	return self.BarricadePointCap
end

function nzRound:SetBarricadePointCap(points)
	self.BarricadePointCap = points
end

function nzRound:GetBoxHasMoved()
	return self.BoxHasMoved
end

function nzRound:SetBoxHasMoved(val)
	self.BoxHasMoved = val
end

function nzRound:SetEndTime( time )

	SetGlobalFloat( "nzEndTime", time )

end

function nzRound:GetEndTime( time )

	GetGlobalFloat( "nzEndTime" )

end

function nzRound:GetNextSpawnTime()
	return self.NextSpawnTime or 0
end
function nzRound:SetNextSpawnTime( time )
	self.NextSpawnTime = time
end
