--
local revivefailtime = 0.2

if SERVER then
	util.AddNetworkString("NZWhosWhoCurTime")
	util.AddNetworkString("NZWhosWhoReviving")

	hook.Add("Think", "CheckDownedPlayersTime", function()
		for k,v in pairs(nzRevive.Players) do
			-- Lol this is retarded, but basically you were able to revive your own Who's Who clone even after going down/dying and then it would open a whole new can of worms of broken NZ shit
			if (IsValid(v.RevivePlayer) and !v.RevivePlayer:GetNotDowned() and v.RevivePlayer.Reviving and IsValid(v.RevivePlayer.Reviving) and v.RevivePlayer.Reviving:GetClass() == "whoswho_downed_clone") then
				net.Start("NZWhosWhoReviving")
				net.WriteEntity(v.RevivePlayer)
				net.WriteBool(false)
				net.Broadcast()

				net.Start("NZWhosWhoCurTime")
				net.WriteEntity(v.RevivePlayer)
				net.Broadcast()
				
				--nzRevive:PlayerNoLongerBeingRevived(v.RevivePlayer)
				v.RevivePlayer:StopRevive()
				v.RevivePlayer.Reviving = nil
				v.RevivePlayer = nil
				v.ReviveTime = nil
				v.DownTime = CurTime()

				--nzRevive.Players[k] = nil
			end
			
			-- Stop reviving players when you don't exist or are down/dead
			if (v.RevivePlayer and !v.RevivePlayer:IsValid() or v.RevivePlayer and !v.RevivePlayer:GetNotDowned()) then
				--local plyBeingRevived = v.RevivePlayer
				if (v.RevivePlayer.Reviving) then
					v.RevivePlayer.Reviving:StopRevive()

					if v.RevivePlayer and v.RevivePlayer.Reviving then
						v.RevivePlayer.Reviving = nil
					end
				end
			end

			-- if (v.ReviveTime and v.RevivePlayer and !v.RevivePlayer:GetNotDowned() || !IsValid(v.RevivePlayer)) then
			-- 	v.ReviveTime = nil
			-- end
			
			-- The time it takes for a downed player to die - Prevent dying if being revived
			if CurTime() - v.DownTime >= GetConVar("nz_downtime"):GetFloat() and !v.ReviveTime then
				local ent = Entity(k)
				if ent.KillDownedPlayer then
					ent:KillDownedPlayer()
				else
					-- If it's a non-player entity, do the same thing just to clean up the table
					local revivor = v.RevivePlayer
					if IsValid(revivor) then
						revivor:StripWeapon("nz_revive_morphine")
						revivor:EquipPreviousWeapon()
					end
					nzRevive.Players[k] = nil
				end
			end
		end
	end)
end

