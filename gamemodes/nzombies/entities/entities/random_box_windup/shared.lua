AddCSLuaFile( )

ENT.Type = "anim"

ENT.PrintName		= "random_box_windup"
ENT.Author			= "Alig96"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.NZEntity = true

function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "Winding" )
	self:NetworkVar( "String", 0, "WepClass")
	self:NetworkVar( "Bool", 1, "IsTeddy" )

end

function ENT:Initialize()

	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetLocalVelocity(self:GetAngles():Up() * 4)

	self:SetSolid( SOLID_OBB )
	self:DrawShadow( false )
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:SetWinding(true)
	self:SetIsTeddy(false)
	self.c = 0
	self.s = -20
	self.t = 0
	self:SetModel("models/weapons/w_rif_ak47.mdl")
	--self:SetAngles(self.Box:GetAngles())
	local box = self.Box -- self.Box

	if SERVER then
		-- Stop winding up
		if nzMapping.Settings.rboxweps then
			local keys = table.GetKeys(nzMapping.Settings.rboxweps)
			self.ScrollWepList = hook.Run("WindBoxWeapons", self.Buyer, keys) or keys -- Let a thirdparty hook decide our final weapon winding list (This can allow easy weapon injecting)
		end
		timer.Simple(5, function()
			self:SetWinding(false)
			if self:GetWepClass() == "nz_box_teddy" then
			--if true then
				self:SetModel("models/hoff/props/teddy_bear/teddy_bear.mdl")
				self:SetAngles( self.Box:GetAngles() + Angle(-90,90,0) )
				self:SetLocalVelocity(self.Box:GetAngles():Up()*30)

				hook.Call("OnPlayerGotTeddy", nil, nil)
				--nzNotifications:PlaySound("nz/randombox/teddy_bear_laugh.wav", 0)
				nzSounds:Play("Laugh")
				self:SetIsTeddy(true)
				if IsValid(self.Buyer) then self.Buyer:GivePoints(950) end -- Refund please
			else
				local wep = weapons.Get(self:GetWepClass())
				if (istable(wep)) then
					self:SetModel(wep.WM or wep.WorldModel)
					self:SetLocalVelocity(Vector(0,0,0)) -- Stop
					
					-- Make it obvious to players that this is a wonder weapon
					if (wep.NZWonderWeapon or istable(NZWonderWeapons) and table.HasValue(NZWonderWeapons, self:GetWepClass())) then -- istable(NZWonderWeapons) and table.HasValue(NZWonderWeapons, self:GetWepClass())
						if IsValid(self.Buyer) then
							net.Start("ShowMagicalHalo")
							net.WriteEntity(self)
							net.Send(self.Buyer)
						end
					end
				end
			end
			--print(self:GetModel())
		end)
		-- If we time out, remove the object
		timer.Simple(8.5, function() if IsValid(self) then self:SetLocalVelocity(self:GetAngles():Up()*-2) end end)

		-- If we time out, remove the object
		timer.Simple(18, function() 
			if IsValid(self) then 
				if (IsValid(self.Buyer)) then
					net.Start("RemoveMagicalHalo")
					net.WriteEntity(self)
					net.Send(self.Buyer)
				end
				
				if (IsValid(self.Box) and isfunction(self.Box.Close)) then
					self.Box:Close() 
				end
				
				--timer.Simple(1, function()
					if (IsValid(self)) then
						self:StopSound("chron/nz/effects/magical_loop.wav")
						self:Remove() 
					end
				--end)
			end 
		end)
	else
		local wep = weapons.Get(self:GetWepClass())
		if !wep then
			timer.Simple(1, function()
				if IsValid(self) then
					wep = weapons.Get(self:GetWepClass())
					if wep and wep.DrawWorldModel then self.WorldModelFunc = wep.DrawWorldModel end
				end
			end)
		elseif wep.DrawWorldModel then 
			self.WorldModelFunc = wep.DrawWorldModel
		end
	end
