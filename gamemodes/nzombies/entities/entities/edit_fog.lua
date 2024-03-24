
AddCSLuaFile()
DEFINE_BASECLASS( "base_edit" )

ENT.Spawnable			= true
ENT.AdminOnly			= true

ENT.PrintName			= "Fog Editor"
ENT.Category			= "Editors"

ENT.NZOnlyVisibleInCreative = true

ENT.NZEntity = true

function ENT:Initialize()

	BaseClass.Initialize( self )

	self:SetMaterial( "gmod/edit_fog" )
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	
	-- There can only be one!
	if SERVER and IsValid(ents.FindByClass("edit_fog")[1]) and ents.FindByClass("edit_fog")[1] != self then ents.FindByClass("edit_fog")[1]:Remove() end

	-- if ( SERVER ) then
	-- 	nzFog.FadeFog(false)
	-- 	--nzRound:EnableSpecialFog( false )
	-- end
	
end

function ENT:SetupDataTables()

	self:NetworkVar( "Float",	0, "FogStart", { KeyName = "fogstart", Edit = { type = "Float", min = 0, max = 10000, order = 1 } }  );
	self:NetworkVar( "Float",	1, "FogEnd", { KeyName = "fogend", Edit = { type = "Float", min = 0, max = 10000, order = 2 } }  );
	self:NetworkVar( "Float",	2, "FarZ", { KeyName = "farz", Edit = { type = "Float", min = 0, max = 10000, order = 2 } }  );
	self:NetworkVar( "Float",	3, "Density", { KeyName = "fogmaxdensity", Edit = { type = "Float", min = 0, max = 1, order = 3 } }  );
	self:NetworkVar( "Vector",	0, "FogColor", { KeyName = "fogcolor", Edit = { type = "VectorColor", order = 3 } }  );
	self:NetworkVar( "Bool", 0, "FarZUnsupportedColors", { KeyName = "farzunsupportedcolors", Edit = { type = "Boolean", order = 4 } } );
	
	--
	-- TODO: Should skybox fog be edited seperately?
	--

	if ( SERVER ) then
		-- defaults
		self:SetFogStart( 0.0 )
		self:SetFogEnd( 10000 )
		self:SetDensity( 0.9 )
		self:SetFogColor( Vector( 0.6, 0.7, 0.8 ) )
        self:SetFarZUnsupportedColors(false)
		self:SetFarZ(100000)
	end

end

--
-- This edits something global - so always network - even when not in PVS
--
function ENT:UpdateTransmitState()

	return TRANSMIT_ALWAYS
end

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end
end

