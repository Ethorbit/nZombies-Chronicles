-- Transitioned from Serverside only code to Shared code by: Ethorbit
-- (Clients should be able to know if they are sprinting or what their
-- max sprint speed is..)

local plymeta = FindMetaTable( "Player" )
AccessorFunc( plymeta, "fStamina", "Stamina", FORCE_NUMBER )
AccessorFunc( plymeta, "fMaxStamina", "MaxStamina", FORCE_NUMBER )
AccessorFunc( plymeta, "fLastStaminaRecover", "LastStaminaRecover", FORCE_NUMBER )
AccessorFunc( plymeta, "fLastStaminaLoss", "LastStaminaLoss", FORCE_NUMBER )
AccessorFunc( plymeta, "fStaminaLossAmount", "StaminaLossAmount", FORCE_NUMBER )
AccessorFunc( plymeta, "fStaminaRecoverAmount", "StaminaRecoverAmount", FORCE_NUMBER )
AccessorFunc( plymeta, "fNextAllowedSprint", "NextAllowedSprint", FORCE_NUMBER )
--AccessorFunc( plymeta, "fMaxRunSpeed", "MaxRunSpeed", FORCE_NUMBER )
AccessorFunc( plymeta, "bSprinting", "Sprinting", FORCE_BOOL )
AccessorFunc( plymeta, "bSpawned", "Spawned", FORCE_BOOL )

function plymeta:SetMaxRunSpeed(num)
	if num <= 0 then return end -- Fuck you
	self.fMaxRunSpeed = num
end

function plymeta:GetMaxRunSpeed()
	if self.fMaxRunSpeed == nil or self.fMaxRunSpeed <= 0 then
		self.fMaxRunSpeed = self:GetDefaultRunSpeed()
	end

	return self.fMaxRunSpeed
end

function plymeta:IsSprinting()
	return self:GetSprinting()
end

-- function plymeta:CancelSprint()
-- 	self:SetNextAllowedSprint(CurTime() + 0.5)
-- end

function plymeta:InitStamina()
	self:SetSprinting( false )
	self:SetNWBool("Sprinting", false)
	self:SetStamina( 100 )
	self:SetMaxStamina( 100 )

	--The rate is fixed on 0.05 seconds
	self:SetStaminaLossAmount( 2 )
	self:SetStaminaRecoverAmount( 4 )

	self:SetLastStaminaLoss( 0 )
	self:SetLastStaminaRecover( 0 )

	self:ConCommand("-speed") -- Spectators can abuse something that this will stop
end

hook.Add( "Think", "PlayerSprint", function()
    if !nzRound:InState( ROUND_CREATE ) then
        for _, ply in pairs( player.GetAll() ) do
			if ply:GetNextAllowedSprint() == nil then -- Just in case, lol
				ply:SetNextAllowedSprint(0)
			end

			if ply:GetStamina() == nil then
				ply:InitStamina()
			end

            if (!isnumber(ply:GetMaxStamina()) or !isnumber(ply:GetStamina()) or !isnumber(ply:GetLastStaminaRecover())) then return end
            if (!IsValid(ply)) then return end
			if ply:Alive() and ply:GetNotDowned() and ply:IsSprinting() and ply:GetStamina() >= 0 and ply:GetLastStaminaLoss() + 0.05 <= CurTime() then
				ply:SetStamina( math.Clamp( ply:GetStamina() - ply:GetStaminaLossAmount(), 0, ply:GetMaxStamina() ) )
				ply:SetLastStaminaLoss( CurTime() )

				-- Delay the recovery a bit, you can't sprint instantly after
				ply:SetLastStaminaRecover( CurTime() + 0.75 )

				if SERVER and ply:GetStamina() == 10 then
					ply:SetNWBool("Sprinting", false)
				end

				if ply:GetStamina() == 0 then -- or CurTime() < ply:GetNextAllowedSprint()
					ply:SetRunSpeed( ply:GetWalkSpeed() )
					ply:SetSprinting( false )
					ply:ConCommand("-speed")
				end
			elseif ply:Alive() and ply:GetNotDowned() and !ply:IsSprinting() and ply:GetStamina() < ply:GetMaxStamina() and ply:GetLastStaminaRecover() + 0.05 <= CurTime() then
				ply:SetStamina( math.Clamp( ply:GetStamina() + ply:GetStaminaRecoverAmount(), 0, ply:GetMaxStamina() ) )
				ply:SetLastStaminaRecover( CurTime() )
			end
		end
	end
end )

hook.Add( "KeyPress", "OnSprintKeyPressed", function( ply, key )
	if !nzRound:InState( ROUND_CREATE ) and ( key == IN_SPEED ) and IsValid(ply) and (ply:Alive() and !ply:IsSpectating()) then
		ply:SetSprinting( true )
		ply:SetNWBool("Sprinting", true)
	end
end )

if (CLIENT) then
	-- Sprint logic, but for clientside Spectator targets (Purely for the animation)
	hook.Add("TranslateActivity", "OnSpectatorTargetSprint", function(ply, act)
		if (LocalPlayer():IsSpectating()) then
			local target = LocalPlayer():GetObserverTarget()
			if (IsValid(target) and target == ply) then
				if (act and act == ACT_MP_RUN and target:GetNWBool("Sprinting")) then
					target:SetSprinting(true)
				else
					target:SetSprinting(false)
				end
			end
		end
	end)
end

hook.Add( "KeyRelease", "OnSprintKeyReleased", function( ply, key )
	-- Always reset sprint state even if player is dead.
	-- Reason: player can die while holding shift.
	if !nzRound:InState( ROUND_CREATE ) and ( key == IN_SPEED ) and (ply:Alive() and !ply:IsSpectating()) then
		ply:SetSprinting( false )
		ply:SetNWBool("Sprinting", false)
		ply:SetRunSpeed( ply:GetMaxRunSpeed() )
	end
end )
