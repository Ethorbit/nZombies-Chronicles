AddCSLuaFile()

ENT.Base = "nz_zombie_boss_tank_base"

DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Tank Randomized"
ENT.Category = "Brainz"
ENT.Author = "Berb"

function ENT:Models() 
     return {"models/enhanced_infected/hulk_"..math.random(3)..".mdl"}
end 

nzRound:AddBossType("Tank [Randomized]", "nz_zombie_boss_tank_random", {
    specialspawn = true,
    initfunc = function()
        --nzRound:SetNextBossRound(math.random(6,8)) -- Randomly spawn in rounds 6-8
        nzRound:SetNextBossRound(nzRound:GetNumber() + math.random(10, 12))

        -- We can't have boss round on dog round
        if (nzRound:GetNextSpecialRound() == nzRound:GetNextBossRound()) then 
            nzRound:SetNextBossRound(nzRound:GetNextBossRound() + 1)
        end
    end,
    spawnfunc = function(tank)
	 tank:SetHealth(tank:GetTankHealth())
	 tank:SetMaxHealth(tank:GetTankHealth())
    end,
    deathfunc = function(panzer, killer, dmginfo, hitgroup)
        nzRound:SetNextBossRound(nzRound:GetNumber() + math.random(3,5)) -- Delay further boss spawning by 3-5 rounds after its death
        --nzRound:SetNextBossRound(nzRound:GetNumber() + 6)
            
        if IsValid(attacker) and attacker:IsPlayer() and attacker:GetNotDowned() then
            attacker:GivePoints(500) -- Give killer 500 points if not downed
        end

        -- We can't have boss round on dog round
        if (nzRound:GetNextSpecialRound() == nzRound:GetNextBossRound()) then 
            nzRound:SetNextBossRound(nzRound:GetNextBossRound() + 1)
        end
    end
}) -- No onhit function, we don't give points on hit for this guy
