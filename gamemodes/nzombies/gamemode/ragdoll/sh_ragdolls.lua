-- Made by Ethorbit after discovering the serverside BecomeRagdoll is
-- the main cause for crashes involving weapons.

-- The idea here is to give a small easy to use libary
-- for creating optimized, flexible, clientside-only
-- ragdolls, and being able to call it from anywhere
-- (server or client).

-- Convars are defined in config/sh_constructor

nzRagdolls = nzRagdolls or {}
nzRagdolls.Ragdolls = nzRagdolls.Ragdolls or {} -- Existing ragdolls
nzRagdolls.LastSpawn = nzRagdolls.LastSpawn or 0
nzRagdolls.FadeTime = nzRagdolls.FadeTime or GetConVar("nz_ragdollremovetime"):GetFloat()

if SERVER then
	util.AddNetworkString("nZombiesClientBecomeRagdoll")
	util.AddNetworkString("nZombiesClientNewRagdoll")
end

if CLIENT then
	net.Receive("nZombiesClientBecomeRagdoll", function()
		nzRagdolls.CreateFromEntity(net.ReadEntity(), net.ReadTable(), net.ReadTable(), net.ReadTable())
	end)

	net.Receive("nZombiesClientNewRagdoll", function()
		nzRagdolls.Create(net.ReadString(), net.ReadVector(), net.ReadTable(), net.ReadTable(), net.ReadTable())
	end)
end

local function do_post_ragdoll_creation_stuff(ragdoll, wasEntity) -- Common things we do after we create a ragdoll
	nzRagdolls.LastSpawn = CurTime()
	hook.Run("OnNZCreatedRagdoll", ragdoll, wasEntity)
end

