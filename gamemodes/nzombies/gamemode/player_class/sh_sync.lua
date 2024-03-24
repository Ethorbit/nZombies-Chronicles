local PLAYER = FindMetaTable("Player")

------------ Player Speeds ------------------
if SERVER then
    util.AddNetworkString("NZ_AddNewPlayerSpeed")
end

if CLIENT then
    net.Receive("NZ_AddNewPlayerSpeed", function()
        local is_walk = net.ReadBool()
        local alias = net.ReadString()
        local speed = net.ReadInt(15)

        if !alias or !speed then return end

        if is_walk then
            LocalPlayer():AddWalkSpeed(alias, speed)
        else
            LocalPlayer():AddRunSpeed(alias, speed)
        end
    end)
end

-----------------------------------------------------
------------ Nova Gas -------------------------------
if CLIENT then
    hook.Add("RenderScreenspaceEffects", "NZNovaGasRenderSpaceFX", function()
		if LocalPlayer().IsTouchingNovaGas and LocalPlayer():IsTouchingNovaGas() then
			DrawMotionBlur( 0.1, 0.8, 0.01 )
		end
	end)

    hook.Add("EntityEmitSound", "NZNovaGasFadeOutAudio", function(data)
        if LocalPlayer().IsTouchingNovaGas and LocalPlayer():IsTouchingNovaGas() then
            data.DSP = 30
        return true end
    end)
end
--------------------------------------------------------------