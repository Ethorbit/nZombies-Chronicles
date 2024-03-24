-- ONLY for overriding!
-- New stuff for existing tables go to extensions/

-- After 8+ years of this stupid fucking lua error showing for people, I've decided to just fix it myself /Ethorbit
local server_only_ents
function SafeRemoveEntity( ent )
    if ( !IsValid( ent ) || ent:IsPlayer() ) then return end

    if CLIENT then
        server_only_ents = server_only_ents or {
            -- add whatever the game cries about deleting
            ["class C_HL2MPRagdoll"] = true -- Yes it literally has 'class' in the classname. :facepalm:
        }

        if server_only_ents[ent:GetClass()] then return end
    end

    ent:Remove()
end

-- Override existing hooks
nzHookAdd = nzHookAdd or hook.Add
hook.Add = function(eventName, ...)
    if (eventName == "ShouldCollide") then
        eventName = "OptimizedShouldCollide"
    end

    nzHookAdd(eventName, ...)
end

-- Ultimate lag fix by: Ethorbit 
-- Our goal is to override ShouldCollide with something that is much more optimized
-- When someone adds a ShouldCollide hook, they're actually adding OptimizedShouldCollide instead
-- The goal is to ignore collision checking when it is unnecessary, this avoids wasting a lot of processing time on nothing
-- The end result is far less lag
local ignore_collisiongroup = {
    [COLLISION_GROUP_DEBRIS] = 1
}
nzHookAdd("ShouldCollide", "nzShouldCollideOptimizer", function(ent1, ent2)
    if ent1:IsWorld() or ent2:IsWorld() then return true end -- No need to process LITERALLY NOTHING GMOD
    if ent1:IsNextBot() or ent2:IsNextBot() then return true end -- Zombies don't have real collisions anyways
    if ent1.NZOnlyVisibleInCreative or ent2.NZOnlyVisibleInCreative then
        if ignore_collisiongroup[ent1:GetCollisionGroup()] or ignore_collisiongroup[ent2:GetCollisionGroup()] then
            return false
        end
    end

    return hook.Run("OptimizedShouldCollide", ent1, ent2)
end)
-----------------------------------------------------------------------------------------

local cTakeDmgInfo = FindMetaTable("CTakeDamageInfo")

if CLIENT then
	-- Get that laggy shit out of here
	halo.Add = function() end
end

local oldDamageInfo = oldDamageInfo or DamageInfo
function DamageInfo()
	local obj = oldDamageInfo()

	--if obj.Reset then
		obj:Reset(true)
	--end

	return obj
end

hook.Add("PostEntityTakeDamage", "PostEntTakeDamage", function(ent, dmginfo, took)
	if dmginfo then --and dmginfo.Reset then
		dmginfo:Reset(true)
	end
end)
------------------------------------------------------------------

local entMeta = FindMetaTable("Entity")

if SERVER then
	-- TakeDamageInfo crash fix by Ethorbit as I have gotten really
	-- fucking annoyed by thirdparty code (even some gamemode code) causing it.
	local oldTakeDamageInfo = entMeta.TakeDamageInfo
	function entMeta:TakeDamageInfo(dmginfo)
		if self.Health and isfunction(self.Health) and self:Health() <= 0 then return end -- JUST STOP!

		oldTakeDamageInfo(self, dmginfo)
	end
end

local playerMeta = FindMetaTable("Player")
local wepMeta = FindMetaTable("Weapon")
local physMeta = FindMetaTable("PhysObj")

-- "Speed hack" bug fix by Ethorbit (after months of trying to figure out the cause)
-- Turns out, the game sets the player's speed to 0 sometimes, and 0 causes "speed hack"
local oldSetRunSpeed = playerMeta.SetRunSpeed
function playerMeta:SetRunSpeed(speed, ...)
	if speed <= 0 then return end -- Fuck you
	oldSetRunSpeed(self, speed, ...)
end

local oldSetWalkSpeed = playerMeta.SetWalkSpeed
function playerMeta:SetWalkSpeed(speed, ...)
	if speed <= 0 then return end -- Fuck you
	oldSetWalkSpeed(self, speed, ...)