function nzRagdolls.CreateFromEntity(ent, dmginfo, bodygroups, emitsoundinfo) -- Turns an existing entity into a ragdoll, makes it happen clientside
	local damageinfo = nzRagdolls.GetDamageTableFromDamageInfo(dmginfo)

	if SERVER then
		net.Start("nZombiesClientBecomeRagdoll")
		net.WriteEntity(ent)
		net.WriteTable(damageinfo)
		net.WriteTable(bodygroups or nzRagdolls.GetBodyGroupTableFromEntity(ent))
		net.WriteTable(emitsoundinfo or {})
		net.Broadcast()
	end

	if CLIENT then
		if !IsValid(ent) or ent:Health() <= 0 then return end
		nzRagdolls.RemoveExtra()

		local ragdoll = ent:BecomeRagdollOnClient()

		if table.Count(emitsoundinfo) > 0 then
			nzRagdolls.EmitSound(ragdoll, emitsoundinfo)
		end

		nzRagdolls.Ragdolls[#nzRagdolls.Ragdolls + 1] = ragdoll
		nzRagdolls.SetBodyGroups(ragdoll, bodygroups)
		nzRagdolls.Damage(ragdoll, damageinfo)

		do_post_ragdoll_creation_stuff(ragdoll, true)
	end
end

function nzRagdolls.Create(mdl, pos, dmginfo, bodygroups, emitsoundinfo) -- Creates a ragdoll somewhere, makes it happen clientside
	if !mdl or !pos then return end
	local damageinfo = nzRagdolls.GetDamageTableFromDamageInfo(dmginfo)

	if SERVER then
		pos = pos + Vector(0,0,10) -- don't get stuck inside floors and stuff..

		net.Start("nZombiesClientNewRagdoll")
		net.WriteString(mdl)
		net.WriteVector(pos)
		net.WriteTable(damageinfo)
		net.WriteTable(bodygroups or {})
		net.WriteTable(emitsoundinfo or {})
		net.Broadcast()
 	end

	if CLIENT then
		if !util.IsValidRagdoll(mdl) then print("[nZ] Tried to create a ragdoll with an invalid ragdoll model!", mdl) return end
		nzRagdolls.RemoveExtra()

		local ragdoll = ClientsideRagdoll(mdl)
		nzRagdolls.Ragdolls[#nzRagdolls.Ragdolls + 1] = ragdoll

		ragdoll:SetNoDraw(false)
		ragdoll:DrawShadow(true)

		if table.Count(emitsoundinfo) > 0 then
			nzRagdolls.EmitSound(ragdoll, emitsoundinfo)
		end

		nzRagdolls.SetPos(ragdoll, pos)
		nzRagdolls.SetBodyGroups(ragdoll, bodygroups)
		nzRagdolls.Damage(ragdoll, damageinfo)

		do_post_ragdoll_creation_stuff(ragdoll, false)
	end
end

function nzRagdolls.Get(index)
	return index and nzRagdolls.Ragdolls[index] or table.Copy(nzRagdolls.Ragdolls)
end

function nzRagdolls.GetLastCreated()
	return nzRagdolls.LastSpawn
end

function nzRagdolls.Remove(ragdoll) -- Removes a single ragdoll (NOTE: does not remove from the ragdolls table)
	if IsValid(ragdoll) then
		ragdoll:FadeOut(nzRagdolls.FadeTime)
		SafeRemoveEntityDelayed(ragdoll, nzRagdolls.FadeTime)
	end
end

function nzRagdolls.RemoveAll() -- Clear all existing ragdolls
	for index,ragdoll in pairs(nzRagdolls.Ragdolls) do
		nzRagdolls.Remove(ragdoll)

		if nzRagdolls[index] then
			table.remove(nzRagdolls.Ragdolls, index)
		end
	end
end

function nzRagdolls.RemoveExtra() -- Removes extra ragolls over the value of nz_maxragdolls
	local max_allowed = GetConVar("nz_maxragdolls"):GetInt()
	if max_allowed <= 0 then return end

	for index,ragdoll in ipairs(nzRagdolls.Ragdolls) do
		-- Remove invalid ragdolls
		if (!IsValid(ragdoll)) then
			nzRagdolls.Remove(ragdoll)
			table.remove(nzRagdolls.Ragdolls, index)
		end

		-- Remove older ragdolls
		if #nzRagdolls.Ragdolls >= max_allowed and index < max_allowed then
			nzRagdolls.Remove(ragdoll)

			if nzRagdolls.Ragdolls[index] then
				table.remove(nzRagdolls.Ragdolls, index)
			end
		end
	end
end

function nzRagdolls.Damage(ragdoll, damageinfo_tbl) -- Apply damage to a ragdoll, which will change up its physics accordingly
	if !IsValid(ragdoll) or !damageinfo_tbl then return end

	for i = 0, ragdoll:GetPhysicsObjectCount() do
		local phys = ragdoll:GetPhysicsObjectNum(i)

		if IsValid(phys) then
			--phys:SetMass(phys:GetMass() / 2)
			phys:SetVelocity(damageinfo_tbl.force)
		end
	end

	ragdoll:SetVelocity(damageinfo_tbl.force)
end

function nzRagdolls.GetDamageTableFromDamageInfo(dmginfo) -- Converts a DamageInfo to a table compatible with nzRagdolls.Damage
	if istable(dmginfo) then
		return dmginfo
	end

	if type(dmginfo) != "CTakeDamageInfo" then return end

	return {
		["damage"] = dmginfo:GetDamage(),
		["type"] = dmginfo:GetDamageType(),
		["force"] = dmginfo:GetDamageForce(),
		["pos"] = dmginfo:GetDamagePosition()
	}
end

function nzRagdolls.SetPos(ragdoll, pos) -- Just SetPos, but runs on all its physics objects too (which is required to properly move it)
	if !IsValid(ragdoll) or !pos then return end

	ragdoll:SetPos(pos)

	for i = 0, ragdoll:GetPhysicsObjectCount() do
		local phys = ragdoll:GetPhysicsObjectNum(i)

		if IsValid(phys) then
			phys:SetPos(pos)
		end
	end
end

function nzRagdolls.SetBodyGroups(ragdoll, bodygroup_tbl) -- Sets bodygroups to a ragdoll, table provided MUST be structured like: {[id] = val}
	if !IsValid(ragdoll) then return end

	for id, val in pairs(bodygroup_tbl) do
		ragdoll:SetBodygroup(id, val)
	end
end

function nzRagdolls.GetBodyGroupTableFromEntity(ent) -- Turns an entity's bodygroups into a table structure compatible with nzRagdolls.SetBodyGroups ^^^
	if !IsValid(ent) then return {} end

	local tbl = {}

	for _,v in pairs(ent:GetBodyGroups()) do
		local id = ent:FindBodygroupByName(v.name)

		if id != -1 then
			tbl[id] = ent:GetBodygroup(id)
		end
	end

	return tbl
end

function nzRagdolls.EmitSound(ragdoll, emitsoundinfo) -- Emits a sound on a ragdoll from a provided emitsoundinfo table (https://wiki.facepunch.com/gmod/Structures/EmitSoundInfo)
	if !IsValid(ragdoll) then return end
	ragdoll:EmitSound(emitsoundinfo.SoundName, emitsoundinfo.SoundLevel or 75, emitsoundinfo.Pitch or 100, emitsoundinfo.Volume or 1, emitsoundinfo.Channel or CHAN_AUTO)
end

cvars.RemoveChangeCallback("nz_maxragdolls", "nZombiesMaxRagdollsCvarListener")
cvars.AddChangeCallback("nz_maxragdolls", function(name, old_val, new_val)
	if old_val != new_val then
		nzRagdolls.RemoveAll()
	end
end, "nZombiesMaxRagdollsCvarListener")

cvars.RemoveChangeCallback("nz_ragdollremovetime", "nZombiesRagdollFadeTimeCvarListener")
cvars.AddChangeCallback("nz_ragdollremovetime", function(name, old_val, new_val)
	if old_val != new_val then
		nzRagdolls.FadeTime = new_val
	end
end, "nZombiesRagdollFadeTimeCvarListener")
