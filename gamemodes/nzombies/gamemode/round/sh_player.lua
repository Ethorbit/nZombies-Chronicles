local plyMeta = FindMetaTable( "Player" )

AccessorFunc( plyMeta, "bReady", "Ready", FORCE_BOOL )
function plyMeta:IsReady() return self:GetReady() end

AccessorFunc( plyMeta, "bPlaying", "Playing", FORCE_BOOL )
function plyMeta:IsPlaying() return self:GetPlaying() end

function plyMeta:IsSpectating() return self:Team() == TEAM_SPECTATOR end

function plyMeta:IsInCreative() return player_manager.GetPlayerClass( self ) == "player_create" end

local player = player

--player.utils
function player.GetAllReady()
	local result = {}
	for _, ply in pairs( player.GetAll() ) do
		if ply:IsReady() then
			table.insert( result, ply )
		end
	end

	return result
end

function player.GetAllPlaying()
	local result = {}
	for _, ply in pairs( player.GetAll() ) do
		if ply:IsPlaying() then
			table.insert( result, ply )
		end
	end

	return result
end

function player.GetAllPlayingAndAlive()
	local result = {}
	for _, ply in pairs( player.GetAllPlaying() ) do
		if ply:Alive() and (ply:GetNotDowned() or ply.HasWhosWho or ply.DownedWithSoloRevive) then -- Who's Who will respawn the player, don't end yet
			table.insert( result, ply )
		end
	end

	return result
end

function player.GetAllNonSpecs()
	local result = {}
	for _, ply in pairs( player.GetAll() ) do
		if ply:Team() != TEAM_SPECTATOR then
			table.insert( result, ply )
		end
	end

	return result
end

function player.GetAllTargetable()
	local result = {}
	for _, ply in pairs(player.GetAll()) do
		if ply:GetTargetPriority() > 0 then
			table.insert( result, ply )
		end
	end
	
	return result
end

function player.FindBySpawnerClass(ply)
    local result = {}
    
    for _, plySpawn in pairs(ents.FindByClass(ply:GetSpawnerClass())) do
        if (plySpawn:HasPlayer(self)) then
            table.insert(result, ply)
        end    
    end

    return result
end

// Keep track of players that are connecting, Gmod is too dumb
// to provide that functionality by default:
local players_connecting = {}
local player_last_connect_time = CurTime()
local player_last_disconnect_time = 0

function player.GetAllConnecting()
	local tbl = {}
	
	for k,_ in pairs(players_connecting) do
		tbl[#tbl + 1] = k 
	end

	return tbl
end

function player.GetLastConnectTime()
	return math.Clamp(CurTime() - player_last_connect_time, 0, math.huge)
end

function player.GetLastDisconnectTime()
	return math.Clamp(CurTime() - player_last_disconnect_time, 0, math.huge)
end

gameevent.Listen(SERVER and "player_connect" or "player_connect_client")
hook.Add(SERVER and "player_connect" or "player_connect_client", "NZConnectingPlayersConnect", function(data)
	local id = data.networkid
	if id == "BOT" then return end -- Bots get into the game immediately, and players who are in the game are not counted as connecting
	players_connecting[id] = true
	player_last_connect_time = CurTime()
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "NZConnectingPlayersDisconnect", function(data)
	local id = data.networkid
	players_connecting[id] = nil
	player_last_disconnect_time = CurTime()
end)

-- They're in, which means they're not connecting anymore - so remove them:
gameevent.Listen("player_spawn")
hook.Add("player_spawn", "NZConnectingPlayersAuthed", function(data)
	local ply = Player(data.userid)
	if !IsValid(ply) then return end
	
	local id = ply:SteamID()
	players_connecting[id] = nil
end)
