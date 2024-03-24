function nzRound:GetState() return self.State end
function nzRound:SetState( state ) self.State = state end

function nzRound:GetNumber() return self.Number or 0 end
function nzRound:SetNumber( num ) self.Number = num end

function nzRound:IsSpecial() return self.SpecialRound or false end
function nzRound:SetSpecial( bool ) self.SpecialRound = bool end

function nzRound:InState( state )
	return nzRound:GetState() == state
end

function nzRound:InProgress()
	return nzRound:GetState() == ROUND_PREP or nzRound:GetState() == ROUND_PROG
end

-- Extra stuff brought in by: Ethorbit
function nzRound:SetZombiesMax(num)
	self.ZombiesMax = num
	hook.Run("NZ.UpdateZombiesMax", num)
end
function nzRound:GetZombiesMax() return self.ZombiesMax or 0 end

function nzRound:SetZombiesKilled(num)
	self.ZombiesKilled = num
	hook.Run("NZ.UpdateZombiesKilled", num)
end
function nzRound:GetZombiesKilled() return self.ZombiesKilled or 0 end

 -- Commented because I gave zombiebase entities a :GetMaxHealth(), which supports more than just walkers like this does.
-- function nzRound:SetZombieHealth(num) self.ZombieHealth = num end
-- function nzRound:GetZombieHealth() return self.ZombieHealth or 0 end

function nzRound:SetZombieSpeeds(tbl) self.ZombieSpeeds = tbl end
function nzRound:GetZombieSpeeds() return self.ZombieSpeeds or {} end