end

function ENT:Use( activator, caller )
	if self.Box:GetOpen() and !self:GetWinding() and self:GetWepClass() != "nz_box_teddy" then
		if activator == self.Buyer then
			local wep = ents.Create(self:GetWepClass()) -- We need to spawn it to check it before giving to player

			local class = self:GetWepClass()
			if (IsValid(wep) and isfunction(wep.GetSpecialCategory) and wep:GetSpecialCategory() == "specialgrenade") then
				activator:SetAmmo(3, "nz_specialgrenade")
			end
			
			if (IsValid(self) and IsValid(self.Buyer)) then
				net.Start("RemoveMagicalHalo")
				net.WriteEntity(self)
				net.Send(self.Buyer)

				self:StopParticles() 
				self:StopSound("chron/nz/effects/magical_loop.wav")
			end

			activator:Give(class)
			if (util.NetworkStringToID("VManip_SimplePlay") != 0) then
				net.Start("VManip_SimplePlay")
				net.WriteString("use")
				net.Send(activator)
			end

			if IsValid(wep) then
				wep:Remove()
			end

			nzWeps:GiveMaxAmmoWep(activator, class)
			self.Box:Close()
			self:Remove()

			local boxDelay = 0.5
			local plyNumber = 0
			if (#player.GetAllPlayingAndAlive() > 1) then
				local entsNearby = ents.FindInBox(self:GetPos() + Vector(300, 300, 300), self:GetPos() - Vector(300, 300, 300))
				for _,v in pairs(entsNearby) do
					if (IsValid(v) and v:IsPlayer() and v:GetNotDowned() and v != activator) then
						plyNumber = plyNumber + 1
					end
				end

				boxDelay = 0.5 + (0.5 * plyNumber)
			end

			activator.LastBoxUseTime = CurTime() + boxDelay
		else
			if IsValid(self.Buyer) then
				activator:PrintMessage( HUD_PRINTTALK, "This is " .. self.Buyer:Nick() .. "'s gun. You cannot take it." )
			end
		end
	end
end

function ENT:WindUp( )
	local gun
	if self.ScrollWepList then
		gun = weapons.Get(self.ScrollWepList[math.random(#self.ScrollWepList)])
	else
		gun = table.Random(weapons.GetList())
	end

	if gun and gun.WorldModel != nil then
		self:SetModel(gun.WM or gun.WorldModel)
	end
	--[[self.c = self.c + 1.3
	if self.c > 7 then
		self.c = 7
	end
	self:SetPos(Vector(self:GetPos().X, self:GetPos().Y, self:GetPos().Z + 0.1*self.c))]]
end

function ENT:TeddyFlyUp( )
	self.t = self.t + 1
	if self.t > 25 then
		self.Box:Close()
		self.Box:MoveAway()
		self:Remove()
		self.t = 25
	end
	--self:SetPos(Vector(self:GetPos().X, self:GetPos().Y, self:GetPos().Z + 1*self.t))
end

function ENT:WindDown( )
	--[[self.s = self.s + 1

	if self.s > 7 then
		self.s = 7
	end
	if self.s >= 0 then
		self:SetPos(Vector(self:GetPos().X, self:GetPos().Y, self:GetPos().Z - 0.1*self.s))
	end]]
end

function ENT:Think()
	if SERVER then
		if self:GetIsTeddy() then
			self:TeddyFlyUp()
		elseif self:GetWinding() then
			self:WindUp()
		else
			self:WindDown()
		end
	end
end

if CLIENT then
	function ENT:Draw()
		-- If we've stopped winding
		if !self:GetWinding() then
			-- We can use the stored world model draw function from the original weapon, but if it doesn't exist or causes errors, then just draw model
			if !self.WorldModelFunc or !pcall(self.WorldModelFunc, self) then self:DrawModel() end
		else
			self:DrawModel()
		end
	end
end
