AddCSLuaFile( )

ENT.Type = "anim"
 
ENT.PrintName		= "invis_wall"
ENT.Author			= "Zet0r"
ENT.Contact			= "youtube.com/Zet0r"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.NZEntity = true

function ENT:SetupDataTables()
	-- Min bound is for now just the position
	--self:NetworkVar("Vector", 0, "MinBound")
	self:NetworkVar("Vector", 0, "MaxBound")
end

function ENT:Initialize()
	--self:SetMoveType( MOVETYPE_NONE )
	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self:DrawShadow( false )
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	if self.SetRenderBounds then
		self:SetRenderBounds(Vector(0,0,0), self:GetMaxBound())
	end
	self:SetCustomCollisionCheck(true)

	--self:PhysicsInitBox(Vector(0,0,0), self:GetMaxBound())
	self:EnableCustomCollisions(true) -- By Ethorbit, I don't know how this happened but adding this, the set solid flag below and returning false in TestCollision finally fixed bullet collision
	self:SetSolidFlags(FSOLID_CUSTOMRAYTEST)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end
	
	--self:SetFilter(true, true)
end

local ignoreClasses = {
	"invis_wall", 
	"invis_wall_zombie",
	"wall_block",
	"wall_block_zombie"
}

function ENT:Use(Activator, Caller, UseType, Integer)
	local ent
	local tr = util.TraceLine({
		start = Activator:EyePos(),
		endpos = Activator:EyePos() + Activator:GetAimVector()*150,
		filter = function(ent2) if ent2 != Activator and !table.HasValue(ignoreClasses, ent2:GetClass()) then ent = ent2 end end,
		mask = MASK_PLAYERSOLID,
		ignoreworld = true,
	})

	if IsValid(ent) and (!isnumber(Activator.lastInvisUseTime) or IsValid(ent) and isnumber(Activator.lastInvisUseTime) and CurTime() > Activator.lastInvisUseTime)
	and ent:GetClass() != "invis_wall" 
	and ent:GetClass() != "invis_wall_zombie"
	and ent:GetClass() != "wall_block"
	and ent:GetClass() != "wall_block_zombie"
	and ent:GetClass() != "power_box" then
		if (ent:GetClass() == "easter_egg") then
			Activator.lastInvisUseTime = CurTime() + 1
			ent:Use(Activator, Caller, UseType, Integer)
			print("Force used Easter Egg")
		end
	end
end

--function ENT:Use(Activator, Caller, UseType, Integer)
	-- local ent
	-- local tr = util.TraceLine({
	-- 	start = Activator:EyePos(),
	-- 	endpos = Activator:EyePos() + Activator:GetAimVector()*150,
	-- 	filter = function(ent2) if ent2 != Activator and !table.HasValue(ignoreClasses, ent2:GetClass()) then ent = ent2 end end,
	-- 	mask = MASK_PLAYERSOLID,
	-- 	ignoreworld = true,
	-- })

	-- if IsValid(ent) and (!isnumber(Activator.lastInvisUseTime) or IsValid(ent) and isnumber(Activator.lastInvisUseTime) and CurTime() > Activator.lastInvisUseTime)
	-- and ent:GetClass() != "invis_wall" 
	-- and ent:GetClass() != "invis_wall_zombie"
	-- and ent:GetClass() != "wall_block"
	-- and ent:GetClass() != "wall_block_zombie"
	-- and ent:GetClass() != "power_box" then
	-- 	if (ent:GetClass() == "perk_machine" and nzPerks) then
	-- 		local data = nzPerks:Get(ent:GetPerkID())
	-- 		if (data.name == "Pack-a-Punch") then return end
	-- 	end

	-- 	Activator.lastInvisUseTime = CurTime() + 1
	-- 	ent:Use(Activator, Caller, UseType, Integer)
	-- end
--end

local mat = Material("color")
local white = Color(255,150,0,30)

if CLIENT then

	if not ConVarExists("nz_creative_preview") then CreateClientConVar("nz_creative_preview", "0") end

	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			--self:SetNoDraw(false)

			cam.Start3D()
				render.SetMaterial(mat)
				render.DrawBox(self:GetPos(), self:GetAngles(), Vector(0,0,0), self:GetMaxBound(), white, true)
			cam.End3D()
		end
	end
--else
	--function ENT:Think()
		-- if (nzRound:InState(ROUND_CREATE)) then
		-- 	if (!self.rendering) then
		-- 		self:SetNoDraw(false)
		-- 		self.rendering = true
		-- 	end
		-- elseif (self.rendering) then
		-- 	self.rendering = false
		-- 	self:SetNoDraw(true)
		-- end
	--end
end

function ENT:TestCollision(start, delta, hulltrace, bounds, mask)
	return false
end

hook.Add("PhysgunPickup", "nzInvisWallNotPickup", function(ply, wall)
	if wall:GetClass() == "invis_wall_block" or wall:GetClass() == "invis_wall" or wall:GetClass() == "invis_damage_wall" then return false end
end)