end
-----------------------------------------------------------------------------------------

if SERVER then
	-- Added by Ethorbit, nullify physics functions as this fucks up and physically pushes stuff like the Mystery Box
	local oldApplyForceCenter = physMeta.ApplyForceCenter
	function physMeta:ApplyForceCenter( force )
		if (IsValid(self) and self.GetEntity and IsValid(self:GetEntity()) and !self:GetEntity().NZEntity) then
			return oldApplyForceCenter(self, force)
		end
	end

	-- Override physics functions that fuck up when looking at a prop and then pausing in Singleplayer (they would end up falling through the map)
	local oldPhysWake = physMeta.Wake
	function physMeta:Wake()
		local ent = self.GetEntity and self:GetEntity() or nil
		if (ent and ent.NZEntity) then return end
		return oldPhysWake(self)
	end

	local oldEnableMotion = physMeta.EnableMotion
	function physMeta:EnableMotion(bool)
		local ent = self.GetEntity and self:GetEntity() or nil
		if (ent and bool and ent.NZEntity) then return end
		return oldEnableMotion(self, bool)
	end
	----------------------------------------------------------------------------------------------------------------------------------
	-- Only allow ONE of each nZombie Item (knife/grenade/specialgrenade)
	-- (Why was this functionality not made in nZombies before?!?!?!)
	hook.Add("WeaponEquip", "NZGrenadeReplace", function(wep, owner)
        if (IsValid(owner) and IsValid(wep) and wep:IsSpecial()) then
			for _,itemType in pairs(nzSpecialWeapons:GetItemTypes()) do
				local theItems = nzSpecialWeapons:GetItems(itemType)
				if (istable(theItems) and theItems[wep:GetClass()]) then
					for _,item in pairs(theItems) do
						if (istable(item)) then
							local itemClass = item.class
							if (itemClass and wep:GetClass() != itemClass and owner:HasWeapon(itemClass)) then 
                                --owner:StripWeapon(itemClass)
							    -- Because Source 1 is shit, we must add yet another loop to remove all weapon classes ourselves 
                                -- (There is a weird issue where StripWeapon doesn't fully remove the weapon, causing issues like no knife after buying bowie knife)
                                for _,equippedWep in pairs(owner:GetWeapons()) do 
                                    if equippedWep:GetClass() == itemClass then 
                                        equippedWep:Remove()
                                    end
                                end 
                            end
						end
					end
				end
			end
		end
	end)

	-- Track/remember the ammunition of every weapon the player uses
	hook.Add("WeaponEquip", "NZTrackAllWeapons", function(wep, owner)
		timer.Simple(0.1, function()
			if IsValid(wep) and IsValid(owner) and !wep:IsSpecial() then
				nzWeps:TrackAmmo(owner, wep:GetClass())
			end
		end)
	end)

	-- Do NOT allow replacement variants of already equipped weapons to be picked up!
	hook.Add("PlayerCanPickupWeapon", "NZDenyDuplicateWeapons", function(ply, wep)
		if IsValid(wep) and ply:HasWeapon(wep:GetClass(), true) then return false end
	end)


	-- hook.Add("DecideBoxWeapons", "NZDenyDuplicateBoxWeapons", function(ply, guns)
	-- 	PrintTable(guns)
	-- end)

	--nzWeps:TrackSpecialAmmo(ply)

	-- Now handled in default weapon modifiers

	--[[function ReplaceReloadFunction(wep)
		-- Either not a weapon, doesn't have a reload function, or is FAS2
		if wep:NZPerkSpecialTreatment() then return end
		local oldreload = wep.Reload
		if !oldreload then return end

		--print("Weapon reload modified")

		wep.Reload = function( self, ... )
			if self.ReloadFinish and self.ReloadFinish > CurTime() then return end
			local ply = self.Owner
			if ply:HasPerk("speed") then
				--print("Hasd perk")
				local cur = self:Clip1()
				if cur >= self:GetMaxClip1() then return end
				local give = self:GetMaxClip1() - cur
				if give > ply:GetAmmoCount(self:GetPrimaryAmmoType()) then
					give = ply:GetAmmoCount(self:GetPrimaryAmmoType())
				end
				if give <= 0 then return end
				--print(give)

				self:SendWeaponAnim(ACT_VM_RELOAD)
				oldreload(self, ...)
				local rtime = self:SequenceDuration(self:SelectWeightedSequence(ACT_VM_RELOAD))/2
				self:SetPlaybackRate(2)
				ply:GetViewModel():SetPlaybackRate(2)

				local nexttime = CurTime() + rtime

				self:SetNextPrimaryFire(nexttime)
				self:SetNextSecondaryFire(nexttime)
				self.ReloadFinish = nexttime

				timer.Simple(rtime, function()
					if IsValid(self) and ply:GetActiveWeapon() == self then
						self:SetPlaybackRate(1)
						ply:GetViewModel():SetPlaybackRate(1)
						self:SendWeaponAnim(ACT_VM_IDLE)
						self:SetClip1(give + cur)
						ply:RemoveAmmo(give, self:GetPrimaryAmmoType())
						self:SetNextPrimaryFire(0)
						self:SetNextSecondaryFire(0)
					end
				end)
			else
				oldreload(self, ...)
			end
		end
	end
	hook.Add("WeaponEquip", "nzModifyWeaponReloads", ReplaceReloadFunction)

	function ReplacePrimaryFireCooldown(wep)
		local oldfire = wep.PrimaryAttack
		if !oldfire then return end

		--print("Weapon fire modified")

		wep.PrimaryAttack = function(...)
			oldfire(wep, ...)

			-- FAS2 weapons have built-in DTap functionality
			if wep:IsFAS2() then return end
			-- With double tap, reduce the delay for next primary fire to 2/3
			if wep.Owner:HasPerk("dtap") or wep.Owner:HasPerk("dtap2") then
				local delay = (wep:GetNextPrimaryFire() - CurTime())*0.80
				wep:SetNextPrimaryFire(CurTime() + delay)
			end
		end
	end
	hook.Add("WeaponEquip", "nzModifyWeaponNextFires", ReplacePrimaryFireCooldown)]]

	-- function ReplaceAimDownSight(wep)
	-- 	local oldfire = wep.SecondaryAttack
	-- 	if !oldfire then return end
	--
	-- 	--print("Weapon fire modified")
	--
	-- 	-- wep.SecondaryAttack = function(...)
	-- 	-- 	oldfire(wep, ...)
	-- 	-- 	-- With deadshot, aim at the head of the entity aimed at
	-- 	-- 	if wep.Owner:HasPerk("deadshot") then
	-- 	-- 		local tr = wep.Owner:GetEyeTrace()
	-- 	-- 		local ent = tr.Entity
	-- 	-- 		if IsValid(ent) and nzConfig.ValidEnemies[ent:GetClass()] then
	-- 	-- 			local head = ent:LookupBone("ValveBiped.Bip01_Neck1")
	-- 	-- 			if head and isnumber(wep.Owner.lastHeadTime) and CurTime() - 3 > wep.Owner.lastHeadTime then
	-- 	-- 				local headpos,headang = ent:GetBonePosition(head)
	-- 	-- 				wep.Owner:SetEyeAngles((headpos - wep.Owner:GetShootPos()):Angle())
	-- 	-- 			end
	-- 	-- 		end
	-- 	-- 	end
	-- 	-- end
	-- end
	-- hook.Add("WeaponEquip", "nzModifyAimDownSights", ReplaceAimDownSight)

	hook.Add("KeyPress", "nzReloadCherry", function(ply, key) -- Improved Electric Cherry by: Ethorbit
		if key == IN_RELOAD then
			if ply:HasPerk("cherry") then
				local wep = ply:GetActiveWeapon()
				local ammocount = wep:GetPrimaryAmmoType()

				if IsValid(wep) and !wep.CherryReloaded and wep:Clip1() < wep:GetMaxClip1() and ply:GetAmmoCount(ammocount) > 1 then
					local pct = 1 - (wep:Clip1()/wep:GetMaxClip1())
					local pos, ang = ply:GetPos() + ply:GetAimVector()*10 + Vector(0,0,50), ply:GetAimVector()
					nzEffects:Tesla( {
						pos = ply:GetPos() + Vector(0,0,50),
						ent = ply,
						turnOn = true,
						dieTime = 1,
						lifetimeMin = 0.05*pct,
						lifetimeMax = 0.1*pct,
						intervalMin = 0.01,
						intervalMax = 0.02,
					})
					--print(pct)
					local zombies = ents.FindInSphere(ply:GetPos(), 250*pct)
					local d = DamageInfo()
					d:SetDamage( 500*pct )
					d:SetDamageType( DMG_SHOCK )
					d:SetAttacker(ply)
					d:SetInflictor(ply)

					for k,v in pairs(zombies) do
						if v.Type == "nextbot" and !v.NZBoss and v:Health() > 0 then
							v:TakeDamageInfo(d)

							if (v:Health() > 0) then
								v:ApplyWebFreeze(3*pct)
							end
						end
					end

					-- Stop them from cherry reload spamming (Wait for successful reload before allowing again):
					wep.CherryReloaded = true
					if (!wep.HandledCherryFunc) then
						wep.HandledCherryFunc = true

						local oldReload = wep.CompleteReload
						wep.CompleteReload = function(...)
							if (IsValid(wep:GetOwner())) then
								--wep:GetOwner().CherryReloaded = false
								wep.CherryReloaded = false
							end
							oldReload(wep, ...)
						end
					end
				end
			end
		end
	end)

	-- hook.Add("DoAnimationEvent", "nzReloadCherry", function(ply, event, data)
	-- 	--print(ply, event, data)
	-- 	if event == PLAYERANIMEVENT_RELOAD then
	-- 		if ply:HasPerk("cherry") then
	-- 			local wep = ply:GetActiveWeapon()
	-- 			if IsValid(wep) and !wep.CherryReloaded and wep:Clip1() < wep:GetMaxClip1() then
	-- 				local pct = 1 - (wep:Clip1()/wep:GetMaxClip1())
	-- 				local pos, ang = ply:GetPos() + ply:GetAimVector()*10 + Vector(0,0,50), ply:GetAimVector()
	-- 				nzEffects:Tesla( {
	-- 					pos = ply:GetPos() + Vector(0,0,50),
	-- 					ent = ply,
	-- 					turnOn = true,
	-- 					dieTime = 1,
	-- 					lifetimeMin = 0.05*pct,
	-- 					lifetimeMax = 0.1*pct,
	-- 					intervalMin = 0.01,
	-- 					intervalMax = 0.02,
	-- 				})
	-- 				--print(pct)
	-- 				local zombies = ents.FindInSphere(ply:GetPos(), 250*pct)
	-- 				local d = DamageInfo()
	-- 				d:SetDamage( 500*pct )
	-- 				d:SetDamageType( DMG_SHOCK )
	-- 				d:SetAttacker(ply)
	-- 				d:SetInflictor(ply)

	-- 				for k,v in pairs(zombies) do
	-- 					if nzConfig.ValidEnemies[v:GetClass()] and v:Health() > 0 then
	-- 						v:TakeDamageInfo(d)

	-- 						if (v:Health() > 0) then
	-- 							v:ApplyWebFreeze(3*pct)
	-- 						end
	-- 					end
	-- 				end

	-- 				-- Stop them from cherry reload spamming (Wait for successful reload before allowing again):
	-- 				wep.CherryReloaded = true
	-- 				if (!wep.HandledCherryFunc) then
	-- 					wep.HandledCherryFunc = true

	-- 					local oldReload = wep.CompleteReload
	-- 					wep.CompleteReload = function(...)
	-- 						if (IsValid(wep:GetOwner())) then
	-- 							--wep:GetOwner().CherryReloaded = false
	-- 							wep.CherryReloaded = false
	-- 						end
	-- 						oldReload(wep, ...)
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end)

	--[[---------------------------------------------------------
	Name: gamemode:ScaleNPCDamage( ply, hitgroup, dmginfo )
	Desc: Scale the damage based on being shot in a hitbox
	-----------------------------------------------------------]]
	function GM:ScaleNPCDamage( npc, hitgroup, dmginfo ) -- Overrided by: Ethorbit (Seems like none of the devs knew about this gmod hook nextbots call under the hood and neither did I, it was a lucky discovery)
	end

	function GM:GetFallDamage( ply, speed )
		local dmg = speed / 10
		if ply:HasPerk("phd") and dmg >= 50 then
			--if ply:Crouching() then
				local zombies = ents.FindInSphere(ply:GetPos(), 250)
				for k,v in pairs(zombies) do
					if (v:IsNextBot() or v:IsNPC()) and v:Health() > 0 then
						local dmg = DamageInfo()
						dmg:SetDamage(345)
						dmg:SetDamageType(DMG_BLAST)

						v:TakeDamageInfo(dmg)
					end
				end

				local pos = ply:GetPos()
				local effectdata = EffectData()
				effectdata:SetOrigin( pos )

				timer.Simple(0, function()
					if IsValid(ply) then
						util.Effect( "HelicopterMegaBomb", effectdata )
					end
				end)

				ply:EmitSound("phx/explode0"..math.random(0, 6)..".wav")
			--end
			return 0
		end
		return ( dmg )
	end

	--local oldsetwep = playerMeta.SetActiveWeapon
	-- hook.Add("PlayerSwitchWeapon", "FixFistsNZ", function(ply, oldwep, newwep)
	-- 	if IsValid(newwep) and !newwep:IsSpecial() and newwep:GetClass() != "weapon_fists" then -- They don't need it anymore! If we leave it, it might replace one of their weapons!!
	-- 		ply:StripWeapon("weapon_fists")
	-- 	end
	-- end)

	-- function playerMeta:SetActiveWeapon(wep)
	-- 	timer.Simple(0.5, function()
	-- 		--if !IsValid(self) || IsValid(self.WhosWhoClone) then return end -- Or else the starting pistol may get replaced
	-- 		local wepCount = 0
	-- 		for k,v in pairs(self:GetWeapons()) do
	-- 			if (!v:IsSpecial()) then
	-- 				wepCount = wepCount + 1
	-- 			end
	-- 		end

	-- 		-- Character breaks when selecting an invalid weapon slot, when this
	-- 		-- happens they will not be able to interact with anything anymore
	-- 		-- the fix is to make sure they always have 2 valid weapons at all
	-- 		-- times so that the possibility of selecting an invalid weapon is
	-- 		-- next to none
	-- 		if (wepCount == 0) then
	-- 			self:Give("weapon_fists")
	-- 			self:SelectWeapon("weapon_fists")
	-- 		end
	-- 	end)

	-- local oldsetwep = playerMeta.SetActiveWeapon
	-- function playerMeta:SetActiveWeapon(wep)
	-- 	local oldwep = self:GetActiveWeapon()
	-- 	print(oldwep)
	-- 	if IsValid(oldwep) and !oldwep:IsSpecial() then
	-- 		self.NZPrevWep = oldwep
	-- 	end
	-- 	oldsetwep(self, wep)
	-- end

	-- The above solution is not so good, it's slow and can save the current weapon
	-- as your last weapon causing the incorrect weapon to be switched to after
	-- reviving someone or using perk machines.

	-- Plus, why override a function when it's not necessary to?
	-- That should always be a last resort.
else
	-- Custom FOV and Draw Distance
	local CustomFOV = GetConVar("nz_custom_fov")
	local EnableCustomFOV = GetConVar("nz_custom_fov_enabled")
	local DrawDistance = CreateConVar("nz_draw_distance", -1, {FCVAR_USERINFO, FCVAR_ARCHIVE}, "Sets the max distance the world can render.")
	local Default_FOV = GetConVar("default_fov")

	local view = {origin = vector_origin, angles = angle_zero, fov=0, zdraw=-1}
	function GM:CalcView( ply, origin, angles, fov, znear, zfar )
	   view.origin = origin
	   view.angles = angles
	   view.fov    = fov
	   view.znear  = znear
	   view.zfar   = zfar

   		-- first person ragdolling
	   if ply:Team() == TEAM_SPEC and ply:GetObserverMode() == OBS_MODE_IN_EYE then
	      local tgt = ply:GetObserverTarget()
	      if IsValid(tgt) and (not tgt:IsPlayer()) then
	         -- assume if we are in_eye and not speccing a player, we spec a ragdoll
	         local eyes = tgt:LookupAttachment("eyes") or 0
	         eyes = tgt:GetAttachment(eyes)
	         if eyes then
	            view.origin = eyes.Pos
	            view.angles = eyes.Ang
	         end
	      end
	   end

	   local wep = ply:GetActiveWeapon()
	   if IsValid(wep) then
	      local func = wep.CalcView
	      if func then
	         view.origin, view.angles, view.fov = func( wep, ply, origin*1, angles*1, fov )
	      end
	   end

	   local allow_custom_fov = EnableCustomFOV != nil and EnableCustomFOV:GetBool()

	   if (CustomFOV and Default_FOV) then
		   -- Custom FOV
		   if allow_custom_fov then
			   local newFov = math.Clamp(ply:GetFOV() + CustomFOV:GetFloat() - Default_FOV:GetFloat(), 0, CustomFOV:GetFloat())
			   view.fov = CustomFOV != nil and newFov or fov
		   end
	   end

	   local new_zfar = (DrawDistance != nil and DrawDistance:GetFloat() > 0.0) and DrawDistance:GetFloat() or view.zfar
	   if new_zfar < view.zfar then
		   view.zfar = new_zfar
	   end

	   return view
	end

	-- Auto weapon reloading
	local autoReload = GetConVar("nz_weapon_auto_reload")
	hook.Add("CreateMove", "NZAutoReload", function(cmd)
		local wep = LocalPlayer():GetActiveWeapon()
		if (IsValid(wep)) then
			local clip = wep:Clip1()
			if (isnumber(clip) and clip - 1 < 0) then -- Fired last shot
				if (isfunction(wep.GetStatus) and isnumber(wep:GetStatus()) and wep:GetStatus() == 5) then return end -- Already reloading
				if (isfunction(wep.Ammo1) and wep:Ammo1() == 0) then return end -- Can't reload, there's no ammo!
				if (wep.Primary and (!wep.Primary.ClipSize or isnumber(wep.Primary.ClipSize) and wep.Primary.ClipSize <= 0)) then return end -- We don't need to ever reload this
				if autoReload:GetBool() then -- Auto Reload option enabled
					cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_RELOAD))
				end
			end
		end
	end)

	-- local function OverrideTheCalcView()
	--     if GAMEMODE and isfunction(GAMEMODE.CalcView) then
	--         local OldCalcView = !isfunction(OldCalcView) and GAMEMODE.CalcView or OldCalcView
	--
	--         function GAMEMODE.CalcView(me, ply, pos, angles, fov, znear, zfar)
	--             local allow_custom_fov = EnableCustomFOV != nil and EnableCustomFOV:GetInt() > 0
	--
	--             if (CustomFOV and Default_FOV) then
	--                 if allow_custom_fov then
	--                     local newFov = math.Clamp(ply:GetFOV() + CustomFOV:GetFloat() - Default_FOV:GetFloat(), 0, CustomFOV:GetFloat())
	--                     fov = CustomFOV != nil and newFov or fov
	--                 end
	--
	--                 zfar = (DrawDistance != nil and DrawDistance:GetFloat() > 0.0) and DrawDistance:GetFloat() or zfar
	--             end
	--
	--             if nzRevive and nzRevive.Players[LocalPlayer():EntIndex()] then
	--                 pos = pos + Vector(0,0,-15)
	--                 angles = angles + Angle(0,0,20)
	--             end
	--
	--             return OldCalcView(me, ply, pos, angles, fov, znear, zfar)
	--         end
	--
	--         hook.Remove("CalcView", "CalcDownedView")
	--     end
	-- end
	-- hook.Add("PostGamemodeLoaded", "OverrideCalcView", OverrideTheCalcView)
	-- OverrideTheCalcView()

	--[[ Manual speedup of the reload function on FAS2 weapons - seemed like the original solution broke along the way
	function ReplaceReloadFunction(wep)
		print(wep, "HUKDAHD1")
		if wep:IsFAS2() then
			print(wep, "HUKDAHD2")
			local oldreload = wep.Reload
			if !oldreload then return end
			print(wep, "HUKDAHD3")
			wep.Reload = function()
				print(wep, "HUKDAHD4")
				oldreload(wep)
				if LocalPlayer():HasPerk("speed") then
					wep.Wep:SetPlaybackRate(2)
				end
			end
			print(wep, "HUKDAHD5")
		end
	end
	hook.Add("HUDWeaponPickedUp", "ModifyFAS2WeaponReloads", ReplaceReloadFunction)]]

