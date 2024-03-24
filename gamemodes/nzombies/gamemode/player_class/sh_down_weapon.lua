-- Functions used to make players use a special weapon meant for when they are down
-- just like in COD
-- local PLAYER = FindMetaTable("Player")
-- function PLAYER:DownWeaponClass()
-- 	return "tfa_down_weapon" .. self:EntIndex()
-- end

-- function PLAYER:CreateDownWeapon(wep)
--     local startWep = !isstring(wep) and nzMapping.Settings.startwep
--     if (self.lastDownedWep != startWep) then
--         self.lastDownedWep = startWep

--         if (isstring(startWep)) then 
--             local tblWep = weapons.Get(startWep) 
--             tblWep.NZSpecialCategory = "Down Weapon"
--             tblWep.IsSpecial = function()
--                 return true
--             end

--             if (istable(tblWep)) then -- Starting wep is a real weapon
--                 weapons.Register(tblWep, self:DownWeaponClass())
--             end
--         end
--     end
-- end

-- if SERVER then 
--     function PLAYER:GiveDownWeapon(wep)
--         self:Give(self:DownWeaponClass()) 
--         self:SetActiveWeapon(self:GetWeapon(self:DownWeaponClass()))
--     end

--     function PLAYER:StripDownWeapon()
--         self:StripWeapon(self:DownWeaponClass())
--         self:SetActiveWeapon(nil)
--         self:EquipPreviousWeapon()
--     end
-- end