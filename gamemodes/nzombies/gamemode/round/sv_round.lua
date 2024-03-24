function GM:InitPostEntity()

	nzRound:Waiting()

end

function nzRound:Waiting()

	self:SetState( ROUND_WAITING )
	hook.Call( "OnRoundWaiting", nzRound )

end

function nzRound:Init()
	self:SetNextSpecialRound(nil) -- This gets dynamically set inside our special spawners

    self:ResetPlayerSpawns()
    
	timer.Simple( 5, function() self:SetupGame() self:Prepare() end )
	self:SetState( ROUND_INIT )
	self:SetEndTime( CurTime() + 5 )
	PrintMessage( HUD_PRINTTALK, "5 seconds till start time." )
	hook.Call( "OnRoundInit", nzRound )

end

function nzRound:Prepare( time )
	nzRound:UpdateSpawnRadius()

    --self:UpdatePlayerSpawns() -- moved to ReadyUp.

	-- Update special round type every round, before special state is set
	local roundtype = nzMapping.Settings.specialroundtype
	self:SetSpecialRoundType(roundtype)

	if self:IsSpecial() then
		self:SetSpecialCount(self:GetSpecialCount() + 1)
	end

	self:SetBossCount(math.floor(1 + (#player.GetAllPlaying() / 6))) -- Support for multiple bosses by Ethorbit. The reasoning here is 4 players is default in cod, 2 more should spawn an additional boss.
	self:SetBossesSpawned(0)

	if self:IsBossRound() then
		self:SetBossRoundsElapsed(self:GetBossRoundsElapsed() + 1)
	end

	-- Set special for the upcoming round during prep, that way clients have time to fade the fog in
	self:SetSpecial( self:MarkedForSpecial( self:GetNumber() + 1 ) )
	self:SetIsBossRound( self:MarkedForBoss( self:GetNumber() + 1 ) )
	self:SetState( ROUND_PREP )
	self:IncrementNumber()

	self:SetZombieHealth( nzCurves.GenerateHealthCurve(self:GetNumber()) )
	self:SetHellHoundHealth( nzCurves.GenerateHellHoundHealth(self:GetNumber()) )
	self:SetPanzerHealth( self:GetNumber() * 75 + 500 )

	self:SetZombiesMax( nzCurves.GenerateMaxZombies(self:GetNumber()) )
	self:SetZombieSpeeds( nzCurves.GenerateSpeedTable(self:GetNumber()) )

	--self:SetZombiesKilled( 0 )
	self:ClearZombiesKilled()

	--Notify
	--PrintMessage( HUD_PRINTTALK, "ROUND: " .. self:GetNumber() .. " preparing" )

	for _,spawner in pairs(Spawner:GetAll()) do
		spawner:Reset()
	end

	hook.Call( "OnRoundPreparation", nzRound, self:GetNumber() )
	--Play the sound

	--Spawn all players
	--Check config for dropins
	--For now, only allow the players who started the game to spawn
	for _, ply in pairs( player.GetAllPlaying() ) do
		ply:ReSpawn()
	end

	--Set this to reset the overspawn debug message status
	CurRoundOverSpawned = false

	--Start the next round
	local time = time or GetConVar("nz_round_prep_time"):GetFloat()
	if self:GetNumber() == -1 then time = 20 end
	--timer.Simple(time, function() if self:InProgress() then self:Start() end end )

	local starttime = CurTime() + time
	hook.Add("Think", "nzRoundPreparing", function()
		if CurTime() > starttime then
			if self:InProgress() then self:Start() end
			hook.Remove("Think", "nzRoundPreparing")
		end
	end)
end

local CurRoundOverSpawned = false

function nzRound:Start()
	self:SetState( ROUND_PROG )

	-- Setup powerup stuff
	self:SetPowerUpPointsRequired(#player.GetAllPlayingAndAlive() * 2000 + GetConVar("nz_difficulty_powerup_required_round_points_base"):GetInt())
	self:SetPowerUpsToSpawn(math.Clamp(#player.GetAllPlayingAndAlive(), 4, #player.GetAll())) --GetConVar("nz_difficulty_powerup_max_per_round"):GetInt())
	self:SetPowerUpsGrabbed(0)
	--nzPowerUps:Shuffle() -- comment out once we finally add cyclical powerups

	-- Barricade Point cap
	timer.Simple(3, function()
		if self then
			self:SetBarricadePointCap(nzCurves.GenerateBarricadePointCap(self:GetNumber()))
			for _,ply in pairs(player.GetAll()) do
				if ply.SetRoundBarricadePoints then
					ply:SetRoundBarricadePoints(0)
				end
			end
		end
	end)

	--Notify
	--PrintMessage( HUD_PRINTTALK, "ROUND: " .. self:GetNumber() .. " started" )
	hook.Call("OnRoundStart", nzRound, self:GetNumber() )
	--nzNotifications:PlaySound("nz/round/round_start.mp3", 1)

	timer.Create( "NZRoundThink", 0.1, 0, function() self:Think() end )

	nzWeps:DoRoundResupply()

	self.fTimeStarted = CurTime()

	if self:GetNumber() == -1 then
		self.InfinityStart = CurTime()
	end
end

function nzRound:TimeStarted() -- The time the round started at
	return self.fTimeStarted
end

function nzRound:TimeElapsed() -- How long a round has been in progress
	return CurTime() - self:TimeStarted()
end

function nzRound:Think()
	if self.Frozen then return end
	hook.Call( "OnRoundThink", self )
	--If all players are dead, then end the game.
	if #player.GetAllPlayingAndAlive() < 1 then
		self:End()
		timer.Remove( "NZRoundThink" )
		return -- bail
	end

	--If we've killed all the spawned zombies, then progress to the next level.
	local numzombies = nzEnemies:TotalAlive()

	if ( self:GetZombiesKilled() >= self:GetZombiesMax() and self:GetNumber() != -1 ) then
		if numzombies <= 0 then
			self:Prepare()
			timer.Remove( "NZRoundThink" )
		end
	end
end

function nzRound:ResetGame()
	--Main Behaviour
	nzDoors:LockAllDoors()
	self:Waiting()
	--Notify
	PrintMessage( HUD_PRINTTALK, "GAME READY!" )
	
    --Reset variables
	self:SetNumber( 0 )
	self:SetSpecialCount( 0 )

	self:SetZombiesKilled( 0 )
	self:SetZombiesMax( 0 )

	Spawner:ResetSpawners()

	--Reset all player ready states
	for _, ply in pairs( player.GetAllReady() ) do
		ply:UnReady()
	end

	--Reset all downed players' downed status
	for k,v in pairs( player.GetAll() ) do
		v:KillDownedPlayer( true )
		v.SoloRevive = nil -- Reset Solo Revive counter
		v:SetPreventPerkLoss(false)
		v:RemovePerks()
	end

	--Remove all enemies
	for k,v in pairs( nzConfig.ValidEnemies ) do
		for k2, v2 in pairs( ents.FindByClass( k ) ) do
			v2:Remove()
		end
	end

	--Resets all active palyers playing state
	for _, ply in pairs( player.GetAllPlaying() ) do
		ply:SetPlaying( false )
	end

	--Reset the electricity
	nzElec:Reset(true)

	--Remove the random box
	nzRandomBox.Remove()

	--Reset all perk machines
	for k,v in pairs(ents.FindByClass("perk_machine")) do
		v:TurnOff()
	end

	for _, ply in pairs(player.GetAll()) do
		ply:SetPoints(0) --Reset all player points
		ply:RemovePerks() --Remove all players perks
		ply:SetTotalRevives(0) --Reset all player total revive
		ply:SetTotalDowns(0) --Reset all player total down
		ply:SetTotalKills(0) --Reset all player total kill
	end

	--Clean up powerups
	nzPowerUps:CleanUp()

	--Reset easter eggs
	nzEE:Reset()
	nzEE.Major:Reset()

	-- Load queued config if any
	if nzMapping.QueuedConfig then
		nzMapping:LoadConfig(nzMapping.QueuedConfig.config, nzMapping.QueuedConfig.loader)
	end

end

function nzRound:End()
	--Main Behaviour
	self:SetState( ROUND_GO )
	--Notify
	PrintMessage( HUD_PRINTTALK, "GAME OVER!" )
	PrintMessage( HUD_PRINTTALK, "Restarting in 10 seconds!" )
	if self:GetNumber() == -1 then
		if self.InfinityStart then
			local time = string.FormattedTime(CurTime() - self.InfinityStart)
			local timestr = string.format("%02i:%02i:%02i", time.h, time.m, time.s)
			net.Start("nzMajorEEEndScreen")
				net.WriteBool(false)
				net.WriteBool(false)
				net.WriteString("You survived for "..timestr.." in Round Infinity")
				net.WriteFloat(10)
				net.WriteBool(false)
			net.Broadcast()
		end
		nzNotifications:PlaySound("nz/round/game_over_-1.mp3", 21)
	elseif nzMapping.OfficialConfig then
		nzNotifications:PlaySound("nz/round/game_over_5.mp3", 21)
	else
		--nzNotifications:PlaySound("nz/round/game_over_4.mp3", 21)
		nzSounds:Play("GameEnd")

	-- 	nzNotifications:PlaySound("nz/round/game_over_-1.mp3", 21)
	-- elseif nzMapping.OfficialConfig then
	-- 	nzNotifications:PlaySound("nz/round/game_over_5.mp3", 21)
	-- else
	-- 	nzNotifications:PlaySound("nz/round/game_over_4.mp3", 21)
	end

	timer.Simple(10, function()
		self:ResetGame()
	end)

	hook.Call( "OnRoundEnd", nzRound )
end

function nzRound:Win(message, keepplaying, time, noautocam, camstart, camend)
	if !message then message = "You survived after " .. self:GetNumber() .. " rounds!" end
	local time = time or 10

	if not noautocam then
		net.Start("nzMajorEEEndScreen")
			net.WriteBool(false)
			net.WriteBool(true)
			net.WriteString(message)
			net.WriteFloat(time)
			if camstart and camend then
				net.WriteBool(true)
				net.WriteVector(camstart)
				net.WriteVector(camend)
			else
				net.WriteBool(false)
			end
		net.Broadcast()
	end

	-- Set round state to Game Over
	if !keepplaying then
		nzRound:SetState( ROUND_GO )
		--Notify with chat message
		PrintMessage( HUD_PRINTTALK, "GAME OVER!" )
		PrintMessage( HUD_PRINTTALK, "Restarting in 10 seconds!" )

		if self.OverrideEndSlomo then
			game.SetTimeScale(0.25)
			timer.Simple(2, function() game.SetTimeScale(1) end)
		end

		timer.Simple(time, function()
			nzRound:ResetGame()
		end)

		hook.Call( "OnRoundEnd", nzRound )
	else
		for k,v in pairs(player.GetAllPlaying()) do
			v:SetTargetPriority(TARGET_PRIORITY_NONE)
		end
		if self.OverrideEndSlomo then
			game.SetTimeScale(0.25)
			timer.Simple(2, function() game.SetTimeScale(1) end)
		end
		timer.Simple(time, function()
			for k,v in pairs(player.GetAllPlaying()) do
				if (v:Team() == TEAM_PLAYERS or v:IsInCreative()) then
					v:SetTargetPriority(TARGET_PRIORITY_PLAYER)
				end

				--v:GivePermaPerks()
			end
		end)
	end

end

function nzRound:Lose(message, time, noautocam, camstart, camend)
	if !message then message = "You got overwhelmed after " .. self:GetNumber() .. " rounds!" end
	local time = time or 10

	if not noautocam then
		net.Start("nzMajorEEEndScreen")
			net.WriteBool(false)
			net.WriteBool(true)
			net.WriteString(message)
			net.WriteFloat(time)
			if camstart and camend then
				net.WriteBool(true)
				net.WriteVector(camstart)
				net.WriteVector(camend)
			else
				net.WriteBool(false)
			end
		net.Broadcast()
	end

	-- Set round state to Game Over
	nzRound:SetState( ROUND_GO )
	--Notify with chat message
	PrintMessage( HUD_PRINTTALK, "GAME OVER!" )
	PrintMessage( HUD_PRINTTALK, "Restarting in 10 seconds!" )

	if self.OverrideEndSlomo then
		game.SetTimeScale(0.25)
		timer.Simple(2, function() game.SetTimeScale(1) end)
	end

	timer.Simple(time, function()
		nzRound:ResetGame()
	end)

	hook.Call( "OnRoundEnd", nzRound )
end

function nzRound:Create(on)
    self:ResetPlayerSpawns()

    if on then
		if self:InState( ROUND_WAITING ) then
			PrintMessage( HUD_PRINTTALK, "The mode has been set to creative mode!" )
			self:SetState( ROUND_CREATE )
			hook.Call("OnRoundCreative", nzRound)
			--We are in create
			for _, ply in pairs( player.GetAll() ) do
				if ply:IsNZAdmin() then
					ply:GiveCreativeMode()
				end
				if ply:IsReady() then
					ply:SetReady( false )
				end
			end

			nzMapping:CleanUpMap()
			nzDoors:LockAllDoors()
			nzParts:ResetAll()
			nzBenches:ResetAll()

            
			for k,v in pairs(ents.GetAll()) do
				if v.NZOnlyVisibleInCreative then
					v:SetNoDraw(false)
				end
			end

			self:SetZombieHealth(100)
		else
			PrintMessage( HUD_PRINTTALK, "Can only go in Creative Mode from Waiting state." )
		end
	elseif self:InState( ROUND_CREATE ) then
		PrintMessage( HUD_PRINTTALK, "The mode has been set to play mode!" )
		self:SetState( ROUND_WAITING )
		hook.Call("OnRoundPlay", nzRound)

		--We are in play mode
		for k,v in pairs(player.GetAll()) do
			v:SetSpectator()
		end

		for k,v in pairs(ents.GetAll()) do
			if v.NZOnlyVisibleInCreative then -- This is set in each entity's file
				v:SetNoDraw(true) -- Yes this improves FPS by ~50% over a client-side convar and round state check
			end
		end
	else
		PrintMessage( HUD_PRINTTALK, "Not in Creative Mode." )
	end
end

function nzRound:SetupGame()
	self:SetNumber( 0 )
	self:SetSpecialCount(0)
	self:SetBossCount(0)
	self:SetSpawnRadiusSP(self:AutoSpawnRadius())

	self:SetBoxHasMoved(false)

	--Spawner:ResetSpawners()

	-- Store a session of all our players
	for _, ply in pairs(player.GetAll()) do
		if ply:IsValid() and ply:IsReady() then
			ply:SetPlaying( true )
		end
		ply:SetFrags( 0 ) --Reset all player kills
	end

	nzMapping:CleanUpMap()
	nzDoors:LockAllDoors()

	-- Open all doors with no price and electricity requirement
	for k,v in pairs(ents.GetAll()) do
		if v:IsBuyableEntity() then
			local data = v:GetDoorData()
			if data then
				if tonumber(data.price) == 0 and tobool(data.elec) == false then
					nzDoors:OpenDoor( v )
				end
			end
		end
		-- Setup barricades
		if v:GetClass() == "breakable_entry" then
			v:ResetPlanks()
		end
	end

	-- Empty the link table
	table.Empty(nzDoors.OpenedLinks)

	-- All doors with Link 0 (No Link)
	nzDoors.OpenedLinks[0] = true
	--nz.nzDoors.Functions.SendSync()

	-- Spawn a random box at a possible starting position
	nzRandomBox.Spawn(nil, true)

	local power = ents.FindByClass("power_box")
	if !IsValid(power[1]) then -- No power switch D:
		nzElec:Activate(true) -- Silently turn on the power
	else
		nzElec:Reset() -- Reset with no value to play the power down sound
	end

	nzPerks:UpdateQuickRevive()

	--nzRound:SetNextSpecialRound( GetConVar("nz_round_special_interval"):GetInt() )
	-- if (nzMapping.Settings.autodogrounds) then
	-- 	self:SetNextSpecialRound(math.random(5, 8))
	-- else
	-- 	self:SetNextSpecialRound(math.random(nzMapping.Settings.dogroundminoffset, nzMapping.Settings.dogroundmaxoffset))
	-- end

	nzEE.Major:Reset()

	hook.Call( "OnGameBegin", nzRound )

end

function nzRound:Freeze(bool)
	self.Frozen = bool
end

function nzRound:RoundInfinity(nokill)
	if !nokill then
		nzPowerUps:Nuke(nil, true) -- Nuke kills them all, no points, no position delay
	end

	nzRound:SetNumber( -2 )
	nzRound:SetState(ROUND_PROG)
	nzRound:Prepare()
end
