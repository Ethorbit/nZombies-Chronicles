AddCSLuaFile()

ENT.Type			= "anim"

ENT.PrintName		= "perk_machine"
ENT.Author			= "Alig96"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.DynLightColors = {
	["jugg"] = Color(255, 100, 100),
	["speed"] = Color(100, 255, 100),
	["dtap"] = Color(255, 255, 100),
	["revive"] = Color(100, 100, 255),
	["dtap2"] = Color(255, 255, 100),
	["staminup"] = Color(200, 255, 100),
	["phd"] = Color(255, 50, 255),
	["deadshot"] = Color(150, 200, 150),
	["mulekick"] = Color(100, 200, 100),
	["cherry"] = Color(50, 50, 200),
	["tombstone"] = Color(100, 100, 100),
	["whoswho"] = Color(100, 100, 255),
	["vulture"] = Color(255, 100, 100),
	["pap"] = Color(200, 220, 220),
}

ENT.ProcessingPerks = {} -- Players that we're trying to give the perk to
ENT.NZEntity = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PerkID")
	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Bool", 1, "BeingUsed")
	self:NetworkVar("Int", 0, "Price")
end

function ENT:GetJingleSound()
	local id = self:GetPerkID()
	if id == "dtap2" then id = "dtap" end
	return "nzr/perks/jingles/jingle_" .. id .. ".mp3"
end

function ENT:StopJingle()
	self:StopSound(self:GetJingleSound())
end	

function ENT:PlayJingle()
	if (self:IsOn() and self:GetPerkID() != "wunderfizz") then
		self:EmitSound(self:GetJingleSound(), 75)	
	end
end

if SERVER then
	function ENT:GetJingleTimerName()
		return "PerkJingle_" .. self:EntIndex()
	end

	function ENT:MakeJingleTimer()
		timer.Stop(self:GetJingleTimerName())
		timer.Create(self:GetJingleTimerName(), math.Rand(1080, 9000), 1, function() 
			if (IsValid(self)) then
				self:PlayJingle()

				timer.Simple(3, function()
					if (IsValid(self)) then
						self:MakeJingleTimer()
					end
				end)		
			end
		end)
	end
end

function ENT:Initialize()
	if SERVER then
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )
		self:SetUseType( SIMPLE_USE )
		self:SetBeingUsed(false)
		local PerkData = nzPerks:Get(self:GetPerkID())
		self:SetPrice(PerkData.price)
	end
end

function ENT:TurnOn()
	if SERVER and !self:GetActive() then
		timer.Simple(math.Rand(0, 0.3), function()
			if (IsValid(self)) then
				self:EmitSound("nzr/machines/perk_turn_on.mp3")
			end
		end)	

		self:MakeJingleTimer()
	end

	self:SetActive(true)
	self:Update()
end

function ENT:TurnOff()
	self:SetActive(false)
	self:Update()

	if SERVER then
		timer.Stop(self:GetJingleTimerName())
	end
end

function ENT:Update()
	local PerkData = nzPerks:Get(self:GetPerkID())
	local skinmodel = PerkData.model
	if skinmodel then
		self:SetModel(skinmodel)
		if self:IsOn() then
			self:SetSkin(PerkData.on_skin or 0)
		else
			self:SetSkin(PerkData.off_skin or 1)
		end
	else
		self:SetModel(PerkData and (self:IsOn() and PerkData.on_model or PerkData.off_model) or "")
	end
end

function ENT:IsOn()
	return self:GetActive()
end

local MachinesNoDrink = {
	["pap"] = true,
}

function ENT:EndTouch(ent)
	if (self:GetPerkID() == "pap") then return end
	if (IsValid(ent) and ent:IsPlayer() and (!ent.LastPerkMachineTouch or CurTime() - ent.LastPerkMachineTouch >= 0.5)) then
		if (!self.LastBumpTime or CurTime() - self.LastBumpTime >= 1) then
			self.LastBumpTime = CurTime()
			self:EmitSound("nzr/effects/perk_bump_" .. math.random(0, 2) .. ".mp3", 65)
		end
	end

	ent.LastPerkMachineTouch = CurTime()
end

function ENT:Use(activator, caller)
	if (self.ProcessingPerks[activator]) then return end -- We're already trying to give them it
	if (isnumber(activator.nextUseTime) and CurTime() < activator.nextUseTime) then return end
	activator.nextUseTime = CurTime() + 1
	local PerkData = nzPerks:Get(self:GetPerkID())
	
	if self:IsOn() then
		-- Don't allow Quick Revive purchase for solos out of revives
		if (PerkData.name == "Quick Revive" and activator.SoloRevive and activator.SoloRevive >= 3 and #player.GetAllPlaying() <= 1) then return end 

		local price = self:GetPrice()
		-- As long as they have less than the max perks, unless it's pap
		if #activator:GetPerks() < GetConVar("nz_difficulty_perks_max"):GetInt() or self:GetPerkID() == "pap" then
			-- If they have enough money
			local func = function()
				local id = self:GetPerkID()
				if !activator:HasPerk(id) then
					local given = true
					
					if PerkData.condition then
						given = PerkData.condition(id, activator, self)
					end
					
					-- Call a hook for it
					local hookblock = hook.Call("OnPlayerBuyPerkMachine", nil, activator, self)
					if hookblock != nil then -- Only if the hook returned true/false
						given = hookblock
					end
					
					if given then
						self.ProcessingPerks[activator] = true

						if !PerkData.specialmachine then
							local wep = activator:Give("nz_perk_bottle")
							if IsValid(wep) then wep:SetPerk(id) end
							--timer.Simple(3, function()
								if IsValid(activator) and activator:GetNotDowned() then
									activator:GivePerk(id, self)
								end

								if IsValid(activator) then
									self.ProcessingPerks[activator] = false
								end
							--end)
						else
							activator:GivePerk(id, self)
							self.ProcessingPerks[activator] = false
						end

						if SERVER then 
							self:StopJingle()
						end
						
						if (IsValid(self) and self:IsOn()) then
							self:EmitSound("nz/machines/jingle/"..id.."_get.wav", 75)
						end

						return true
					end
				else
					self.ProcessingPerks[activator] = false
					print("Already have perk")
					return false
				end
			end
			
			-- If a perk has NoBuy true, then it won't run a Buy on it but just run the func directly
			-- (Allows stuff like dynamic pricing and conditional checks, similar to PaP)
			if PerkData.nobuy then func() else activator:Buy(price, self, func) end
		else
			print(activator:Nick().." already has max perks")
		end
	end
end

if CLIENT then
	local usedcolor = Color(255,255,255)
	
	function ENT:Draw()
		self:DrawModel()
		if self:GetActive() then
			if !self.NextLight or CurTime() > self.NextLight then
				-- Optimized by Blunto and improved optimization by Ethorbit.
                local dlight = DynamicLight( self:EntIndex(),true )
				if ( dlight ) then
					local col = nzPerks:Get(self:GetPerkID()).color or usedcolor
                    dlight.pos = self:GetPos() + self:OBBCenter() + (self:GetForward() * 40)
                    dlight.r = col.r
                    dlight.g = col.g
                    dlight.b = col.b
                    dlight.brightness = 5
                    dlight.Decay = 1000
                    dlight.Size = 150
                    dlight.minlight = 0
                    dlight.DieTime = CurTime() + 1
				end
				if math.random(300) == 1 then self.NextLight = CurTime() + 0.05 end
			end
		end
	end
end
