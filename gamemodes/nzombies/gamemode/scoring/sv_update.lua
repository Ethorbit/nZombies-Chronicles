function GM:OnZombieKilled(zombie, dmgInfo)
	local attacker = dmgInfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:IncrementTotalKills()
		hook.Call("XPFromZombie", nil, attacker, zombie)
	end
end

-- function GiveNuke() -- For testing point exploit with nuke
-- 	---Entity(1):ConCommand("+attack2")

-- 	--timer.Simple(0.3, function()
-- 		nzPowerUps:SpawnPowerUp(Entity(1):GetPos(), "nuke")
-- 	--end)
	
-- 	-- timer.Simple(1, function()
-- 	-- 	Entity(1):ConCommand("-attack2")
-- 	-- end)
-- end

hook.Add("PlayerRevived", "nzupdateReviveScore", function(ply, revivor)
	if IsValid(revivor) and revivor:IsPlayer() then
		revivor:IncrementTotalRevives()
		
		if ply != revivor then
			--revivor:GiveXP(Maxwell.XPAmountFromRevives)
			hook.Call("XPFromRevive", nil, revivor)
		end
	end
end )

hook.Add("PlayerDowned", "nzupdateDownedScore", function(ply)
	if IsValid(ply) and ply:IsPlayer() then
		ply:IncrementTotalDowns()
	end
end )
