local playerMeta = FindMetaTable("Player")

function playerMeta:SetWhosWhoClone(clone)
	if (self.SetWhosWhoEntity) then
		self:SetWhosWhoEntity(clone)
	end
end

function playerMeta:GetWhosWhoClone() -- Gets their (non-player) who's who clone
	return self.GetWhosWhoEntity and self:GetWhosWhoEntity() or nil
end

if SERVER then
	util.AddNetworkString("NZSetSoloRevives")
	hook.Add("OnGameBegin", "ResetSoloRevsClient", function()
		net.Start("NZSetSoloRevives")
		net.WriteInt(0, 5)
		net.Broadcast()
	end)

	function playerMeta:DownPlayer()
		--if (self:IsSpectating()) then return end -- Spectators cannot go down! -- Added by: Ethorbit

		if (SERVER and IsValid(self.Reviving) and self.Reviving:GetClass() == "whoswho_downed_clone") then
			net.Start("NZWhosWhoReviving")
			net.WriteEntity(self.Reviving:GetPerkOwner())
			net.WriteBool(false)
			net.Broadcast()
		end

		local id = self:EntIndex()
		--self:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_HL2MP_SIT_PISTOL)

		nzRevive.Players[id] = {}
		nzRevive.Players[id].DownTime = CurTime()

		-- downed players are not targeted
		self:SetTargetPriority(TARGET_PRIORITY_NONE)
		self:SetHealth(100)
		self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

		if self:HasPerk("whoswho") or self:HasPerk("tombstone") then
			local weps = {}
			local blList = {"nz_revive_morphine", "nz_packapunch_arms", "nz_death_machine"}
			for i=1, #self:GetWeapons() do -- Do this instead of a pairs loop
				local v = self:GetWeapons()[i]
				if (!table.HasValue(blList, v:GetClass()) and !v:IsValidPerkBottle()) then
					table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap"), speed = v:HasNZModifier("speed"), dtap = v:HasNZModifier("dtap")})
				end
			end

			local perks = {}
			for _,perk in pairs(self:GetPerks()) do
				if perk != "whoswho" then
					table.insert(perks, perk)
				end
			end

			self.DownWeaponData = table.Copy(weps)
			self.DownPerkData = table.Copy(perks)
		end

		if self:HasPerk("whoswho") then
			self.HasWhosWho = true
			self:SaveGrenadeAmmo()

			local whoswhoTomb = self:HasPerk("tombstone")
			timer.Simple(5, function()
				-- If you choose to use Tombstone within these seconds, you won't make a clone and will get Who's Who back from Tombstone
				if IsValid(self) and !self:GetNotDowned() then
					--print("Should've respawned by now")

					nzRevive:CreateWhosWhoClone(self, nil, self.DownWeaponData, self.DownPerkData, whoswhoTomb)
					self.DownWeaponData = nil
					self.DownPerkData = nil
					nzRevive:RespawnWithWhosWho(self)
				end
			end)
		end

		-- Electric cherry AOE downed damage added by: Ethorbit
		if self:HasPerk("cherry") then
			nzEffects:Tesla( {
				pos = self:GetPos() + Vector(0,0,50),
				ent = self,
				turnOn = true,
				dieTime = 1,
				lifetimeMin = 0.05,
				lifetimeMax = 0.1,
				intervalMin = 0.01,
				intervalMax = 0.02,
			})

			local zombies = ents.FindInSphere(self:GetPos(), 350)
			for _,v in pairs(zombies) do
				if (IsValid(v) and v:IsValidZombie() and v:Health() > 0) then
					v:ApplyWebFreeze(5)
				end
			end
		end

		if self:HasPerk("tombstone") then
			nzRevive.Players[id].tombstone = true
		end

		if #player.GetAllPlaying() <= 1 and self:HasPerk("revive") and (!self.SoloRevive or self.SoloRevive < 3) then
			-- Despawn zombies nearby, so that we don't immediately go down when auto revived, created by Ethorbit
			for _,zombie in pairs(ents.FindInSphere(self:GetPos(), 200)) do
				if IsValid(zombie) and zombie:IsValidZombie() then
					zombie:RespawnZombie()
				end
			end

			self.SoloRevive = self.SoloRevive and self.SoloRevive + 1 or 1
			net.Start("NZSetSoloRevives")
			net.WriteInt(self.SoloRevive, 5)
			net.Send(self)

			self.DownedWithSoloRevive = true
			self:StartRevive(self)
			timer.Simple(8, function()
				if IsValid(self) and !self:GetNotDowned() then
					self:RevivePlayer(self, nil, true)
				end
			end)
			--print(self, "Downed with solo revive")
		end

		self.OldPerks = self:GetPerks()

		self:RemovePerks()

		self.DownPoints = math.Round(self:GetPoints()*0.05, -1)
		if self.DownPoints >= self:GetPoints() then
			self:SetPoints(0)
		else
			self:TakePoints(self.DownPoints, true)
		end

		hook.Call("PlayerDowned", nzRevive, self)

		-- Added by Ethorbit as I think this is helpful info to have
		if self.SetLastDownedPosition then
			self:SetLastDownedPosition(self:GetPos())
		end

		-- Equip the first pistol found in inventory - unless a pistol is already equipped
		local wep = self:GetActiveWeapon()
		if (IsValid(wep)) then
			if (type(wep.GetHoldType) == "string") then
				if  wep:GetHoldType() == "pistol" or wep:GetHoldType() == "duel" or wep.HoldType == "pistol" or wep.HoldType == "duel" then
					return
				end
			end

			for k,v in pairs(self:GetWeapons()) do
				if (type(v:GetHoldType()) == "string") then
					if v:GetHoldType() == "pistol" or v:GetHoldType() == "duel" or v.HoldType == "pistol" or v.HoldType == "duel" then
						self:SelectWeapon(v:GetClass())
						return
					end
				end
			end
		end
	end

	function playerMeta:RevivePlayer(revivor, nosync, force)
		local id = self:EntIndex()
		if !nzRevive.Players[id] then return end
		if !force and IsValid(revivor) and !revivor:GetNotDowned() then return end

		-- We are revived, if we have a clone we need to run ITS RevivePlayer function
		-- or else A: we won't have our perks/weapons and B: the clone might exist forever when it needs to be deleted
		if revivor then
			local clone = self:GetWhosWhoClone()
			if IsValid(clone) then
				clone:RevivePlayer(revivor)
			end
		end

		--self:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
		nzRevive.Players[id] = nil
		if !nosync then
			hook.Call("PlayerRevived", nzRevive, self, revivor)
		end

		if (self:Team() == TEAM_PLAYERS or self:IsInCreative()) then
			self:SetTargetPriority(TARGET_PRIORITY_PLAYER)
		end

		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)

		self.HasWhosWho = nil
		if IsValid(revivor) and revivor:IsPlayer() then
			if self.DownPoints then
				revivor:GivePoints(self.DownPoints)
			end

			--revivor:EquipPreviousWeapon()
			--revivor:SelectWeapon(revivor.NZPrevWep)
			timer.Simple(0.5, function()
				if revivor:GetWeapon("nz_revive_morphine") then
					revivor:StripWeapon("nz_revive_morphine") -- Remove the viewmodel again
				end
			end)
		end
		self.DownPoints = nil
		self.HasWhosWho = nil
		self.DownedWithSoloRevive = nil

		-- Added by Ethorbit as I think this is helpful info to have
		if self.SetLastRevivedPosition then
			self:SetLastRevivedPosition(self:GetPos())
		end

		--self:SetPos(self:GetPos() + Vector(0,0,25))
		self:ResetHull()
	end

	function playerMeta:StartRevive(revivor, nosync)
		local id = self:EntIndex()
		if (!revivor:Visible(self)) then return end -- Prevent reviving through walls and stuff
		if !nzRevive.Players[id] then return end -- Not even downed
		if nzRevive.Players[id].ReviveTime then return end -- Already being revived

		nzRevive.Players[id].ReviveTime = CurTime()
		nzRevive.Players[id].RevivePlayer = revivor
		revivor.Reviving = self

		-- Added by Ethorbit (Don't allow reviving someone if they are already being revived!)
		-- If we do this it can cause bugs, confusion and also isn't like COD at all..
		local alreadyBeingRevived = false
		for k,v in pairs(player.GetAll()) do
			if (v != revivor and v.Reviving == self) then
				alreadyBeingRevived = true
				break
			end
		end
		if (alreadyBeingRevived) then return end

		print("Started revive", self, revivor)

		if revivor:GetNotDowned() then -- You can revive yourself while downed with Solo Quick Revive
			local theirwep = revivor:GetActiveWeapon()
			if IsValid(theirwep) and !theirwep:IsSpecial() then revivor.NZRevWep = theirwep:GetClass() end

			revivor:Give("nz_revive_morphine") -- Give them the viewmodel
		end

		if !nosync then hook.Call("PlayerBeingRevived", nzRevive, self, revivor) end
	end

	function playerMeta:StopRevive(nosync)
		local id = self:EntIndex()
		if !nzRevive.Players[id] then return end -- Not even downed

		local revivor = nzRevive.Players[id].RevivePlayer
		if IsValid(revivor) then
			--revivor:SelectWeapon(revivor:GetWeapon(revivor.NZRevWep))
			--revivor:EquipPreviousWeapon()
			timer.Simple(0.5, function()
				if IsValid(revivor) and revivor:GetWeapon("nz_revive_morphine") then
					revivor:StripWeapon("nz_revive_morphine") -- Remove the revivors viewmodel
				end
			end)
		end

		nzRevive.Players[id].ReviveTime = nil
		nzRevive.Players[id].RevivePlayer = nil

		print("Stopped revive", self)

		if !nosync then hook.Call("PlayerNoLongerBeingRevived", nzRevive, self) end
	end

	function playerMeta:KillDownedPlayer(silent, nosync, nokill)
		local id = self:EntIndex()
		if !nzRevive.Players[id] then return end

		local revivor = nzRevive.Players[id].RevivePlayer
		if IsValid(revivor) then -- This shouldn't happen as players can't die if they are currently being revived
			revivor:SelectWeapon(revivor.NZRevWep)
			timer.Simple(0.5, function()
				if revivor:GetWeapon("nz_revive_morphine") then
					revivor:StripWeapon("nz_revive_morphine") -- Remove the revivors if someone was reviving viewmodel
				end
			end)
		end

		nzRevive.TombstoneSuicide(self) -- Added by Ethorbit, why should they lose their Tombstone drop because they didn't hold E?
		nzRevive.Players[id] = nil

		if !nokill then
			if silent then
				self:KillSilent()
			else
				self:Kill()
			end
		end

		-- Added by Ethorbit as I think this is helpful info to have
		if self.SetLastDeathPosition then
			self:SetLastDeathPosition(self:GetPos())
		end

		if !nosync then hook.Call("PlayerKilled", nzRevive, self) end
		self.HasWhosWho = nil
		self.DownPoints = nil
		self.DownedWithSoloRevive = nil
		for k,v in pairs(player.GetAllPlayingAndAlive()) do
			v:TakePoints(math.Round(v:GetPoints()*0.1, -1), true)
		end

		self:RemoveAllPowerUps()

		--self:SetPos(self:GetPos() + Vector(0,0,25))
		self:ResetHull()
	end

end

function playerMeta:GetNotDowned()
	local id = self:EntIndex()
	if nzRevive.Players[id] then
		return false
	else
		return true
	end
end

function playerMeta:GetDownedWithTombstone()
	local id = self:EntIndex()
	if nzRevive.Players[id] then
		return nzRevive.Players[id].tombstone or false
	else
		return false
	end
end

function playerMeta:GetPlayerReviving()
	return self.Reviving
end

-- We overwrite the shoot pos function here so we can set it to the lower angle when downed
local oldshootpos = playerMeta.GetShootPos
function playerMeta:GetShootPos()
	if self:GetNotDowned() then return oldshootpos(self) end
	return oldshootpos(self) + Vector(0,0,-15)
end
