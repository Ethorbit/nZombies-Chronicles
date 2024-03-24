AddCSLuaFile()

ENT.Type			= "anim"

ENT.PrintName		= "nz_teleporter"
ENT.Author			= "Laby & Ethorbit"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Editable = true
ENT.NZEntity = true

ENT.WireMat = Material( "cable/cable" ) -- The wire texture that appears in Creative Mode for seeing what's linked
ENT.LockedPlayers = {} -- Players locked by us, travelling to their destination
ENT.TeleportingPlayers = {} -- Players we are teleporting

ENT.GifTextures = { -- Give it all the same order as in sh_tools_teleporter
	[1] = {mat = "nzr/tp/codtele", title = "Der Riese"},
	[2] = {mat = "nzr/tp/coldwartp", title = "Cold War"},
	[3] = {mat = "nzr/tp/bo3tp", title = "Black Ops 3"},
	[4] = {mat = "nzr/tp/soe", title = "Shadows of Evil"},
	[5] = {mat = "nzr/tp/originstp", title = "Origins (Black Ops 3)"}
}

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "Flag", {KeyName = "TeleporterFlag", Edit = {title = "Flag", order = -1, type = "String"}} )
	self:NetworkVar( "String", 1, "Destination", {KeyName = "TeleporterDestination", Edit = {title = "Destination", order = 1, type = "String"}} )
	self:NetworkVar( "String", 2, "Door", {KeyName = "TeleporterDoorFlag", Edit = {category = "Door", title = "Door", order = 11, type = "String"}} )
	self:NetworkVar( "String", 3, "Trap", {KeyName = "TeleporterTrap", Edit = {category = "Trap", title = "Trap", order = 12, type = "String"}} )
	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Bool", 1, "BeingUsed")
	self:NetworkVar("Bool", 2, "OnCooldown")
	self:NetworkVar( "Bool", 5, "ModelVisible", {KeyName = "TeleporterModelVisible", Edit = {category = "Model", title = "Visible?", order = 9, type = "Boolean"}} )
	self:NetworkVar( "Bool", 6, "ModelCollisions", {KeyName = "TeleporterModelCollisions", Edit = {category = "Model", title = "Has collisions?", order = 10, type = "Boolean"}} )
	self:NetworkVar( "Bool", 7, "Useable", {KeyName = "TeleporterUseable", Edit = {title = "Useable?", order = 11, type = "Boolean"}} )
	self:NetworkVar( "Bool", 8, "RequiresDoor", {KeyName = "TeleporterRequiresDoor", Edit = {category = "Door", title = "Requires Door?", order = 12, type = "Boolean"}} )
	self:NetworkVar( "Bool", 9, "ActivatesTrap", {KeyName = "TeleporterActivatesTrap", Edit = {category = "Trap", title = "Activates Trap?", order = 13, type = "Boolean"}} )
	self:NetworkVar( "Int", 0, "Price", {KeyName = "TeleporterPrice", Edit = {title = "Price", order = 3, type = "Int", min = 0, max = 999999}} )
	self:NetworkVar("Int", 3, "ModelType")
	self:NetworkVar( "Float", 4, "TeleporterTime", {KeyName = "TeleporterTime", Edit = {title = "Teleport Time", order = 5, type = "Float", min = 0, max = 10000}} )
	self:NetworkVar( "Int", 6, "CooldownTime", {KeyName = "TeleporterCooldown", Edit = {title = "Cooldown", order = 6, type = "Int", min = 0, max = 10000}} )
	self:NetworkVar("Vector", 0, "DestPos")

	local gif_combo = {}
	for k,v in pairs(self.GifTextures) do
		gif_combo[v.title] = k
	end

	self:NetworkVar( "Int", 6, "GifType", {KeyName = "TeleporterGifType", Edit = {title = "Overlay", order = 4, type = "Combo", values = gif_combo}} )
	self:NetworkVar( "Bool", 3, "TPBack", {KeyName = "TeleporterTPBack", Edit = {title = "Teleport Back?", order = 7, type = "Boolean"}} )
	self:NetworkVar( "Int", 5, "TPBackDelay", {KeyName = "TeleporterTPBackDelay", Edit = {title = "Time to Teleport Back", order = 8, type = "Int", min = 0, max = 1000}} )
	self:NetworkVar("Bool", 4, "Transitioning")

	if SERVER then
		self:SetFlag("0")
		self:SetDestination("1")
		self:SetDoor("0")
		self:SetTrap("0")
		self:SetRequiresDoor(false)
		self:SetPrice(1500)
		self:SetGifType(1)
		self:SetTPBack(false)
		self:SetTPBackDelay(20)
		self:SetTeleporterTime(2.5)
		self:SetCooldownTime(20)
		self:SetModelType(1)
		self:SetModelCollisions(true)
		self:SetModelVisible(true)
		self:SetUseable(true)
	end

	self:NetworkVarNotify("ModelCollisions", function(ent, name, oldVal, newVal)
		self:EnableModelCollisions(newVal)
	end)
