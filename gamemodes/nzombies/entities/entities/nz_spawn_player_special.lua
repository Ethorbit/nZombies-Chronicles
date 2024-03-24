ENT.Type = "anim"
ENT.Base = "base_entity"

AddCSLuaFile( )
ENT.PrintName = "nz_spawn_player_special"
ENT.NZOnlyVisibleInCreative = true

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "Link" )
end

function ENT:Initialize()
	self:SetModel( "models/player/odessa.mdl" )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:SetColor(Color(0, 255, 0))
	self:DrawShadow( false )
end

function ENT:IsSuitable()
	local tr = util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos(),
		filter = self,
		mins = Vector( -20, -20, 0 ),
		maxs = Vector( 20, 20, 70 ),
		ignoreworld = true,
		mask = MASK_NPCSOLID
	} )

	return not tr.Hit
end

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end
end

function ENT:Initialize()
	self:SetModel( "models/player/odessa.mdl" )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:SetColor(Color(255, 255, 255))
	self:DrawShadow( false )
end