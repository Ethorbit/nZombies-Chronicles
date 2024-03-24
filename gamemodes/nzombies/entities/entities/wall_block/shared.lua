AddCSLuaFile( )
ENT.Base = "prop_buys" -- prop_buys are purchaseable props and this is an invisible prop, let's combine the functionality!

ENT.Type = "anim"

ENT.PrintName		= "wall_block"
ENT.Author			= "Alig96 & Zet0r"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.NZOnlyVisibleInCreative = true

ENT.NZEntity = true

--[[function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "BlockPlayers")
	self:NetworkVar("Bool", 1, "BlockZombies")
end

function ENT:SetFilter(players, zombies)
	if players and zombies then
		self:SetBlockPlayers(true)
		self:SetBlockZombies(true)
		self:SetCustomCollisionCheck(false)
		self:SetColor(Color(255,255,255))
	elseif players and !zombies then
		self:SetBlockPlayers(true)
		self:SetBlockZombies(false)
		self:SetCustomCollisionCheck(true)
		self:SetColor(Color(100,100,255))
	elseif !players and zombies then
		self:SetBlockPlayers(false)
		self:SetBlockZombies(true)
		self:SetCustomCollisionCheck(true)
		self:SetColor(Color(255,100,100))
	end
end]]

local ignoreClasses = {
	"invis_wall", 
	"invis_wall_zombie",
	"wall_block",
	"wall_block_zombie"
}

function ENT:Use(Activator, Caller, UseType, Integer)
	local ent
	local tr = util.TraceLine({
		start = Activator:EyePos(),
		endpos = Activator:EyePos() + Activator:GetAimVector()*150,
		filter = function(ent2) if ent2 != Activator and !table.HasValue(ignoreClasses, ent2:GetClass()) then ent = ent2 end end,
		ignoreworld = true
	})

	if IsValid(ent) and !isnumber(Activator.lastInvisUseTime) or IsValid(ent) and isnumber(Activator.lastInvisUseTime) and CurTime() > Activator.lastInvisUseTime
	and ent:GetClass() != "invis_wall" 
	and ent:GetClass() != "invis_wall_zombie"
	and ent:GetClass() != "wall_block"
	and ent:GetClass() != "wall_block_zombie"
	and ent:GetClass() != "power_box" then
		if (ent:GetClass() == "easter_egg") then
			Activator.lastInvisUseTime = CurTime() + 1
			ent:Use(Activator, Caller, UseType, Integer)
		end
	end
end


--function ENT:Use(Activator, Caller, UseType, Integer)
	-- local ent
	-- local tr = util.TraceLine({
	-- 	start = Activator:EyePos(),
	-- 	endpos = Activator:EyePos() + Activator:GetAimVector()*150,
	-- 	filter = function(ent2) if ent2 != Activator and !table.HasValue(ignoreClasses, ent2:GetClass()) then ent = ent2 end end,
	-- 	ignoreworld = true
	-- })

	-- if IsValid(ent) and !isnumber(Activator.lastInvisUseTime) or IsValid(ent) and isnumber(Activator.lastInvisUseTime) and CurTime() > Activator.lastInvisUseTime
	-- and ent:GetClass() != "invis_wall" 
	-- and ent:GetClass() != "invis_wall_zombie"
	-- and ent:GetClass() != "wall_block"
	-- and ent:GetClass() != "wall_block_zombie"
	-- and ent:GetClass() != "power_box" then
	-- 	if (ent:GetClass() == "perk_machine" and nzPerks) then
	-- 		local data = nzPerks:Get(ent:GetPerkID())
	-- 		if (data.name == "Pack-a-Punch") then return end
	-- 	end

	-- 	Activator.lastInvisUseTime = CurTime() + 1
	-- 	ent:Use(Activator, Caller, UseType, Integer)
	-- end
--end

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow( false )
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	self:SetCustomCollisionCheck(true)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end
	
	-- YES! Finally found a way to make bullets pass through without disabling solidity!
	--self:AddSolidFlags(FSOLID_CUSTOMRAYTEST)
	--self:AddSolidFlags(FSOLID_CUSTOMBOXTEST)
	
end

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end
end