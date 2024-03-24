-- Actual Commands
concommand.Add("nz_forceround", function(ply, cmd, args, argStr)
	if !IsValid(ply) or ply:IsNZAdmin() then
		local round = args[1] and tonumber(args[1]) or nil
		local nokill = args[2] and tobool(args[2]) or false

		if !nokill then
			nzPowerUps:Nuke(nil, true) -- Nuke kills them all, no points, no position delay
		end

		if round then
			nzRound:SetNumber( round - 1 )
			local specint = GetConVar("nz_round_special_interval"):GetInt() or 6
			--nzRound:SetNextSpecialRound( math.ceil(round/specint)*specint)
		end
		nzRound:Prepare()
	end
end)

concommand.Add("nz_doground", function(ply) -- Dog rounds are now a bit random to match BO1, so you use this command to fast travel to the next dog round
	if !IsValid(ply) or ply:IsNZAdmin() then
		RunConsoleCommand("nz_forceround", nzRound:GetNextSpecialRound())
	end
end)

concommand.Add("nz_bossround", function(ply) -- Boss rounds are different, and match COD better
	if !IsValid(ply) or ply:IsNZAdmin() then
		RunConsoleCommand("nz_forceround", nzRound:GetNextBossRound())
	end
end)

concommand.Add("nz_restartround", function(ply) -- With all these special and boss parameters, a command to restart the round is more helpful than nz_forceround <current round>
	if !IsValid(ply) or ply:IsNZAdmin() then
		if nzRound:IsSpecial() then
			nzRound:SetNextSpecialRound(nzRound:GetNumber())
			nzRound:SetSpecialCount(math.Clamp(nzRound:GetSpecialCount() - 1, 0, math.huge))
		end

		if nzRound:IsBossRound() then
			nzRound:SetNextBossRound(nzRound:GetNumber())
		end

		RunConsoleCommand("nz_forceround", nzRound:GetNumber())
	end
end)

concommand.Add("nz_giveallperks", function(ply) -- You probably can't get more than 8, in fact this command was made just to playtest that limit.
	if ply:IsNZAdmin() then
		for id,perk in RandomPairs(nzPerks.Data) do
			if !perk.specialmachine then
				ply:GivePerk(id)
			end
		end
	end
end)

concommand.Add("nz_reloadconfig", function(ply) -- Yeah IDK what to say, I use a custom addon for loading configs at runtime so nobody can make use of this but me..
	if !IsValid(ply) or ply:IsSuperAdmin() then
		LoadConfig()
	end
end)

-- Quick reload for dedicated severs
-- concommand.Add("nz_qr", function(ply, cmd, args, argStr)
-- 	-- if !IsValid(ply) or ply:IsSuperAdmin() then
-- 	-- 	RunConsoleCommand("changelevel", game.GetMap())
-- 	-- end
-- end)

-- concommand.Add( "nz_print_weps", function()
-- 	for k,v in pairs( weapons.GetList() ) do
-- 		print( v.ClassName )
-- 	end
-- end)

-- concommand.Add("nz_door_id", function()
-- 	local tr = util.TraceLine( util.GetPlayerTrace( player.GetByID(1) ) )
-- 	if IsValid( tr.Entity ) then print( tr.Entity:doorIndex() ) end
-- end)

-- concommand.Add("printeyeentityinfo", function(ply, cmd, args, argstr)
-- 	if !ply:IsSuperAdmin() then return end
-- 	local ent = ply:GetEyeTrace().Entity
-- 	if IsValid(ent) then
-- 		local pos = ent:GetPos()
-- 		local ang = ent:GetAngles()
-- 		print("{pos = Vector("..math.Round(pos.x)..", "..math.Round(pos.y)..", "..math.Round(pos.z).."), ang = Angle("..math.Round(ang[1])..", "..math.Round(ang[2])..", "..math.Round(ang[3])..")}")
-- 	end
-- end)
