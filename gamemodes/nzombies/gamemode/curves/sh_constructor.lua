if SERVER then
	-- Main Tables
	nzCurves = nzCurves or AddNZModule("Curves")

	function nzCurves.GenerateHealthCurve(round)
		round = math.Clamp(round, -1, nzMapping.Settings.maxhealthround)

		local base = GetConVar("nz_difficulty_zombie_health_base"):GetFloat()
		local scale = GetConVar("nz_difficulty_zombie_health_scale"):GetFloat()
		return math.Round(base*math.pow(scale,round - 1))
	end

	function nzCurves.GenerateHellHoundHealth(round)
		local baseScale = GetConVar("nz_difficulty_zombie_health_scale"):GetFloat()
		local extraScale = math.Clamp(baseScale - 1.1, baseScale, math.huge)
		local extraBase = GetConVar("nz_difficulty_zombie_health_base"):GetFloat() - 75

		if extraScale <= 0 then
			extraScale = 1
		end

		local val = 800 + extraBase
		local specialCount = nzRound:GetSpecialCount() + 1

		-- This logic copies what's in BO1's Source Code
		if (specialCount == 1) then
			val = (200 + extraBase) * extraScale
		elseif (specialCount == 2) then
			val = (450 + extraBase) * extraScale
		elseif (specialCount == 3) then
			val = (650 + extraBase) * extraScale
		else
			val = (800 + extraBase) * extraScale
		end

		return val
	end

	function nzCurves.GenerateMaxZombies(round)
		if round == -1 then return math.huge end -- It's round infinity, so do infinite zombies.

		local base = GetConVar("nz_difficulty_zombie_amount_base"):GetInt()
		local scale = GetConVar("nz_difficulty_zombie_amount_scale"):GetFloat()
		local num = math.Round((base + (scale * (#player.GetAllPlaying() - 1))) * round)

		return math.Round((base + (scale * (#player.GetAllPlaying() - 1))) * round)
	end

	function nzCurves.GenerateSpeedTable(round)
		if !round then return {[50] = 100} end -- Default speed for any invalid round (Say, creative mode test zombies)
		local tbl = {}
		local range = 3 -- The range on either side of the tip (current round) of speeds in steps of "steps"
		local min = 40 -- Minimum speed (Round 1), 30 for cod experience
		local max = 200 -- Maximum speed, 200 for cod experience
		local custMax = nzMapping.Settings.maxzombiespeed
		if (isnumber(custMax) and custMax > 0) then
			max = custMax
		end

		local maxround = nzMapping.Settings.maxspeedround --27 -- The round at which the max speed has its tip
		local steps = ((max-min)/maxround) -- The different speed steps speed can exist in

		print("Generating round speeds with steps of "..steps.."...")
		for i = -range, range do
			local speed = (min - steps + steps*round) + (steps*i)
			if speed >= min and speed <= max then
				local chance = 100 - 10*math.abs(i)^2
				--print("Speed is "..speed..", with a chance of "..chance)
				tbl[speed] = chance
			elseif speed >= max then
				tbl[max] = 100
			end
		end
		return tbl
	end

	-- Moo's more CoDZ like speed increase.
	-- Commented instead of removed. I prefer NZ classic's movement, but this might serve a purpose one day I guess..
    --function nzCurves.GenerateCoDSpeedTable(round) -- Works best for enemies that obey the speed given to them by an animation rather than code.
	--	if not round then return {[50] = 100} end
	--	local tbl = {}
	--	local round = round
	--	local multiplier = nzMapping.Settings.speedmulti or 4 -- Actual value used in BO3 onward. If you want Pre-BO3 Speed increases, use 8 instead.
	--	local speed = 1 -- BO1 has this start at 1.

	--	for i = 1,round do -- I've been trolled once more by the "For" loop...
	--		speed = round * multiplier - multiplier -- Subbing by multiplier as well cause that seems to work.
	--	end

	--	if round == 1 then -- We always want walking zombies on the first round(Just like in the real games!).
	--		tbl[0] = 100
	--	else
	--		tbl[speed] = 100 -- This calculates the base number for the zombies of the round to use, further speed adjustments are done in the zombie luas themselves if they support it.
	--	end
	--	return tbl
	--end

	local startVar = GetConVar("nz_difficulty_barricade_points_cap_start")
	local perroundVar = GetConVar("nz_difficulty_barricade_points_cap_per_round")
	local maximumVar = GetConVar("nz_difficulty_barricade_points_cap_max")
	function nzCurves.GenerateBarricadePointCap(round)
		if startVar and maximumVar and perroundVar then
			local start = startVar:GetFloat()
			local maximum = maximumVar:GetFloat()
			local perround = perroundVar:GetFloat()

			if !round then return maximum end
			if round <= 1 then return start end

			return math.Clamp(start + (perround * (round - 1)), 0, maximum)
		end

		return 500
	end
end
