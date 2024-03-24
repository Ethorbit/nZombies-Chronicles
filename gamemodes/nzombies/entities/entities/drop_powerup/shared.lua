AddCSLuaFile()

ENT.Type = "anim"
 
ENT.PrintName		= "drop_powerups"
ENT.Author			= "Alig96"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "PowerUp" )
	
end

function ENT:Initialize()
	if SERVER then
		timer.Simple(1, function()
			if (IsValid(self)) then
				self:EmitSound("nzr/announcer/powerups/ambience/power_up_loop.wav")
			end	
		end)
	end
	

	//self:SetPowerUp("dp")
	self:SetModelScale(nzPowerUps:Get(self:GetPowerUp()).scale, 0)
	
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitSphere(60, "default_silent")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	if SERVER then
		self:SetTrigger(true)
		self:SetUseType(SIMPLE_USE)
	else
		self.NextParticle = CurTime()
	end
	self:UseTriggerBounds(true, 20)
	--self:SetMaterial("models/shiny.vtf")
	self:SetColor( Color(255,200,0) )
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	--self:SetTrigger(true)
	
	--[[timer.Create( self:EntIndex().."_deathtimer", 30, 1, function()
		if IsValid(self) then
			timer.Destroy(self:EntIndex().."_deathtimer")
			if SERVER then
				self:Remove()
			end			
		end
	end)]]
	self.RemoveTime = CurTime() + 30
end

if SERVER then
	function ENT:StartTouch(hitEnt)
		if (hitEnt:IsValid() and hitEnt:IsPlayer()) then
			nzRound:SetPowerUpsGrabbed(nzRound:GetPowerUpsGrabbed() + 1)
			self:StopSound("nzr/announcer/powerups/ambience/power_up_loop.wav")
			
			nzPowerUps:Activate(self:GetPowerUp(), hitEnt, self)
			self:Remove()
		end
	end
	
	function ENT:Think()
		local timeLeft = self.RemoveTime - CurTime()
		
		if timeLeft < 7 and timeLeft > 2 then -- Blink slow
			if (!self.NextBlinkTime or CurTime() > self.NextBlinkTime) then
				self.NextBlinkTime = CurTime() + 1
				self:SetNoDraw(true)
				self:SetRenderMode(RENDERMODE_NONE)
						
				timer.Simple(0.6, function()
					if (IsValid(self)) then
						self:SetNoDraw(false)
						self:SetRenderMode(RENDERMODE_NORMAL)
					end
				end)	
			end
		end

		if timeLeft <= 2 then -- Blink fast
			if (!self.NextBlinkTime or CurTime() > self.NextBlinkTime) then
				self.NextBlinkTime = CurTime() + 0.5
				self:SetNoDraw(true)
				
				timer.Simple(0.3, function()
					if (IsValid(self)) then
						self:SetNoDraw(false)
					end
				end)	
			end
		end

		if self.RemoveTime and CurTime() > self.RemoveTime then
			self:StopSound("nzr/announcer/powerups/ambience/power_up_loop.wav")
			self:Remove()
		end
	end
end

if CLIENT then
	--local glow = Material ( "sprites/glow04_noz" )
	--local col = Color(0,200,255,255)
	
	local particledelay = 0.1
	
	function ENT:Draw()
		if CurTime() > self.NextParticle then
			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			util.Effect( "powerup_glow", effectdata )
			self.NextParticle = CurTime() + particledelay
		end
		self:DrawModel()
	end
	
	function ENT:Think()
		if !self:GetRenderAngles() then self:SetRenderAngles(self:GetAngles()) end
		self:SetRenderAngles(self:GetRenderAngles()+(Angle(0,50,0)*FrameTime()))
	end
	
	-- hook.Add( "PreDrawHalos", "drop_powerups_halos", function()
	-- 	halo.Add( ents.FindByClass( "drop_powerup" ), Color( 0, 255, 0 ), 50, 50, 0 )
	-- end)
end