end

function ENT:EnableModelCollisions(bool)
	--if CLIENT then return end

	if bool then
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	else
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end

function ENT:Reset()
	timer.Destroy("NZRTeleporterInitialize" .. self:EntIndex())
	timer.Destroy("NZRTeleporterDisableCooldown" .. self:EntIndex())
	timer.Destroy("NZRTeleporterTPBack" .. self:EntIndex())
	timer.Destroy("NZRTeleporterTPBackLock" .. self:EntIndex())

	self.TeleportingPlayers = {}

	for _,ply in pairs(self.LockedPlayers) do
		if IsValid(ply) then
			self:UnlockPlayer(ply)
		end
	end

	self:SetBeingUsed(false)
	self:SetOnCooldown(false)
	self:SetTransitioning(false)
end

function ENT:Initialize()
	if SERVER then
		self:DrawShadow( false )
		self:SetUseType( SIMPLE_USE )
		self:SetBeingUsed(false)
		self:SetOnCooldown(false)
		self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
	end

	hook.Add("OnRoundEnd", "DisableTeleportationsInProgress", function()
		for _,v in pairs(ents.FindByClass("nz_teleporter")) do
			v:Reset()
		end
	end)

	hook.Add("ElectricityOn", "TurnTeleporterOnWithPower", function()
		for _,v in pairs(ents.FindByClass("nz_teleporter")) do
			v:SetBeingUsed(false)
			v:SetOnCooldown(false)
		end
	end)

	-- Teleporter Overlay
	hook.Add("RenderScreenspaceEffects", "TeleporterOverlayImages", function()
		if LocalPlayer().GetTeleporterEntity then
			for _,v in pairs(ents.FindByClass("nz_teleporter")) do
				if (v == LocalPlayer():GetTeleporterEntity()) then
					DrawMaterialOverlay(v:GetGif(), 0.03)
				end
			end
		end
	end)

	hook.Add("PlayerDeath", "TeleporterUnlockDeadPlayers", function(ply)
		for _,v in pairs(ents.FindByClass("nz_teleporter")) do
			local isTping = table.HasValue(v.TeleportingPlayers, ply)
			local isLocked = table.HasValue(v.LockedPlayers, ply)

			if isTping then
				v:RemoveTeleportingPlayer(ply)
			end

			if isLocked  then
				v:UnlockPlayer(ply)
			end

			if isLocked or isTping then
				print("Player died, no longer locked by Teleporter")
			end
		end
	end)

	-- This is way better than ply:GodEnable(true) as that allows invincibility with players downing themselves mid TP while
	-- this works exactly as intended
	hook.Add("PlayerShouldTakeDamage", "TeleporterPreventDownOrDeath", function(ply)
		if ply.TeleportNextAllowedDamage and CurTime() < ply.TeleportNextAllowedDamage then
			return false
		end

		-- While the below works perfectly fine, it could under the right lua error conditions, allow the player to have invincibility
		-- for the rest of the game :|  (This is just speculation, but I'm being safe about this because this hook literally prevents damage)
		--if IsValid(ply) and IsValid(ply:GetTeleporterEntity()) then return false end
	end)
end

function ENT:UpdateTransmitState() -- Always transmit to avoid clientside entity awareness issues
	return TRANSMIT_ALWAYS
end

function ENT:IsLinkedDoorOpen() -- Checks if the assigned Door flag is opened
	if self:GetRequiresDoor() then
		return nzDoors:IsLinkOpened(self:GetDoor())
	end

	return true
end

function ENT:GetDestinations()
	local result = {}

	for _, ent in pairs(ents.FindByClass("nz_teleporter")) do
		if (ent:GetDestination() == self:GetFlag()) then
			result[#result + 1] = ent
		end
	end

	return result
end

function ENT:GetDestinationsUnlocked()
	local result = {}

	if self:IsLinkedDoorOpen() then
		for _,dest in pairs(self:GetDestinations()) do
			if dest:IsLinkedDoorOpen() then
				result[#result + 1] = dest
			end
		end
	end

	return result
end

function ENT:LockPlayer(ply) -- Player stood in the Teleporter long enough, now they're locked in until they arrive at their destination.
	if ply:Team() == TEAM_SPECTATOR then return end
	ply:SetTargetPriority(TARGET_PRIORITY_NONE)

	if SERVER then
		if ply.SetTeleporterEntity then
			ply:SetTeleporterEntity(self)
		end

		ply:Lock()
		ply:SetNoDraw(true)
		ply:DrawWorldModel(false)
	end

	ply:SetRenderMode(RENDERMODE_NONE)
	self.LockedPlayers[#self.LockedPlayers + 1] = ply
end

function ENT:UnlockPlayer(ply)
	ply:SetDefaultTargetPriority()

	if SERVER then
		if ply.SetTeleporterEntity then
			ply:SetTeleporterEntity(nil)
		end

		ply:UnLock()
		ply:SetNoDraw(false)
		ply:DrawWorldModel(true)
	end

	ply:SetRenderMode(RENDERMODE_NORMAL)
	table.RemoveByValue(self.LockedPlayers, ply)

	ply:StopSound("nzr/teleport.mp3")
end

function ENT:TurnOn()
	self:SetActive(true)
	self:Update()
end

function ENT:TurnOff()
	self:SetActive(false)
	self:Update()
end


function ENT:Update()
	self:SetModel("models/nz_der_riese_waw/zombie_teleporter_pad.mdl")
	self:SetModelType(1)
		--if self:GetModelType() == 1 then
		--if self:IsOn() then
			--self:SetModel(FIVEON)
			--else
			--self:SetModel(FIVEOFF)
			--end
		--else
	--if self:IsOn() then
			--self:SetModel(KINOON)
			--else
			--self:SetModel(KINOOFF)
			--end
		--end
end


function ENT:IsOn()
	return self:GetActive()
end

function ENT:GetGif()
	return self.GifTextures[self:GetGifType()] and self.GifTextures[self:GetGifType()].mat or "nzr/tp/codtele"
end

function ENT:SetPlayerPos(ply, pos)
	if ply:Team() == TEAM_SPECTATOR then return end
	ply:SetPos(pos)
	ply:SetVelocity(-ply:GetVelocity()) -- Sometimes they fling away when they are TP'd, so just make them have no speed
end

function ENT:EnableDefenses(bool) -- Enable/Disable traps that are tied to us
	if !self:GetActivatesTrap() then return end

	for _,ent in pairs(ents.GetAll()) do
		if ent.Trap and ent.Activation and ent.GetNZName and ent:GetNZName() == self:GetTrap() then
			if bool then
				ent:Activation(nil, ent:GetDuration(), ent:GetCooldown(), true)
			else
				ent:Deactivation(true)
			end
		end
	end
end

function ENT:AddTeleportingPlayer(ply)
	if !IsValid(ply) then return end
	self.TeleportingPlayers[#self.TeleportingPlayers + 1] = ply
end

function ENT:RemoveTeleportingPlayer(ply)
	if !IsValid(ply) then return end
	table.RemoveByValue(self.TeleportingPlayers, ply)
end

function ENT:GetTeleportingPlayers()
	return self.TeleportingPlayers
end

function ENT:Teleport() -- Start the teleportation procedure
	self.TeleportingPlayers = {}
	for k, v in pairs ( ents.FindInSphere( self:GetPos(), 90 ) ) do
		if IsValid(v) and v:IsPlayer() and (!v:IsSpectating() or v:IsInCreative()) and v:Alive() then
			self:AddTeleportingPlayer(v)
		end
	end

	local anyPlys = #self.TeleportingPlayers > 0

	self:SetTransitioning(true)

	local rand = util.SharedRandom("TeleporterDest" .. self:EntIndex(), 1, #self:GetDestinations())
	local tp_destination = self:GetDestinations()[rand]

	------ We COULD just pick the first teleporter that either isn't
	------ tied to a door or is tied to a door that's open, but it's
	------ probably better to just not work and let the HUD text to its job
	------ at alerting the user that they fucked up the configuration
	-- if !IsValid(tp_destination) then
	-- 	for _,v in pairs(ents.FindByClass("nz_teleporter")) do
	-- 		if v != self then
	-- 			tp_destination = v
	-- 			break
	-- 		end
	-- 	end
	-- end

	if !IsValid(tp_destination) then return end

	-- Lock any players on us in, they are being sent to their destination
	for _,ply in pairs(self:GetTeleportingPlayers()) do
		self:LockPlayer(ply)
		ply.TeleportNextAllowedDamage = CurTime() + 4
		ply:SendLua([[surface.PlaySound("nzr/teleport.mp3")]])
	end

	self:EnableDefenses(false)

	local effectData = EffectData()
	effectData:SetStart( self:GetPos() + Vector(0, 0, 1000) )
	effectData:SetOrigin( self:GetPos() )
	effectData:SetMagnitude( 1 )
	util.Effect("lightning_strike", effectData)

	timer.Create("NZRTeleporterInitialize" .. self:EntIndex(), 4, 1, function() -- Time until the locked players are actually teleported
		if IsValid(self) and IsValid(tp_destination) then
			self:SetTransitioning(false)

			-- Send players to the destination and then unlock them so they can move again
			for _,ply in pairs(self:GetTeleportingPlayers()) do
				if IsValid(ply) then
					self:SetPlayerPos(ply, tp_destination:GetPos() + Vector(0, 0, 21))
					self:UnlockPlayer(ply)
				end
			end

			local effectData = EffectData()
			effectData:SetStart( tp_destination:GetPos() + Vector(0, 0, 1000) )
			effectData:SetOrigin( tp_destination:GetPos() )
			effectData:SetMagnitude( 1 )
			util.Effect("lightning_strike", effectData)

			self:SetOnCooldown(true)

			for _,dest in pairs(self:GetDestinations()) do
				dest:SetOnCooldown(true)
			end

			-- We and our destinations are on cooldown, wait the cooldown time and set that to false

			timer.Create("NZRTeleporterDisableCooldown" .. self:EntIndex(), (self:GetCooldownTime() + (self:GetTPBack() and self:GetTPBackDelay() or 0)), 1, function()
				if IsValid(self) then
					self:SetOnCooldown(false)

					if IsValid(tp_destination) then
						tp_destination:SetOnCooldown(false)
					end
				end
			end)

			-- If there's no teleporting back then we're done and can unregister everything as being Used
			if !anyPlys or !self:GetTPBack() then
				self:SetBeingUsed(false)

				for _,dest in pairs(self:GetDestinations()) do
					dest:SetBeingUsed(false)
				end
			end

			-- Send the player back
			if (anyPlys and self:GetTPBack()) then
				-- Lightning effects
				timer.Simple(self:GetTPBackDelay() - 1, function()
					if IsValid(self) then
						local effectData = EffectData()
						effectData:SetOrigin( self:GetPos() + Vector(0, 0, 100) )
						effectData:SetMagnitude( 2 )
						effectData:SetEntity(nil)
						util.Effect("lightning_prespawn", effectData)

						for _,ply in pairs(self:GetTeleportingPlayers()) do
							if IsValid(ply) and ply:Team() != TEAM_SPECTATOR then
								local effectData = EffectData()
								effectData:SetOrigin(ply:GetPos() + Vector(0, 0, 100))
								effectData:SetMagnitude( 2 )
								effectData:SetEntity(nil)
								util.Effect("lightning_prespawn", effectData)
							end
						end
					end
				end)

				-- Lock them in
				timer.Create("NZRTeleporterTPBackLock" .. self:EntIndex(), self:GetTPBackDelay(), 1, function()
					if IsValid(self) then
						self:SetTransitioning(true)

						for _,ply in pairs(self:GetTeleportingPlayers()) do
							if IsValid(ply) and ply:Team() != TEAM_SPECTATOR then
								ply:SendLua([[surface.PlaySound("nzr/teleport.mp3")]])
								self:LockPlayer(ply)
							end
						end
					end
				end)

				self:EnableDefenses(false)

				-- Send them back to the destination
				timer.Create("NZRTeleporterTPBack" .. self:EntIndex(), self:GetTPBackDelay() + 3, 1, function()
					if IsValid(self) then
						for _,ply in pairs(self:GetTeleportingPlayers()) do
							if IsValid(ply) then
								if ply:Team() != TEAM_SPECTATOR then
									local effectData = EffectData()
									effectData:SetStart( ply:GetPos() + Vector(0, 0, 1000) )
									effectData:SetOrigin( ply:GetPos() )
									effectData:SetMagnitude( 1 )
									util.Effect("lightning_strike", effectData)
								end

								self:SetPlayerPos(ply, self:GetPos() +  Vector(0, 0, 21))
								self:UnlockPlayer(ply)
							end
						end

						self:SetTransitioning(false)

						-- NOW we're done
						self:SetBeingUsed(false)

						for _,dest in pairs(self:GetDestinations()) do
							dest:SetBeingUsed(false)
						end
					end
				end)
			end
		end
	end)
end

function ENT:Use(activator, caller)
	if !self:GetUseable() then return end
	if !activator:IsInCreative() then
		if self:GetBeingUsed() then return end
		if !activator:GetNotDowned() or #self:GetDestinationsUnlocked() <= 0 then return end
	end

	if (IsValid(activator) and (activator:IsPlayer() and (nzElec:IsOn() or activator:IsInCreative()))) then
		local price = self:GetPrice()
		if (activator:IsInCreative() or (activator:GetPoints() >= price and !self:GetOnCooldown())) then
			self:SetBeingUsed(true)
			self:EnableDefenses(true)

			for _,dest in pairs(self:GetDestinations()) do
				dest:SetBeingUsed(true)
			end

			timer.Simple(self:GetTeleporterTime() - 1, function()
				if IsValid(self) then
					local effectData = EffectData()
					effectData:SetOrigin( self:GetPos()+ Vector(0, 0, 100) )
					effectData:SetMagnitude( 2 )
					effectData:SetEntity(nil)
					util.Effect("lightning_prespawn", effectData)
				end
			end)

			-- If they have enough money
			activator:TakePoints(price)

			timer.Simple(self:GetTeleporterTime(), function()
				if IsValid(self) then
					self:Teleport()
				end
			end)
		end
	end
end

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()

			-- draw "wires" in creative this is very resource intensive
			for _, lEnt in pairs(self:GetDestinations()) do
				if IsValid(lEnt) then
					local texcoord = math.Rand( 0, 1 )
					render.SetMaterial(self.WireMat)
					render.DrawBeam(self:GetPos() + self:OBBCenter(), lEnt:GetPos() + lEnt:OBBCenter(), 1, texcoord, texcoord + 1, Color( 20, 255, 30 ) )
				end
			end
		elseif self:GetModelVisible() then
			self:DrawModel()
		end
	end
end
