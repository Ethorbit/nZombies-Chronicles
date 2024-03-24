-- Update Ammos
local function UpdatePrimSec(ply, wep)
    if (IsValid(ply)) then
        if (!wep) then 
            wep = ply:GetActiveWeapon()
        end

        if (IsValid(wep) and wep.Ammo1 and wep.Ammo2) then
            if (wep.Ammo1) then
                ply:SetNWInt("Spec_PrimaryAmmo", wep:Ammo1())
            end

            if (wep.Ammo2) then 
                ply:SetNWInt("Spec_SecondaryAmmo", wep:Ammo2())          
            end
        end
    end
end

hook.Add("PlayerAmmoChanged", "NZPlyAmmoNetworkFix", function(ply, ammoID, oldCount, newCount)
    if (IsValid(ply)) then
        if (ammoID == GetNZAmmoID("grenade")) then
            ply:SetNWInt("Spec_Nades", newCount)
        return end

        if (ammoID == GetNZAmmoID("specialgrenade")) then
            ply:SetNWInt("Spec_NadesSpecial", newCount)
        return end

        timer.Simple(0, function() UpdatePrimSec(ply) end)
    end
end)

hook.Add("PlayerSwitchWeapon", "NZPlyAmmoNetworkFixSwitch", function(ply, oldWep, newWep)
    if (IsValid(ply) and IsValid(newWep)) then
        UpdatePrimSec(ply, newWep)
        ply:SetNWInt("Spec_Clip1", newWep:Clip1())
        ply:SetNWInt("Spec_Clip2", newWep:Clip2())
    end 
end)

-- Update Clips
local SWEP = FindMetaTable("Weapon")
if (SWEP and SWEP.SetClip1 and SWEP.SetClip2) then -- They both exist now, it is safe to build off them (our changes won't get overrided by TFA Base)   
    local oldFunc = SWEP.SetClip1
    function SWEP:SetClip1(num)
        if (IsValid(self)) then
            if (IsValid(self.Owner)) then
                self.Owner:SetNWInt("Spec_Clip1", num)
            end

            return oldFunc(self, num)
        end
    end

    local oldFunc2 = SWEP.SetClip2
    function SWEP:SetClip2(num)
        if (IsValid(self)) then
            if (IsValid(self.Owner)) then
                self.Owner:SetNWInt("Spec_Clip2", num)
            end

            return oldFunc2(self, num)
        end     
    end
end