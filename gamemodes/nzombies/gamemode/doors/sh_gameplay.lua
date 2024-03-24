function nzDoors.OnUseDoor(ply, key)
	if (ply:GetNotDowned() and key == IN_USE) then -- Downed players can't use anything!
		local tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector() * 90, ply)
		local useEnt = tr.Entity
		if (IsValid(useEnt) and useEnt:IsBuyableEntity()) then
			-- Players can't use stuff while using special weapons! (Perk bottles, knives, etc)
			local activeWep = ply:GetActiveWeapon()
			if (IsValid(activeWep) and !activeWep:IsSpecial()) then
				if useEnt.buyable == nil or tobool(useEnt.buyable) then
                    if SERVER then
					    nzDoors:BuyDoor(ply, useEnt)
                    end

                    hook.Run("NZ.PlayerUsedEntity", ply, useEnt)
				end
			end
		end
	end
end
hook.Add("KeyPress", "nzPlayerBuyDoor", nzDoors.OnUseDoor)