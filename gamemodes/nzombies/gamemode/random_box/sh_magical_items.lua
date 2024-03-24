game.AddParticles("particles/magic_particles.pcf")
PrecacheParticleSystem("magic_smoke")

if (SERVER) then
    util.AddNetworkString("ShowMagicalHalo")
    util.AddNetworkString("RemoveMagicalHalo")
else
    --local magicals = {}
    -- hook.Add("PreDrawHalos", "MagicalHalos", function()
    --     halo.Add(magicals, Color(0, 104, 139), 20, 20, 5, true)
    -- end)

    net.Receive("ShowMagicalHalo", function()
        local magicalEnt = net.ReadEntity()
        if IsValid(magicalEnt) then
            magicalEnt:EmitSound("chron/nz/effects/magical_loop.wav", 80, 100, 0.5)
            --table.insert(magicals, magicalEnt)
            ParticleEffectAttach("magic_smoke", PATTACH_POINT_FOLLOW, magicalEnt, 4)
        end
    end)

    net.Receive("RemoveMagicalHalo", function()
        local magicalEnt = net.ReadEntity()
        if IsValid(magicalEnt) then 
            magicalEnt:StopParticles() 
            magicalEnt:StopSound("chron/nz/effects/magical_loop.wav")
        end

        --table.RemoveByValue(magicals, magicalEnt)
    end)
end