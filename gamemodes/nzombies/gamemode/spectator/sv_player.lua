nzSpectate = nzSpectate or {}

--Get the meta Table
local plyMeta = FindMetaTable( "Player" )
--accessors
AccessorFunc( plyMeta, "iSpectatingID", "SpectatingID", FORCE_NUMBER )
AccessorFunc( plyMeta, "iSpectatingType", "SpectatingType", FORCE_NUMBER )

function plyMeta:SetSpectator()
	if self:Alive() then
		self:KillSilent()
	end
	self:SetTeam( TEAM_SPECTATOR )
	self:SetSpectatingType( OBS_MODE_CHASE )
	self:Spectate(OBS_MODE_CHASE)
	self:SetSpectatingID( 1 )
end

function plyMeta:SpectateClosestEntity() -- Spectate the closest entity to the spectator, created by Ethorbit
	local closestEnt = nzMisc:GetClosestEntityToPosition(self:GetPos(), function(ent)
		return ent != self and ent:GetParent() != self and ent:IsInWorld() and (!ent:IsPlayer() or ent:Team() == TEAM_PLAYERS)
	end)

	self:SpectateEntity(closestEnt)
end
