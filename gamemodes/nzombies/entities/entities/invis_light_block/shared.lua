-- Created by Ethorbit to make lighting entire regions of a map
-- effortless and allows more integration of the Spookifier

AddCSLuaFile( )

ENT.Type = "anim"
 
ENT.PrintName		= "invis_light_block"
ENT.Author			= "Zet0r (Modifed by Ethorbit)"
ENT.Contact			= "youtube.com/Zet0r"
ENT.Purpose			= "Effortlessly light an entire room"
ENT.Instructions	= ""

ENT.NZEntity = true

function ENT:SetupDataTables()
	-- Min bound is for now just the position
	--self:NetworkVar("Vector", 0, "MinBound")
	self:NetworkVar("Vector", 0, "MaxBound")
end

function ENT:Initialize()
	--self:SetMoveType( MOVETYPE_NONE )
	self:DrawShadow( false )
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	if self.SetRenderBounds then
		self:SetRenderBounds(Vector(0,0,0), self:GetMaxBound())
	end
	self:SetCustomCollisionCheck(true)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetSolid(SOLID_NONE)

	if SERVER then -- Make the light
		local lightpos = (self:GetPos() + self:GetMaxBound() / 2) -- Center of box
		local brightness = 500
		local light = ents.Create("light")
		light:SetPos(lightpos)
		light:SetKeyValue("_light", "255 255 255 1000")
		light:Fire("TurnOn")
		print(light)

		-- barrel:SetModel("models/props_junk/cinderblock01a.mdl")
		-- barrel:SetPos()
		print(self:GetMaxBound())
	end

	--self:SetFilter(true, true)
end

function ENT:OnRemove()
	if IsValid(self.lightent) then
		self.lightent:Remove()
	end
end

local mat = Material("color")
local white = Color(255, 255, 255, 5)

if CLIENT then

	if not ConVarExists("nz_creative_preview") then CreateClientConVar("nz_creative_preview", "0") end

	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			cam.Start3D()
				render.SetMaterial(mat)
				render.DrawBox(self:GetPos(), self:GetAngles(), Vector(0,0,0), self:GetMaxBound(), white, true)
			cam.End3D()
		end
	end
end

-- Causes collisions to completely disappear, not just traces :(
--[[function ENT:TestCollision(start, delta, hulltrace, bounds)
	return nil -- Traces pass through it!
end]]

hook.Add("PhysgunPickup", "nzInvisWallNotPickup", function(ply, wall)
	if wall:GetClass() == "invis_light_block" then return false end
end)
