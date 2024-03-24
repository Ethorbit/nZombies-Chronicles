-- File added by Ethorbit, this will be used for both the Creative AND play versions
-- of the player classes. Use sh_player_ingame or sh_player_creative instead if only
-- one of those is meant to have something!

local PLAYER = FindMetaTable("Player")
local oldHasWep = isfunction(oldHasWep) and oldHasWep or PLAYER.HasWeapon
local oldGetRunSpeed = isfunction(oldGetRunSpeed) and oldGetRunSpeed or PLAYER.GetRunSpeed
local oldGetWalkSpeed = isfunction(oldGetWalkSpeed) and oldGetWalkSpeed or PLAYER.GetWalkSpeed

--function PLAYER:GetSpawnerClass() -- no need to use anything else for now..
--    return "player_spawns"
--end

function PLAYER:SetSpawner(spawner)
    self.SpawnerEntity = spawner
end

function PLAYER:GetSpawner()
    return self.SpawnerEntity
end

-- New 'Saved' speeds because I got super tired of nZombies addons and gamemode functions
-- archiving and setting the player speeds themselves, fucking up and then permanently screwing
-- up the gameplay.

function PLAYER:GetRunSpeed(alias)
	if !alias then return oldGetRunSpeed(self) end
	if !self.tSavedRunSpeeds then self.tSavedRunSpeeds = {} end
	return self.tSavedRunSpeeds[alias]
end

function PLAYER:GetWalkSpeed(alias)
	if !alias then return oldGetWalkSpeed(self) end
	if !self.tSavedWalkSpeeds then self.tSavedWalkSpeeds = {} end
	return self.tSavedWalkSpeeds[alias]
end

local function network_new_speed(ply, alias, num, is_walk)
	net.Start("NZ_AddNewPlayerSpeed")
	net.WriteBool(is_walk)
	net.WriteString(alias)
	net.WriteInt(num, 15)
	net.Send(ply)
end

function PLAYER:AddWalkSpeed(alias, num)
	if !self.tSavedWalkSpeeds then self.tSavedWalkSpeeds = {} end
	self.tSavedWalkSpeeds[alias] = num

	if SERVER then
		network_new_speed(self, alias, num, true)
	end
end

function PLAYER:AddRunSpeed(alias, num)
	if !self.tSavedRunSpeeds then self.tSavedRunSpeeds = {} end
	self.tSavedRunSpeeds[alias] = num

	if SERVER then
		network_new_speed(self, alias, num, false)
	end
end

function PLAYER:GetDefaultWalkSpeed()
	return self:HasPerk("staminup") and self:GetWalkSpeed("staminup") or self:GetWalkSpeed("default") or 200
end

function PLAYER:GetDefaultRunSpeed()
	return self:HasPerk("staminup") and self:GetRunSpeed("staminup") or self:GetRunSpeed("default") or 300
end

function PLAYER:AddDefaultSpeeds()
	self:AddWalkSpeed("default", 200)
	self:AddRunSpeed("default", 300)

	-- Staminup Perk
	self:AddWalkSpeed("staminup", 230)
	self:AddRunSpeed("staminup", 350)

	-- When you're in a cloud of nova 6 gas
	self:AddWalkSpeed("novagas", 25)
	self:AddRunSpeed("novagas", 25)

	-- When you walk on mud
	self:AddWalkSpeed("mud", 100)
	self:AddRunSpeed("mud", 150)
end

------------------------------------------------------------------------

function PLAYER:IsTouchingNovaGas()
	local res = LocalPlayer().GetLastNovaGasTouch and LocalPlayer():GetLastNovaGasTouch()
	if !res then return false end

	return CurTime() - res <= 1.3
end

function PLAYER:CanUse() -- Whether the player can or can't purchase/use things
	if (!self:GetNotDowned() or (self:IsSpectating() and !self:IsInCreative())) then return false end
    if (IsValid(self:GetTeleporterEntity())) then return false end

	local wep = self:GetActiveWeapon()
	if IsValid(wep) and wep:IsSpecial() then return false end

	return true
end

-- Relying off of just Gmod's IsSuperAdmin is bad since some people use ULX
-- This function should make the process simpler.
function PLAYER:IsNZAdmin()
	 return (self:IsSuperAdmin() or self:GetUserGroup() == "superadmin" or self:GetUserGroup() == "admin")
end

-- Sets player to their NZ spawn position (not map spawn)
function PLAYER:MoveToSpawn()
    local spawn = nzRound:GetPlayerSpawn(self)
    local spawnPos = IsValid(spawn) and spawn:GetPos() or nil
    if spawnPos then
        self:SetPos(spawnPos)
        if self:GetPos() == spawnPos then return end -- Source let us do this. Yay!
    
        -- Source is being a motherfucker and now we take drastic measures.
        -- (Below should basically NEVER run, but it's never a bad idea to have a fallback)
        local giveUpTime = CurTime() + 5
        local co = coroutine.create(function()
            while CurTime() < giveUpTime do
                if self:GetPos() != spawnPos then
                    self:SetPos(spawnPos)
                else
                    break
                end

                coroutine.yield()
            end
        end)

        coroutine.resume(co)
    else
        ServerLog("No spawn set for player: " .. self:Nick() .. "\n")
    end
end

-- HasWeapon from Garry's Mod works great! However, it doesn't know that a replaceable version
-- of a weapon is the same as the original weapon, so we do need to add that logic in ourselves
function PLAYER:HasWeapon(class, checkReplacements)
	if !checkReplacements then return oldHasWep(self, class) end -- Whoever called this function did not specifically want to catch upgraded/downgraded versions, just run the original meta func

	-- Caller wants to detect upgraded/downgraded versions too:
	local wep_class = !isentity(class) and class or class:GetClass()

	if wep_class then
		local hasWep = oldHasWep(self, class)
		if hasWep then -- Well if they literally have the same weapon, then we're already done
			return hasWep
		elseif nzWeps then -- However, now it's either really not the same weapon, or it could be an upgraded/downgraded version of the weapon
			-- The weapon has upgrades, for every upgraded class use the old HasWeapon meta function to check if the player has it:
			for _,upgraded_class in pairs(nzWeps:GetAllOtherVariants(wep_class)) do
				if oldHasWep(self, upgraded_class) then return true end
			end
		end
	end

	return false
end
