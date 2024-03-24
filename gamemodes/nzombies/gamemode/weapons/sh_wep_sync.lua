-- Client Server Syncing


if SERVER then

	-- Server to client (Server)
	util.AddNetworkString( "nzWeps.Sync" )

	function nzWeps:SendSync( ply, weapon, modifier, revert )
		net.Start( "nzWeps.Sync" )
		net.WriteEntity ( ply )
		net.WriteString( weapon:GetClass() )
		net.WriteEntity( weapon )
		net.WriteString( modifier )
		net.WriteBool( revert )
		return net.Broadcast()
	end

end

if CLIENT then

	-- Server to client (Client)
	local function ReceiveSync( length )
		local owner = net.ReadEntity()
		local wepClass = net.ReadString()
		local wep = net.ReadEntity()
		local modifier = net.ReadString()
		local revert = net.ReadBool()

		if (!IsValid(wep) and (modifier == "pap" or modifier == "repap")) then
			timer.Create("fixingstupidpapcamo", 0, 2000, function()
				if (IsValid(owner)) then
					wep = owner:GetWeapon(wepClass)
				end

				if IsValid(wep) and modifier then
					if revert then
						wep:RevertNZModifier(modifier)
					else
						wep:ApplyNZModifier(modifier)
					end

					timer.Destroy("fixingstupidpapcamo")
				end
			end)
		else
			if !IsValid(wep) or !modifier then return end
		
			if revert then
				wep:RevertNZModifier(modifier)
			else
				wep:ApplyNZModifier(modifier)
			end	
		end
	end

	-- Receivers
	net.Receive( "nzWeps.Sync", ReceiveSync )
end
