-- Recoded itemcarry from scratch by: Ethorbit
local part_mats = part_mats or {}
hook.Add("OnPartAdded", "NZHUDPartAdded", function(ply, part)
    if !IsValid(part) then return end
    part_mats[part] = nzDisplay.GetSpawnIcon(part:GetModel())
end)

hook.Add("OnPartRemoved", "NZHUDPartRemoved", function(ply, part)
    part_mats[part] = nil
end)

hook.Add("HUDPaint", "NZ.PartHUD", function()
    local ply = LocalPlayer():IsSpectating() and LocalPlayer():GetObserverTarget() or LocalPlayer()
    if IsValid(ply) then
        if ply:HasParts() then
            local num = 0
            for _,part in pairs(ply:GetParts()) do 
                --if part.GetBuilt and part:GetBuilt() then return end 
                
                num = num + 1
                if part_mats[part] then
                    surface.SetDrawColor(255, 255, 255)
                    surface.SetMaterial(part_mats[part])
                    surface.DrawTexturedRect((ScrW() - 310) - (90 * num), ScrH() - 90, 80, 80)
                end
            end
        end
    end
end)
