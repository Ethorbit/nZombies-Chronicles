if SERVER then
	util.AddNetworkString( "nzRoundNumber" )
	util.AddNetworkString( "nzRoundState" )
	util.AddNetworkString( "nzRoundSpecial" )
	util.AddNetworkString( "nzPlayerReadyState" )
	util.AddNetworkString( "nzPlayerPlayingState" )

	-- Extra networking brought in by: Ethorbit
	util.AddNetworkString("nz.ZombiesMax")
	util.AddNetworkString("nz.ZombiesKilled")
	util.AddNetworkString("nz.ZombieHealth")
	util.AddNetworkString("nz.ZombieSpeeds")

	function nzRound:SendNumber( number, ply )

		net.Start( "nzRoundNumber" )
			net.WriteInt( number or 0, 16 )
		return ply and net.Send( ply ) or net.Broadcast()

	end

	function nzRound:SendState( state, ply )

		net.Start( "nzRoundState" )
			net.WriteUInt( state or ROUND_WAITING, 3 )
		return ply and net.Send( ply ) or net.Broadcast()

	end

	function nzRound:SendSpecialRound( bool, ply )

		net.Start( "nzRoundSpecial" )
			net.WriteBool( bool or false )
		return ply and net.Send( ply ) or net.Broadcast()

	end

	function nzRound:SendReadyState( ply, state, recieverPly )

		net.Start( "nzPlayerReadyState" )
			net.WriteEntity( ply )
			net.WriteBool( state )
		return recieverPly and net.Send( recieverPly ) or net.Broadcast()

	end

	function nzRound:SendPlayingState( ply, state, recieverPly )

		net.Start( "nzPlayerPlayingState" )
			net.WriteEntity( ply )
			net.WriteBool( state )
		return recieverPly and net.Send( recieverPly ) or net.Broadcast()

	end

	function nzRound:SendSync(ply)
		self:SendNumber( self:GetNumber(), ply )
		self:SendSpecialRound( self:IsSpecial(), ply)
		self:SendState(self:GetState(), ply)
		self:SendZombiesMax(self:GetZombiesMax(), ply)
		self:SendZombiesKilled(self:GetZombiesKilled(), ply)
		self:SendZombieHealth(self:GetZombieHealth(), ply)
		self:SendZombieSpeeds(self:GetZombieSpeeds(), ply)

		for _, v in pairs(player.GetAll()) do
			self:SendReadyState(v, v:GetReady(), ply)
			self:SendPlayingState(v, v:GetPlaying(), ply)
		end

		self:SetEndTime( self:GetEndTime() )

	end

	FullSyncModules["Round"] = function(ply)
		nzRound:SendSync(ply)
	end

	-- Extra stuff brought in by: Ethorbit
	function nzRound:SendZombiesMax(num, ply)
		if !num then return end
		net.Start("nz.ZombiesMax")
		net.WriteInt(num, 25)
		return ply and net.Send(ply) or net.Broadcast()
	end

	function nzRound:SendZombiesKilled(num, ply)
		if !num then return end
		net.Start("nz.ZombiesKilled")
		net.WriteInt(num, 25)
		return ply and net.Send(ply) or net.Broadcast()
	end

	function nzRound:SendZombieHealth(num, ply) -- Commented because I gave zombiebase entities a :GetMaxHealth(), which supports more than just walkers like this does.
		-- if !num then return end
		-- net.Start("nz.ZombieHealth")
		-- net.WriteInt(num, 25)
		-- return ply and net.Send(ply) or net.Broadcast()
	end

	function nzRound:SendZombieSpeeds(tbl, ply)
		if !tbl then return end
		net.Start("nz.ZombieSpeeds")
		net.WriteTable(tbl)
		return ply and net.Send(ply) or net.Broadcast()
	end
end

if CLIENT then
	local function receiveRoundState()
		local old = nzRound:GetState()
		new = net.ReadUInt( 3 )

		nzRound:SetState( new )

		if old != new then
			nzRound:StateChange( old, new )
		end
	end
	net.Receive( "nzRoundState", receiveRoundState )


	local function receiveRoundNumber()
		nzRound:SetNumber( net.ReadInt( 16 ) )
	end
	net.Receive( "nzRoundNumber", receiveRoundNumber)

	local function receiveSpecialRound()
		nzRound:SetSpecial( net.ReadBool() )
	end
	net.Receive( "nzRoundSpecial", receiveSpecialRound )


	local function receivePlayerReadyState()
		local ply = net.ReadEntity()
		if IsValid(ply) then
			ply:SetReady( net.ReadBool() )
		end
	end
	net.Receive( "nzPlayerReadyState", receivePlayerReadyState )

	local function receivePlayerPlayingState()
		local ply = net.ReadEntity()
		if IsValid(ply) then
			ply:SetPlaying( net.ReadBool() )
		end
	end
	net.Receive( "nzPlayerPlayingState", receivePlayerPlayingState )

	-- Extra stuff brought in by: Ethorbit
	net.Receive("nz.ZombiesMax", function()
		local num = net.ReadInt(25)
		nzRound:SetZombiesMax(num)
	end)

	net.Receive("nz.ZombiesKilled", function()
		nzRound:SetZombiesKilled(net.ReadInt(25))
	end)

	net.Receive("nz.ZombieHealth", function()
		nzRound:SetZombieHealth(net.ReadInt(25))
	end)

	net.Receive("nz.ZombieSpeeds", function()
		nzRound:SetZombieSpeeds(net.ReadTable())
	end)
end
