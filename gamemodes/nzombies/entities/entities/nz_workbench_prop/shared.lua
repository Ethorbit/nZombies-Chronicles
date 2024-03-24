AddCSLuaFile( )

ENT.Type = "anim"

ENT.PrintName		= "nz_workbench_prop"
ENT.Author			= "Ethorbit"
ENT.Purpose			= "A prop that can be picked up and used at Workbenches to craft weapons (if the weapon is set)."
ENT.Instructions	= ""
ENT.Editable = true

ENT.NZEntity = true

function ENT:SetupDataTables() -- Moved all configuration here, so they can be edited in context menu's right-click as well! :D
	local classes = {}
	for k,v in pairs(weapons.GetList()) do
		if !v.NZTotalBlacklist then
			if v.Category and v.Category != "" then
				classes[v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName] = v.ClassName
			else
				classes[v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName] = v.ClassName
			end
		end
	end

	-- TODO: add option 'For Workbench', and have it on by default. Some config creators will not use this for workbench purposes..
	-- TODO: add optional ID and make the gamemode fire pickup hooks for props and push the ID and weapon class along with it, one for picked up, dropped and all collected.
	self:NetworkVar( "String", 0, "BuildClass", {KeyName = "nz_scriptprop_buildclass", Edit = {type = "Combo", title = "Weapon this part makes", values = classes, order = -1}} )
	-- Invalidate based on Workbench buildclass
	self:NetworkVarNotify("BuildClass", function(ent, name, old, new)
		if #new == 0 then return end
		if #nzBenches:GetAll() > 1 and #nzBenches:GetByBuildClass(new) == 0 then
			ent:SetInvalid(true)
		else
			ent:SetInvalid(false)
		end

		if SERVER then
			nzParts:UpdateEntity(ent)
		end
	end)

	self:NetworkVar( "Bool", 0, "Invalid")
	self:NetworkVar( "Bool", 1, "Built")
    self:NetworkVarNotify("Built", function(ent, name, old, new)
        if new == true then 
            self:Disable()
        else 
            self:Enable()
        end 
    end)
    
    --self:SetBuildClass("")
end

function ENT:Initialize()
	self:Enable()
    self:SetBuilt(false)
	self.OriginalSpawnAngles = self:GetAngles()

	if SERVER then
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:DrawShadow(true)
		self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
	end

    -- for _,workbench in pairs(nzBenches:GetAll()) do
	-- 	if workbench.AddNewPart then
    --     	workbench:AddNewPart(self)
	-- 	end
    -- end
end

function ENT:UpdateTransmitState() -- Always transmit otherwise sometimes this entity will fail to render for players after they leave the PVS once
	return TRANSMIT_ALWAYS
end

function ENT:Enable() -- Appear and allow interaction again
	if self:GetBuilt() then return end -- We've been built
    self.bDisabled = false

	if SERVER then
		self:SetRenderMode(RENDERMODE_NORMAL)
		self:SetModelScale(1)
		self:DrawShadow(true)
	end

	self:StopRespawnTimer()
end

function ENT:Disable() -- When the entity will appear to no longer exist and disable interactivity
	self.bDisabled = true

	if SERVER then
		self:SetRenderMode(RENDERMODE_NONE)
		self:SetModelScale(0) -- Just incase, sometimes rendermode_none still shows for people
	end

	self:StartRespawnTimer()
end

function ENT:IsDisabled()
	return self.bDisabled
end

function ENT:Pickup() -- A player picked us up
	self:Disable()
end

function ENT:ResetPosition() -- Reset ourselves at a random part position
    if nzParts.Data and nzParts.Data[self:GetModel()] then
		local spawn_data = table.Random(nzParts.Data[self:GetModel()])
		if spawn_data then
			self:SetPos(spawn_data.pos)
			self:SetAngles(spawn_data.angles)
			self:Enable()
		end
	else
		print("[Buildables] Failed to respawn part because it is not in the parts data table!")
	end
end

function ENT:StartRespawnTimer(time) -- Force respawn/enable after this many seconds
	if !nzMapping.Settings.buildablesforcerespawn then return end -- Config creator does not want parts to respawn themselves

	-- Just in case someone's greifing or doesn't know what to do with the part
	local time = time or 720
	timer.Create("ForceResetPart" .. self:EntIndex(), time, 1, function()
		if (IsValid(self)) then
			self:Reset()
		end
	end)
end

function ENT:StopRespawnTimer() -- Cancel out the current force respawn timer
	timer.Destroy("ForceResetPart" .. self:EntIndex())
end

function ENT:Reset(pos) -- When this needs to respawn
	if SERVER then
		if !pos then
            self:ResetPosition()
		else 
			self:SetPos(pos)
			self:SetAngles(self.OriginalSpawnAngles)
		end
	end

	self.ValidWeapon = nil
	self:Enable()
end

function ENT:Use(activator) -- Player is picking this up
	if (self:IsDisabled() or self:GetInvalid()) then return end

	if (IsValid(activator) and activator:IsPlayer()) then
		activator:PickupPart(self)
	end
end

function ENT:GetWeapon() -- Get the weapon table of the Part's BuildClass
	if self.ValidWeapon then return self.ValidWeapon end
	self.ValidWeapon = weapons.Get(self:GetBuildClass())

	if !self.ValidWeapon and #nzBenches:GetAll() == 1 then
		self.ValidWeapon = nzBenches:GetAll()[1]:GetWeapon()
	end

	return self.ValidWeapon
end

function ENT:GetPartName()
	if !nzMapping.Settings.buildablesdisplayweppart then return "" end
	return (self:GetWeapon().PrintName or self:BuildClass()) .. " "
end

function ENT:GetNZTargetText() -- Text that appears when looking at this
	if self:GetInvalid() then
		if LocalPlayer():IsInCreative() then return "Invalid Part! - No Workbench has the buildclass" end
		return ""
	end

	if self:IsDisabled() or self:GetInvalid() then return "" end
	if LocalPlayer():IsInCreative() then return "A Part." end
	if LocalPlayer():IsSpectating() then return "" end
	if !LocalPlayer():GetNotDowned() then return "You cannot get this when down." end
	if LocalPlayer():HasPart(self) then return "You already have this." end
	if nzMapping.Settings.buildablesshare and LocalPlayer():HasMaxParts() then return "You cannot pickup any more parts." end
	if LocalPlayer():HasMaxParts() then return "(Too many parts) Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to swap with " .. self:GetPartName() .. "part." end
	return "Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to pickup " .. self:GetPartName() .. "part."
end

if CLIENT then
	function ENT:Draw()
		if self:GetInvalid() and !LocalPlayer():IsInCreative() then return end -- Invalid parts shall not be shown in-game

		if LocalPlayer():IsInCreative() then -- Give an effect so it's easy to know what a Part is
			self:DrawModel()
		return end

		if (!LocalPlayer():IsSpectating()) then
			self:DrawModel()
		return end

		local targ = LocalPlayer():GetObserverTarget()
		if (IsValid(targ) and targ:IsPlayer() and targ:Alive() and LocalPlayer():GetObserverMode() != OBS_MODE_ROAMING) then -- Only show if they are spectating somebody (Not in free roam where they can easily tell teammates where parts are)
			self:DrawModel()
		return end
	end
end

function ENT:OnRemove()
	for _,table in pairs(nzBenches:GetAll()) do
		if IsValid(table) and table.RemoveOldPart then 
            table:RemoveOldPart(self)
        end 
	end
end
