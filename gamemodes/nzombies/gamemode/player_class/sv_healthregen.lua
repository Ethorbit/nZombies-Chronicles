local HealthRegen = {
	Amount = 20,
	Delay = 2.4,
	Rate = 0.1
}

hook.Add( "Think", "RegenHealth", function()
	for k,v in pairs( player.GetAll() ) do

		if v:Alive() and v:GetNotDowned() and v:Health() < v:GetMaxHealth() and (!v.lastregen or CurTime() > v.lastregen + HealthRegen.Rate) and (!v.lasthit or CurTime() > v.lasthit + HealthRegen.Delay) then
			v.lastregen = CurTime()
			v:SetHealth( math.Clamp(v:Health() + HealthRegen.Amount, 0, v:GetMaxHealth() ) )
		end
	end
end )

hook.Add("EntityTakeDamage", "PreventHealthRegen", function(ent, dmginfo)
	if (!ent:IsPlayer()) then return end

	local sameply = dmginfo:GetAttacker() == ent
	local otherply = dmginfo:GetAttacker():IsPlayer() and !sameply
	if (otherply) then return end

	local phddmg = sameply and ent:HasPerk("phd") or ent.SELFIMMUNE
	if (!phddmg) then
		if (dmginfo:GetDamage() > 0) then
			if ent:GetNotDowned() then
				ent.lasthit = CurTime()

				-- Slow them down (Added by Ethorbit)
				if dmginfo:GetDamage() >= 15 then
					ent:ConCommand("-speed")

					local stam = ent:GetStamina()
					ent:SetStamina(0)
	
					timer.Simple(0.15, function()
						if (IsValid(ent) and ent:GetStamina() < stam) then
							ent:SetStamina(stam)
						end
					end)
				end
			end
		end
	end
end)
