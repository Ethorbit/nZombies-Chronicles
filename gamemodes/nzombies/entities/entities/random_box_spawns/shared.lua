AddCSLuaFile( )

ENT.Type = "anim"
 
ENT.PrintName		= "random_box_spawns"
ENT.Author			= "Zet0r"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.NZEntity = true

function ENT:Initialize()
	self:SetModel( "models/nzprops/mysterybox_pile.mdl" )
	self:SetColor( Color(255, 255, 255) )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)		
	end
	
	--self:SetNotSolid(true)
	--self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	--self:DrawShadow( false )
end

-- function ENT:Think()
	
-- end

-- Mysterybox moving by explosive bug fixed by Ethorbit:
function ENT:PhysicsCollide(colData, collider)
	self:SetMoveType( MOVETYPE_NONE )
end

if CLIENT then
	
end