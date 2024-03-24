
local function HandlePlayerDowned(ply, vel)
	if !ply:GetNotDowned() then
		ply.CalcIdeal = ACT_HL2MP_SWIM_REVOLVER
		
		local len = vel:Length2D()
		if ( len <= 1 ) then
			ply.CalcIdeal = ACT_HL2MP_SWIM_PISTOL
		end
		
		return ply.CalcIdeal, ply.CalcSeqOverride
	end
end
hook.Add("CalcMainActivity", "nzPlayerDownedAnims", HandlePlayerDowned)

hook.Add("PrePlayerDraw", "nzPlayerDownedPos", function(ply)
	if (ply:GetPos() == ply.FixedRevPos) then return end
	ply.FixedRevPos = ply:GetPos() - Vector(0, 0, 25)
	if !ply:GetNotDowned() then
		ply:SetPos(ply.FixedRevPos)
	end
end)

local function PlayerDownedParameters(ply, vel, seqspeed)
	if !ply:GetNotDowned() then
		local len = vel:Length2D()
		local movement = 0

		if ( len > 1 ) then
			movement = ( len / seqspeed )
		elseif math.Round(ply:GetCycle(), 1) != 0.7 then
			movement = 5
		end

		local rate = math.min( movement, 1 )
		
		ply:SetPoseParameter("move_x", -1)
		ply:SetPlaybackRate( movement )
		
		if !ply.NZDownedAnim then
			ply.oldViewOffsetHere = ply:GetViewOffset()
			ply:SetViewOffset(Vector(0, 0, 30))
			--ply:SetHull(Vector(-16,-16,0), Vector(16,16,72))
			ply.NZDownedAnim = true
		end

		--ply:SetNetworkOrigin(ply:GetPos() - Vector(0,0,20))
		--
		return true
	elseif ply.NZDownedAnim then
		-- if (isvector(ply.oldViewOffsetHere)) then
		ply:SetViewOffset(Vector(0, 0, 64))
		-- end

		--ply:SetPos(ply:GetPos() + Vector(0,0,25))
		ply:ResetHull()
		ply.NZDownedAnim = false
	end
end
hook.Add("UpdateAnimation", "nzPlayerDownedAnims", PlayerDownedParameters)

if CLIENT then
	local function RenderDownedPlayers(ply)
		if !ply:GetNotDowned() then
			ply:SetRenderOrigin(ply:GetPos() - Vector(0,0,50))
			local ang = ply:GetAngles()
			ply:SetRenderAngles(Angle(-30,ang[2],ang[3]))
			ply:InvalidateBoneCache()
			
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then wep:InvalidateBoneCache() end
		end
	end
	hook.Add("PrePlayerDraw", "nzPlayerDownedAnims", RenderDownedPlayers)
end