end

local olddefreload = wepMeta.DefaultReload
function wepMeta:DefaultReload(act)
	if IsValid(self.Owner) and self.Owner:HasPerk("speed") then return end
	olddefreload(self, act)
end

local ghosttraceentities = {
-- 	["wall_block"] = true,
-- 	["invis_wall"] = true,
-- 	["invis_damage_wall"] = true,
-- 	["invis_wall_zombie"] = true,
-- 	["wall_block_zombie"] = true,
	["func_breakable"] = true,
-- 	["player"] = true
}

function GM:EntityFireBullets(ent, data)
	-- Fire the PaP shooting sound if the weapon is PaP'd
	--print(wep, wep:HasNZModifier("pap"))
	if SERVER then
		if ent:IsPlayer() then
			local wep = ent:GetActiveWeapon()
			if IsValid(wep) and wep:HasNZModifier("pap") and !wep.NZOverridePaPFireSound and !wep.IsMelee and !wep.IsKnife then
				ent:EmitSound("NZ_PaP_Shoot_Sound")
			end
		end
	end

	local ents = {}
	local tr = util.TraceLine({
		start = data.Src,
		endpos = data.Src + (data.Dir*data.Distance),
		filter = function(ent2)
			if (ent2:IsPlayer()) then return false end
			return true
		end
	})

    -- If we're going to make the bullet skip it, at least damage it so if it's breakable, then it ya know.. BREAKS. /Ethorbit
	if SERVER and IsValid(tr.Entity) and ghosttraceentities[tr.Entity:GetClass()] then --and tr.Entity.dontbreak then
        local fakeDmg = DamageInfo()
		if (IsValid(ent:GetOwner())) then
			fakeDmg:SetAttacker(ent:GetOwner())
		else
			fakeDmg:SetAttacker(Entity(0))
		end

		fakeDmg:SetInflictor(ent)
		fakeDmg:SetDamage(data.Damage)
		fakeDmg:SetDamageForce(Vector(data.Force, data.Force, data.Force))
		fakeDmg:SetDamageType(DMG_BULLET)
		tr.Entity:TakeDamageInfo(fakeDmg)
	end

	local trIgnore = util.TraceLine({
		start = data.Src,
		endpos = data.Src + (data.Dir*data.Distance),
		filter = function(ent2)
			if ghosttraceentities[ent2:GetClass()] then
            --if !ent2.dontbreak and ghosttraceentities[ent2:GetClass()] then
--				if (SERVER) then
--					if (!ent2.dontbreak and ent2:GetClass() == "func_breakable") then
--                        local keyvals = ent2:GetKeyValues()
--					    if keyvals and keyvals.health and keyvals.health < 10000 and keyvals.damagefilter == "" and !ent2:HasSpawnFlags(1) then 
--                            --ent2:Remove()
--						    ent2:Fire("Break")
--                        end 
--					end
--				end

				ents = true
				return false
			else
				return true
			end
		end
	})

	-- if ents == true then
	-- 	if (!ent:IsPlayer()) then -- It's not a player firing the bullet, just skip anyways
	-- 		data.Src = trIgnore.HitPos - data.Dir * 5
	-- 	return true end

	-- 	-- It hit an invisible entity
	-- 	local wep = ent:GetActiveWeapon()

	-- 	if (IsValid(tr.Entity) and !tr.Entity.dontbreak or !IsValid(tr.Entity)) then
	-- 		if (IsValid(wep) and wep:IsWeapon() and !isstring(wep.TracerName) and data.TracerName == "Tracer") then -- For bullets, it's OK to always teleport to end
	-- 			data.Src = trIgnore.HitPos - data.Dir * 5
	-- 		elseif (IsValid(tr.Entity) and ghosttraceentities[tr.Entity:GetClass()] != nil) then -- For bullets with tracers however, we need to be sure, or the effect is always lost
	-- 			data.Src = trIgnore.HitPos - data.Dir * 5
	-- 		end
	-- 	elseif (IsValid(tr.Entity)) then -- For some reason bullets will still skip, so simulate damage
	-- 		local fakeDmg = DamageInfo()
	-- 		if (IsValid(ent:GetOwner())) then
	-- 			fakeDmg:SetAttacker(ent:GetOwner())
	-- 		else
	-- 			fakeDmg:SetAttacker(Entity(0))
	-- 		end

	-- 		fakeDmg:SetInflictor(ent)
	-- 		fakeDmg:SetDamage(data.Damage)
	-- 		fakeDmg:SetDamageForce(Vector(data.Force, data.Force, data.Force))
	-- 		fakeDmg:SetDamageType(DMG_BULLET)
	-- 		tr.Entity:TakeDamageInfo(fakeDmg)
	-- 		--hook.Call("EntityTakeDamage", nil, ent, )
	-- 	end

	-- 	--data.Attacker:SetPos(tr.HitPos)
	-- 	--data.Src = tr.HitPos - data.Dir * 5
	-- 	return true
	-- end

	-- Perform a trace that filters out entities from the table above
	--[[local tr = util.TraceLine({
		start = data.Src,
		endpos = data.Src + (data.Dir*data.Distance),
		filter = function(ent2)
			if ghosttraceentities[ent2:GetClass()] then
				return false
			else
				return true
			end
		end
	})

	--PrintTable(tr)

	-- If we hit anything, move the source of the bullets up to that point
	if IsValid(tr.Entity) and tr.Fraction < 1 then
		data.Src = tr.HitPos - data.Dir * 5
		return true
	end]]

	if ent:IsPlayer() and ent:HasPerk("dtap2") then return true end
