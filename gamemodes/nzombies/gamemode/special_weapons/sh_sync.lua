if SERVER then
	util.AddNetworkString("nzUpdateMyWeapons")
	util.AddNetworkString("nzSendSpecialWeapon")

	-- Update their special weapons, auto called when their 
	-- special weapon returns as nil and they can't switch to it
	net.Receive("nzUpdateMyWeapons", function(len, ply) 
		if (!isnumber(ply.LastUpdatedWeapons) or CurTime() - ply.LastUpdatedWeapons > 4) then -- Some spam protection
			print(ply:Nick() .. " requested a Special Weapons update.")
			ply:UpdateSpecialWeapons()
			ply.LastUpdatedWeapons = CurTime()
		end
	end)

	function nzSpecialWeapons:SendSpecialWeaponAdded(ply, wep, id)
		timer.Simple(0.5, function()
			if IsValid(ply) then
				net.Start("nzSendSpecialWeapon")
					net.WriteString(id)
					net.WriteBool(true)
					net.WriteEntity(wep)
				net.Send(ply)
			end
		end)
	end
	
	function nzSpecialWeapons:SendSpecialWeaponRemoved(ply, id)
		timer.Simple(0.1, function()
			if IsValid(ply) then
				net.Start("nzSendSpecialWeapon")
					net.WriteString(id)
					net.WriteBool(false)
				net.Send(ply)
			end
		end)
	end
end

if CLIENT then
	local function ReceiveSpecialWeaponAdded()
		if !LocalPlayer().NZSpecialWeapons then LocalPlayer().NZSpecialWeapons = {} end
		local id = net.ReadString()
		local bool = net.ReadBool()
		
		if bool then
			local ent = net.ReadEntity()
			LocalPlayer().NZSpecialWeapons[id] = ent
		else
			LocalPlayer().NZSpecialWeapons[id] = nil
		end
	end
	net.Receive("nzSendSpecialWeapon", ReceiveSpecialWeaponAdded)
end