function nzRevive.HandleRevive(ply, ent)
	-- Make sure other downed players can't revive other downed players next to them
	if !nzRevive.Players[ply:EntIndex()] then
		local tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector()*100, ply)

		-- Changed from line trace to view cone for reviving by: Ethorbit
		local dply = tr.Entity
		for k,v in pairs(ents.FindInCone(ply:EyePos(), ply:GetAimVector() * 120, 100, 100)) do
			if (v:IsPlayer() and v != ply and !v:GetNotDowned() or v:GetClass() == "whoswho_downed_clone") then 
				dply = v
			end
		end

		local ct = CurTime()

		-- Added by Ethorbit (Don't allow reviving people through walls/ceilings)
		if (IsValid(dply) and IsValid(ply)) then
			if (!ply:Visible(dply)) then
				if (ply.Reviving) then
					ply.Reviving:StopRevive()
					ply.Reviving = nil

					if (!dply:IsPlayer() and isfunction(dply.GetPerkOwner)) then -- If it's a Who's Who clone we should reset its revive icon status
						net.Start("NZWhosWhoReviving")
						net.WriteEntity(dply:GetPerkOwner())
						net.WriteBool(false)
						net.Broadcast()
					end
				end
			return end
		end

		-- Added by Ethorbit (Don't allow reviving someone if they are already being revived!)
		-- If we do this it can cause bugs, confusion and also isn't like COD at all..
		local downsrevivor = istable(nzRevive.Players[dply:EntIndex()]) and nzRevive.Players[dply:EntIndex()].RevivePlayer or nil
		if (downsrevivor and IsValid(dply) and IsValid(downsrevivor) and downsrevivor != ply) then return end

		-- Also added by Ethorbit (I'm pretty sure this was supposed to be in the gamemode)
		if (ply.Reviving and !IsValid(dply)) then 
			if (IsValid(ply.Reviving) and !ply.Reviving:IsPlayer() and IsValid(ply.Reviving:GetPerkOwner()) and ply.Reviving:GetPerkOwner():IsPlayer()) then
				net.Start("NZWhosWhoReviving")
				net.WriteEntity(ply.Reviving:GetPerkOwner())
				net.WriteBool(false)
				net.Broadcast()
			else
				net.Start("NZWhosWhoReviving")
				net.WriteEntity(ply)
				net.WriteBool(false)
				net.Broadcast()
			end

			if ply.Reviving.StopRevive then
				ply.Reviving:StopRevive()
			end
			
			ply.Reviving = nil
		end

		if IsValid(dply) and !nzRevive.Players[dply:EntIndex()] then
			if (ply.Reviving) then
				ply:StripWeapon("nz_revive_morphine")
			end
		end

		--if (ply:GetPos():Distance(dply:GetPos()) <= 20) then return end
		if IsValid(dply) and (dply:IsPlayer() or dply:GetClass() == "whoswho_downed_clone") then
			local id = dply:EntIndex()
			if nzRevive.Players[id] then
				if (nzRevive.Players[id].RevivePlayer == ply) then
					local plysWep = ply:GetActiveWeapon()
					if (!IsValid(plysWep) or IsValid(plysWep) and plysWep:GetClass() != "nz_revive_morphine") then
						if (!IsValid(ply:GetWeapon("nz_revive_morphine"))) then
							ply:Give("nz_revive_morphine")
						end
			
						ply:SetActiveWeapon(ply:GetWeapon("nz_revive_morphine"))
					end
				end
				
				if !nzRevive.Players[id].RevivePlayer then
					if (IsValid(ply.Reviving)) then
						if ply.Reviving:GetClass() == "whoswho_downed_clone" then
							net.Start("NZWhosWhoReviving")
							net.WriteEntity(ply.Reviving:GetPerkOwner())
							net.WriteBool(false)
							net.Broadcast()
						end

						ply.Reviving:StopRevive()
					end
					
					dply:StartRevive(ply)
					if (dply:GetClass() == "whoswho_downed_clone") then
						if (IsValid(dply:GetPerkOwner())) then		
							net.Start("NZWhosWhoReviving")
							net.WriteEntity(dply:GetPerkOwner())
							net.WriteBool(true)
							net.Broadcast()
						end
					end
				end

				-- print(CurTime() - nzRevive.Players[id].ReviveTime)
				
				if ply:HasPerk("revive") and ct - nzRevive.Players[id].ReviveTime >= 1.5 -- With quick-revive
				or ct - nzRevive.Players[id].ReviveTime >= 3.03 then	-- 3 is the time it takes to revive
					dply:RevivePlayer(ply)
					ply.Reviving = nil
				end
			end
		elseif ply.LastReviveTime ~= nil and IsValid(ply.Reviving) and ply.Reviving != dply -- Holding E on another player or no player
		and ct > ply.LastReviveTime + revivefailtime then -- and for longer than fail time window
			local id = ply.Reviving:EntIndex()
			if nzRevive.Players[id] then
				if nzRevive.Players[id].ReviveTime then
					--ply:SetMoveType(MOVETYPE_WALK)
					ply.Reviving:StopRevive()
					ply.Reviving = nil
				end
			end
		end

		-- When a player stops reviving
		if !ply:KeyDown(IN_USE) then -- If you have an old revival target
			if IsValid(ply.Reviving) and (ply.Reviving:IsPlayer() or ply.Reviving:GetClass() == "whoswho_downed_clone") then
				local id = ply.Reviving:EntIndex()
				if nzRevive.Players[id] then
					if nzRevive.Players[id].ReviveTime then
						if (ply.Reviving and IsValid(ply.Reviving) and !ply.Reviving:IsPlayer() and IsValid(ply.Reviving:GetPerkOwner())) then
							net.Start("NZWhosWhoReviving")
							net.WriteEntity(ply.Reviving:GetPerkOwner())
							net.WriteBool(false)
							net.Broadcast()
						end
						
						--ply:SetMoveType(MOVETYPE_WALK)
						ply.Reviving:StopRevive()
						ply.Reviving = nil
						--nz.nzRevive.Functions.SendSync()
					end
				end
			end
		end

	end
end

-- Hooks
hook.Add("FindUseEntity", "CheckRevive", nzRevive.HandleRevive)

if SERVER then
	util.AddNetworkString("nz_TombstoneSuicide")

	function nzRevive.TombstoneSuicide(ply, weps, perks, force)
		if !weps and ply.DownWeaponData then
			weps = table.Copy(ply.DownWeaponData)
		end

		if !perks and ply.DownPerkData then
			perks = table.Copy(ply.DownPerkData)
		end

		if force or ply:GetDownedWithTombstone() then
			local tombstone = ents.Create("drop_tombstone")
			tombstone:SetPos(ply:GetPos() + Vector(0,0,50))
			tombstone:Spawn()

			-- local weps = {}
			-- local blList = {"nz_revive_morphine", "nz_perk_bottle", "nz_packapunch_arms", "nz_death_machine"}
			-- for i=1, #ply:GetWeapons() do -- Do this instead of a pairs loop
			-- 	local v = ply:GetWeapons()[i]
			-- 	if (!table.HasValue(blList, v:GetClass())) then
			-- 		table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap")})
			-- 	end
		
			-- 	--table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap")})
			-- end

			-- local perks = ply.OldPerks

			tombstone.OwnerData.weps = weps
			tombstone.OwnerData.perks = perks		
			ply.DownWeaponData = nil
			ply.DownPerkData = nil	
			tombstone:SetPerkOwner(ply)
		end
	end

	net.Receive("nz_TombstoneSuicide", function(len, ply)
		nzRevive.TombstoneSuicide(ply)
		ply:KillDownedPlayer()
	end)
end

if SERVER then
	util.AddNetworkString("nz_WhosWhoActive")
end

function nzRevive:CreateWhosWhoClone(ply, pos, weps, perks, tombstone) -- weps, perks, tombstone parameters added by Ethorbit, it allows more flexibility and we can pass things like the Mule Kick weapon in
	local pos = pos or ply:GetPos()

	local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() != "nz_perk_bottle" and ply:GetActiveWeapon():GetClass() or ply.oldwep or nil

	local who = ents.Create("whoswho_downed_clone")
	who:SetPos(pos + Vector(0, 0, 10))
	who:SetAngles(ply:GetAngles())
	who:Spawn()
	ply:SetWhosWhoClone(who)
	who:GiveWeapon(wep)
	who:SetPerkOwner(ply)
	who:SetModel(ply:GetModel())
	who.OwnerHasTombstone = tombstone
	
	-- Refill their grenades (Added by Ethorbit)
	local nade_ammotype = GetNZAmmoID("grenade")
	if nade_ammotype then
		ply:SetAmmo(3, nade_ammotype)
	end

	who.OwnerData.perks = perks --ply.OldPerks or ply:GetPerks()
	who.OwnerData.weps = weps

	-- BIG NONO, doing this means they may not be given in the same order
	-- for k,v in SortedPairsByValue(ply:GetWeapons()) do
	-- 	table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap"), speed = v:HasNZModifier("speed"), dtap = v:HasNZModifier("dtap")})
	-- end

	-- local weps = {}
	-- local blList = {"nz_revive_morphine", "nz_perk_bottle", "nz_packapunch_arms", "nz_death_machine"}
	-- for i=1, #ply:GetWeapons() do -- Do this instead of a pairs loop
	-- 	local v = ply:GetWeapons()[i]
	-- 	if (!table.HasValue(blList, v:GetClass())) then
	-- 		table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap"), speed = v:HasNZModifier("speed"), dtap = v:HasNZModifier("dtap")})
	-- 	end

	-- 	--table.insert(weps, {class = v:GetClass(), pap = v:HasNZModifier("pap"), speed = v:HasNZModifier("speed"), dtap = v:HasNZModifier("dtap")})
	-- end

	-- timer.Simple(1, function()
	-- 	player_manager.RunClass(ply, "Loadout") -- Rearm them
	-- end)

	timer.Simple(0.1, function()
		if IsValid(who) then
			local id = who:EntIndex()

			if self then
				self.Players[id] = {}
				self.Players[id].DownTime = CurTime()
			end

			hook.Call("PlayerDowned", nzRevive, who)
		end
	end)

	ply.WhosWhoClone = who
	ply.WhosWhoMoney = 0

	net.Start("NZWhosWhoReviving")
	net.WriteEntity(ply)
	net.WriteBool(false)
	net.Broadcast()

	net.Start("nz_WhosWhoActive")
		net.WriteBool(true)
	net.Send(ply)
end

function nzRevive:RespawnWithWhosWho(ply, pos)
	local pos = pos or nil

	if !pos then
		local spawns = {}
		local plypos = ply:GetPos()
		local maxdist = 1500^2
		local mindist = 500^2

		local findEnt = #ents.FindByClass("nz_spawn_player_special") > 0 and "nz_spawn_player_special" or "nz_spawn_zombie_special"
		local available = ents.FindByClass(findEnt)
		if IsValid(available[1]) then
			for k,v in pairs(available) do
				local dist = plypos:DistToSqr(v:GetPos())
				if v.link == nil or nzDoors:IsLinkOpened( v.link ) then -- Only for rooms that are opened (using links)
					if dist < maxdist and dist > mindist then -- Within the range we set above
						if v:IsSuitable() then -- And nothing is blocking it
							table.insert(spawns, v)
						end
					end
				end
			end
			if !IsValid(spawns[1]) then
				for k,v in pairs(available) do -- Retry, but without the range check (just use all of them)
					local dist = plypos:DistToSqr(v:GetPos())
					if v.link == nil or nzDoors:IsLinkOpened( v.link ) then
						if v:IsSuitable() then
							table.insert(spawns, v)
						end
					end
				end
			end
			if !IsValid(spawns[1]) then -- Still no open linked ones?! Spawn at a random player spawnpoint
				local pspawns = ents.FindByClass("player_spawns")
				if !IsValid(pspawns[1]) then
					ply:Spawn()
				else
					pos = pspawns[math.random(#pspawns)]:GetPos()
				end
			else
				pos = spawns[math.random(#spawns)]:GetPos()
			end
		else
			-- There exists no special spawnpoints - Use regular player spawns
			local pspawns = ents.FindByClass("player_spawns")
			if !IsValid(pspawns[1]) then
				ply:Spawn()
			else
				pos = pspawns[math.random(#pspawns)]:GetPos()
			end
		end
	end
	ply:RevivePlayer()
	ply:StripWeapons()
	
	timer.Simple(1, function()
		if (IsValid(ply)) then
			player_manager.RunClass(ply, "Loadout") -- Rearm them
		end
	end)

	ply:SetUsingSpecialWeapon(false)

	if pos then ply:SetPos(pos + Vector(0, 0, 25)) end

	if (CLIENT) then
		ply.DownTime = CurTime()
		
	end

	if SERVER then
		net.Start("NZWhosWhoCurTime")
		net.WriteEntity(ply)
		--net.WriteFloat(CurTime(), 32)
		net.Broadcast() -- Everyone needs to know so their revive icons are correct
	end
end
