--Gamemode Overrides

function GM:PlayerInitialSpawn( ply )
	timer.Simple( 0, function() ply:SetSpectator() end )
end

function GM:PlayerDeath( ply, wep, killer )
	ply:SetSpectator()
	ply:SetTargetPriority(TARGET_PRIORITY_NONE)
end

function GM:PlayerDeathThink( ply )

	-- Allow players in creative mode to respawn
	if ply:IsInCreative() and nzRound:InState( ROUND_CREATE ) then
		if ply:KeyDown(IN_JUMP) or ply:KeyDown(IN_ATTACK) then
			ply:Spawn()
			return true
		end
	end

	--local players = player.GetAllPlayingAndAlive()
	local players = {}
	for _,v in pairs(player.GetAll()) do
		if (IsValid(v) and (v:Team() == TEAM_PLAYERS or v:IsInCreative()) and v:Alive()) then
			table.insert(players, v)
		end
	end

	if #players <= 0 then
		if ply:GetObserverMode() != OBS_MODE_ROAMING then
			ply:SetObserverMode(OBS_MODE_ROAMING)
			ply:SpectateClosestEntity()
		end
	elseif ply:KeyPressed( IN_RELOAD ) and IsValid(ply:GetObserverTarget()) and ply:GetObserverTarget():IsPlayer() then
		ply:SetSpectatingType( ply:GetSpectatingType() + 1 )
		if ply:GetSpectatingType() > 5 then
			ply:SetSpectatingType( 4 )
			ply:SetupHands(players[ ply:GetSpectatingID() ])
		end

		ply:Spectate( ply:GetSpectatingType() )
	elseif ply:KeyPressed( IN_ATTACK ) then
		ply:SetSpectatingID( ply:GetSpectatingID() + 1 )
		if ply:GetSpectatingID() > #players then ply:SetSpectatingID( 1 ) end
		ply:SpectateEntity( players[ ply:GetSpectatingID() ] )
	elseif ply:KeyPressed( IN_ATTACK2 ) then
		ply:SetSpectatingID( ply:GetSpectatingID() - 1 )
		if ply:GetSpectatingID() <= 0 then ply:SetSpectatingID( #players ) end
		ply:SpectateEntity( players[ ply:GetSpectatingID() ] )
	elseif ply:KeyPressed( IN_JUMP ) then
		if (ply:GetSpectatingType() == 6) then
			ply:SetSpectatingType(5)
		else
			ply:SetSpectatingType(6)
		end

		ply:Spectate(ply:GetSpectatingType())
	end

	local targ = ply:GetObserverTarget()

	-- Always spectate something valid, added by Ethorbit because of all the visual bugs
	if ply:GetSpectatingType() != 6 or #players <= 1 then -- Leave them be if they're roaming around. unless a new game started
		if !IsValid(targ)  then
			ply:SpectateClosestEntity()
			ply:SetObserverMode(OBS_MODE_ROAMING)
		elseif targ:IsPlayer() and targ:Team() != TEAM_PLAYERS and !targ:IsInCreative() then -- We're spectating a spectator or dead player...
			ply:SpectateClosestEntity()
			ply:SetObserverMode(OBS_MODE_ROAMING)
		elseif !targ:IsPlayer() and #player.GetAllPlayingAndAlive() > 0 then -- We're not spectating a player even though we can
			ply:SpectateEntity(player.GetAllPlayingAndAlive()[1])
			ply:SetObserverMode(OBS_MODE_CHASE)
		end
	end

	ply:SetMoveType(MOVETYPE_OBSERVER)
end

local function disableDeadUse( ply, ent )
	if !ply:Alive() then return false end
end

hook.Add( "PlayerUse", "nzDisableDeadUse", disableDeadUse)

local hooks = hook.GetTable().AllowPlayerPickup
if hooks then
	for k,v in pairs(hooks) do
		hook.Remove("AllowPlayerPickup", k)
	end
end

local function disableDeadPickups( ply, ent )
	if !ply:Alive() then
		return false
	else
		-- This will allow pickups even if the weapon can't holster
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and !wep:IsSpecial() then
			local holster = wep.Holster
			wep.Holster = function() return true end
			timer.Simple(0, function() wep.Holster = holster end)
		end
		return true
	end
end

hook.Add( "AllowPlayerPickup", "_nzDisableDeadPickups", disableDeadPickups)
