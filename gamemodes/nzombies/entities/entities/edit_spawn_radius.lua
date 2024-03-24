-- Made by Ethorbit for easily customizable zombie spawn radiuses that you can setup for each config

AddCSLuaFile()

ENT.Author 				= "Ethorbit"
ENT.Type 				= "anim"

ENT.Spawnable			= true
ENT.AdminOnly			= true
ENT.Editable 			= true

ENT.PrintName			= "Spawn Radius Editor"
ENT.Category			= "Editors"

ENT.NZOnlyVisibleInCreative = true
ENT.NZEntity = true

ENT.PreviewColor = Color(245, 122, 0)

AccessorFunc(ENT, "fNextPreviewStop", "NextPreviewStop", FORCE_NUMBER) -- If current time is before this, the radius preview will show.

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Radius", { KeyName = "nz_spawn_radius", Edit = { type = "Float", min = 0, max = 10000, order = 1 } });

	self:NetworkVar("Bool", 0, "HasMultiplayerRadius", { KeyName = "nz_spawn_radius_has_multiplayer", Edit = { category = "Multiplayer", title = "Multiplayer Has Different Radius?", type = "Boolean", order = 2 } });
	self:NetworkVar("Float", 1, "MultiplayerRadius", { KeyName = "nz_spawn_radius_multiplayer", Edit = { category = "Multiplayer", title = "Multiplayer Radius", type = "Float", min = 0, max = 10000, order = 3 } });

	if SERVER then
		self:SetRadius(2500)
		self:SetHasMultiplayerRadius(false)
		self:SetMultiplayerRadius(3000)
	end

	self:NetworkVarNotify("Radius", self.OnRadiusChanged)
end

function ENT:Initialize()
	if (SERVER) then
		self:SetModel( "models/maxofs2d/cube_tool.mdl" )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(ONOFF_USE)

		-- Let's only allow 1 for now (Why would you ever need more than that anyway?)
		for _,other_spawn_radius in pairs(ents.FindByClass(self:GetClass())) do
			if (other_spawn_radius != self) then
				other_spawn_radius:Remove()
			end
		end

		nzRound:UpdateSpawnRadius()
	end

	self:SetMaterial("squad/orangebox")
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetNextPreviewStop(0)

	if CLIENT then
		self:DeactivatePreview()
	end
end

function ENT:OnRadiusChanged()
	self:SetNextPreviewStop(CurTime() + 3)

	if SERVER then
		nzRound:UpdateSpawnRadius()
	end
end

if CLIENT then
	function ENT:ActivatePreview()
		self.bPreviewActivated = true
		self.hookAlias3D = "Radius_Spawner_Edit_Preview3D" .. self:EntIndex()
		self.hookAlias2D = "Radius_Spawner_Edit_Preview2D" .. self:EntIndex()

		hook.Add("PostDrawOpaqueRenderables", self.hookAlias3D, function()
			if IsValid(self) then
				self:Do3DRadiusPreview()
			end
		end)

		hook.Add("HUDPaint", self.hookAlias2D, function()
			if IsValid(self) then
				self:Do2DRadiusPreview()
			end
		end)
	end

	function ENT:DeactivatePreview()
		self.bPreviewActivated = false

		if self.hookAlias3D then
			hook.Remove("PostDrawOpaqueRenderables", self.hookAlias3D)
		end

		if self.hookAlias2D then
			hook.Remove("HUDPaint",  self.hookAlias2D)
		end
	end

	function ENT:Think()
		if !LocalPlayer():IsInCreative() then return end

		if (self:IsPreviewAllowed()) then
			if !self.bPreviewActivated then
				self:ActivatePreview()
			end
		elseif (self.bPreviewActivated) then
			self:DeactivatePreview()
		end
	end

	function ENT:IsPreviewAllowed()
		return CurTime() < self:GetNextPreviewStop() and ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE )
	end

	function ENT:IsUserInRadius()
		for _,ent in pairs(ents.FindInSphere(self:GetPos(), self:GetRadius())) do
			if ent == LocalPlayer() then
				return true
			end
		end
	end

	function ENT:Do3DRadiusPreview()
		if self:IsPreviewAllowed() then
			-- Visualize the radius:
			if (CurTime() < self:GetNextPreviewStop()) then
				render.DrawWireframeSphere(self:GetPos(), self:GetRadius(), 50, 50, self.PreviewColor, true)
				render.DrawWireframeSphere(self:GetPos(), self:GetRadius(), 50, 50, self.PreviewColor, false)
			end
		end
	end

	function ENT:Do2DRadiusPreview() -- Let them know whether or not they're inside the radius (in case the 3D preview is out of visible bounds)
		if self:IsPreviewAllowed() and self:IsUserInRadius() then
			local col = self.PreviewColor
			col.a = 10
			surface.SetDrawColor(col)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end
	end

	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end

	function ENT:OnRemove()
		self:DeactivatePreview()
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