end

-- Ghost invisible walls so nothing but players or NPCs collide with them
local inviswalls = {
	["invis_damage_wall"] = true,
	["invis_wall"] = true,
	["wall_block"] = true,
}
hook.Add("ShouldCollide", "nz_InvisibleBlockFilter", function(ent1, ent2)
	if inviswalls[ent1:GetClass()] then
		return ent2:IsPlayer() or ent2:IsNPC()
	elseif inviswalls[ent2:GetClass()] then
		return ent1:IsPlayer() or ent1:IsNPC()
	end
end)

-- This is so awkward ._.
-- game.AddAmmoType doesn't take duplicates into account and has a hardcoded limit of 128
-- which means our ammo types won't exist if we pass that limit with the countless duplicates :(
local oldaddammo = game.AddAmmoType
local alreadyexist = alreadyexist or {}
function game.AddAmmoType( tbl ) -- Let's prevent that!
	if tbl.name and !alreadyexist[tbl.name] then -- Only if the ammo doesn't already exist!
		oldaddammo(tbl) -- THEN we can proceed with normal procedure!
		alreadyexist[tbl.name] = true
	end
end

if SERVER then
	concommand.Add("gmod_admin_cleanup", function(ply, cmd, args) -- This is a no no
		if (nzRound:GetState() != ROUND_CREATE) then return end
		cleanup.CC_AdminCleanup(ply, cmd, args)
	end)
end
