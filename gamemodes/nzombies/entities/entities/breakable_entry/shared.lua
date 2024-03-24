AddCSLuaFile( )

ENT.Type = "anim"

ENT.PrintName		= "breakable_entry"
ENT.Author			= "Alig96, Chtidino, Ethorbit"
ENT.Contact			= "Don't"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.NZOnlyVisibleInCreative = true
ENT.Classic = false
ENT.PlankPositions = {}
ENT.ZombiesTearingDown = {}

ENT.NZEntity = true

-- models/props_interiors/elevatorshaft_door01a.mdl
-- models/props_debris/wood_board02a.mdl
function ENT:Initialize()
	self.max_zombies_var = GetConVar("nz_difficulty_barricade_max_zombies")
	self.max_planks_var = GetConVar("nz_difficulty_barricade_planks_max")
	self.points_var = GetConVar("nz_difficulty_barricade_points")

	if !self:GetHasPlanks() then 
		self.NoPlanks = true
	end

	local classicVar = GetConVar("nz_barricade_classic")
	if classicVar then
		self.Classic = classicVar:GetInt() > 0

		if (!self.Classic) then
			if (self:GetTriggerJumps()) then -- This is jumpable, keep the planks as high as they are in COD
				self.PlankPositions = {
					[6] = {
						pos = Vector(2.5, 0, 45),
						ang = Angle(0, 0, 100)
					},	
					[5] = {
						pos = Vector(-2.5, 0, 23), 
						ang = Angle(0, 0, 93) 
					},
					[4] = {
						pos = Vector(0, 15, 25), 
						ang = Angle(0, 0, 10) 
					},
					[3] = {
						pos = Vector(0, -15, 25), 
						ang = Angle(0, 0, -10)
					},
					[2] = {
						pos = Vector(-2.5, 0, 35), 
						ang = Angle(0, 0, 85) 
					},
					[1] = {
						pos = Vector(-2.5, 0, 0), 
						ang = Angle(0, 0, 80) 
					}
				}
			else -- These below aren't jumpable which likely means there's nothing under the barricade so lower the planks:
				self.PlankPositions = {
					[6] = {
						pos = Vector(2.5, 0, 30),
						ang = Angle(0, 0, 100)
					},	
					[5] = {
						pos = Vector(-2.5, 0, 8), 
						ang = Angle(0, 0, 93) 
					},
					[4] = {
						pos = Vector(0, 15, 10), 
						ang = Angle(0, 0, 10) 
					},
					[3] = {
						pos = Vector(0, -15, 10), 
						ang = Angle(0, 0, -10)
					},
					[2] = {
						pos = Vector(-2.5, 0, 20), 
						ang = Angle(0, 0, 85) 
					},
					[1] = {
						pos = Vector(-2.5, 0, -15), 
						ang = Angle(0, 0, 80) 
					}
				}
			end

			local originalCount = #self.PlankPositions
			while (#self.PlankPositions < self:GetMaxAllowedPlanks() and #self.PlankPositions > 0) do
				for i = 1, originalCount do
					self.PlankPositions[#self.PlankPositions + 1] = self.PlankPositions[i]
				end
			end
		end
	end

	self:SetModel("models/props_c17/fence01b.mdl")
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )

	--self:SetHealth(0)
	self:SetCustomCollisionCheck(true)
	self.NextPlank = CurTime()

	self.Planks = {}

	if SERVER then
		self:ResetPlanks(true)
	end
end

function ENT:GetPoints()
	return self.points_var and self.points_var:GetInt() or 10
end

function ENT:GetMaxAllowedZombies()
	return self.max_zombies_var and self.max_zombies_var:GetInt() or 3
end

function ENT:GetMaxAllowedPlanks()
	return self.max_planks_var and self.max_planks_var:GetInt() or 6
end

function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "NumPlanks" )
	self:NetworkVar( "Bool", 0, "HasPlanks" )
	self:NetworkVar( "Bool", 1, "TriggerJumps" )

end

function ENT:AddPlank(nosound)
	if !self:GetHasPlanks() then 
		self.NoPlanks = true
	return end

	self:SpawnPlank()
	self:SetNumPlanks( (self:GetNumPlanks() or 0) + 1 )
	if !nosound then
		self:EmitSound("nzr/effects/board_slam_0"..math.random(0,5)..".wav")
	end

	if (self:GetNumPlanks() > 0) then
		self.NoPlanks = false
	end
end

function ENT:RemovePlank(number)
        number = number or 1

	for i = 1,number do 
		local plank
		if (!self.Classic) then
			plank = self.Planks[self:GetNumPlanks()] -- In COD they are removed in order every time
		else
			plank = table.Random(self.Planks)
		end
	
		--if !IsValid(plank) and plank != nil then -- Not valid but not nil (NULL)
			if (plank == nil) then
				return
			elseif !IsValid(plank) then -- Not valid but not nil (NULL)
				table.RemoveByValue(self.Planks, plank) -- Remove it from the table
				self:RemovePlank() -- and try again
			end
	
			-- table.RemoveByValue(self.Planks, plank) -- Remove it from the table
			-- self:RemovePlank() -- and try again
		--end
		
		if IsValid(plank) then
			-- Drop off
			plank:SetParent(nil)
			plank:PhysicsInit(SOLID_VPHYSICS)
			local entphys = plank:GetPhysicsObject()
			if entphys:IsValid() then
				 entphys:EnableGravity(true)
				 entphys:Wake()
			end
			plank:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			-- Remove
			timer.Simple(2, function() if IsValid(plank) then plank:Remove() end end)
		end
		
		table.RemoveByValue(self.Planks, plank)
		self:SetNumPlanks( self:GetNumPlanks() - 1 )
		if (self:GetNumPlanks() == 0) then
			self.NoPlanks = true
			break
		end
	end 

end

function ENT:RemoveAllPlanks()
	for i=1, table.Count(self.Planks) do
		self:RemovePlank()
	end
end

function ENT:ResetPlanks(nosoundoverride)
	self:RemoveAllPlanks()
	self.Planks = {}
	self:SetNumPlanks(0)
	if self:GetHasPlanks() then
		for i=1, self:GetMaxAllowedPlanks() do
			self:AddPlank(!nosoundoverride)
		end
	end
end

function ENT:Use( activator, caller )
	activator.LastBarricade = self

	if CurTime() > self.NextPlank then
		if self:GetHasPlanks() and self:GetNumPlanks() < self:GetMaxAllowedPlanks() then
			self:AddPlank()	
			if (IsValid(activator)) then
				local pointAmount = self:GetPoints()
				if (activator.GetRoundBarricadePoints and isnumber(activator:GetRoundBarricadePoints()) and activator:GetRoundBarricadePoints() + pointAmount < nzRound:GetBarricadePointCap()) then 
					activator:GivePoints(pointAmount)
					activator:SetRoundBarricadePoints(activator:GetRoundBarricadePoints() + pointAmount)
					hook.Call("XPFromBarrier", nil, activator, self)
				end

				if (util.NetworkStringToID("VManip_SimplePlay") != 0) then
					if (activator:GetEyeTrace().Entity == self) then -- Only show their hand if they don't have like their backs facing us
						net.Start("VManip_SimplePlay")
						net.WriteString("use")
						net.Send(activator)
					end
				end

				activator:EmitSound("nzr/effects/repair_ching.wav")
			end
			self.NextPlank = !activator:HasPerk("speed") and CurTime() + 1 or CurTime() + 0.75
		end
	end
end

function ENT:SpawnPlank()
	-- Spawn
	local angs = {-60,-70,60,70}
	local plank = ents.Create("breakable_entry_plank")
	local min = self:GetTriggerJumps() and 0 or -45

	if (!self.Classic and self.PlankPositions and self.PlankPositions[self:GetNumPlanks() + 1]) then
		-- In COD the planks are ALWAYS in the same positions & angles:
		if (self:GetNumPlanks()) then 
			plank:SetParent(self)
			plank:SetLocalPos(self.PlankPositions[self:GetNumPlanks() + 1].pos)
			plank:SetLocalAngles(self.PlankPositions[self:GetNumPlanks() + 1].ang)
		end
	else
		plank:SetParent(self)
		plank:SetPos( self:GetPos()+Vector(0,0, math.random( min, 45 )) )
		plank:SetAngles( Angle(0,self:GetAngles().y, table.Random(angs)) )
	end

	plank:Spawn()
	plank:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	table.insert(self.Planks, plank)
end

-- function ENT:SpawnPlankAnimated(speed)
-- 	if !speed then speed = 1 end

-- 	local plank = self:SpawnPlank()
-- 	plank.OrigPos = plank:GetPos()
-- 	plank.OrigAng = plank:GetAngles()
-- 	plank:SetPos( plank:GetPos()-Vector(0,0,90) + self:GetAngles():Forward()*50 )
-- 	plank:SetAngles( plank:GetAngles() + Angle(350,0,0) )

-- 	for i = 1, 210 do
-- 		timer.Simple((i / 180) / speed, function()
-- 			if IsValid(plank) and IsValid(self) then
-- 				if i >= 210 then
-- 					plank:SetPos(plank.OrigPos)
-- 					plank:SetAngles(plank.OrigAng)
-- 					for a = 1, 3 do
-- 						ParticleEffect("impact_wood", plank:WorldSpaceCenter(), Angle(0,0,0))
-- 					end
-- 					self:EmitSound("nzu/barricade/slam_0" .. math.random(0,5) .. ".wav")
-- 					util.ScreenShake(self:GetPos(), 30, 30, 0.5, 120)
-- 					timer.Simple(0.1, function() if IsValid(self) then self:EmitSound("nzu/barricade/repair.wav") end end)
-- 				elseif i >= 201 then
-- 					plank:SetPos(plank:GetPos() - self:GetAngles():Forward()*5)
-- 				elseif i >= 151 then
-- 					plank:SetPos(plank:GetPos() + Vector(0,0,0.1))
-- 				elseif i >= 101 then
-- 					plank:SetPos(plank:GetPos() - Vector(0,0,0.1))
-- 				else
-- 					plank:SetPos(plank:GetPos() + Vector(0,0,0.9))
-- 					plank:SetAngles(plank:GetAngles() - Angle(3.5,0,0))
-- 				end
-- 			end
-- 		end)
-- 	end
-- end

function ENT:Touch(ent)
	--if self:GetTriggerJumps() and self:GetNumPlanks() == 0 then
		--if ent.TriggerBarricadeJump then ent:TriggerBarricadeJump(self, self:GetTouchTrace().HitNormal) end
	--end
end

local function CollidableEnt(ent)
	if (ent:Health() > 0) then return true end -- This entity is an organism of some type
	if (!IsValid(ent:GetPhysicsObject())) then return true end -- This entity is not a physics object
	return false
end

function IsStuck(ply)
	local Maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale()) 
	local Mins = Vector(ply:OBBMins().X / ply:GetModelScale(), ply:OBBMins().Y / ply:GetModelScale(), ply:OBBMins().Z / ply:GetModelScale())

	local tr = util.TraceHull({
		start = ply:GetPos(),
		endpos = ply:GetPos(),
		maxs = Maxs, -- Exactly the size the player uses to collide with stuff
		mins = Mins, -- ^
		collisiongroup = COLLISION_GROUP_PLAYER, -- Collides with stuff that players collide with
		filter = ply
	})   

	return tr.Hit
end

-- things projectiles, nades and other non-player ents should be allowed to go through
local ent_pass = {
    ["breakable_entry"] = true,
    ["breakable_entry_plank"] = true,
    ["invis_wall"] = true,
    ["wall_block"] = true,
    ["invis_wall_zombie"] = true
}

hook.Add("ShouldCollide", "zCollisionHook", function(ent1, ent2)
    -- Hopefully this is optimized a bit better..
    if IsValid(ent1) and ent_pass[ent1:GetClass()] and !ent2:IsPlayer() and !ent2:IsNextBot() then return false end
    --if IsValid(ent1) and ent1:GetClass() == "breakable_entry" and !ent2:IsPlayer() and ent2.Type != "nextbot" then return false end
	--if IsValid(ent1) and ent1:GetClass() == "breakable_entry_plank" and !ent2:IsPlayer() and ent2.Type != "nextbot" then return false end
	--if IsValid(ent1) and (ent1:GetClass() == "invis_wall" 
	--					or ent1:GetClass() == "wall_block"
	--					or ent1:GetClass() == "invis_wall_zombie"
	--					or ent1.Base == "wall_block") and !ent2:IsPlayer() and ent2.Type != "nextbot" then return false end

-- Commented out because this is retarded. Plus all zombies jump through barricades now, so not necessary.
 	-- Barricade glitch fixed by Ethorbit:
	--if IsValid(ent1) and ent1:GetClass() == "breakable_entry" and nzConfig.ValidEnemies[ent2:GetClass()] and !ent1:GetTriggerJumps() and ent1.NoPlanks then
	--	if !ent2:GetTarget() then return end
	--	
	--	if !ent1.CollisionResetTime then
	--		if !IsValid(ent2:GetTarget()) then return end
	--		if ent1:GetPos():Distance(ent2:GetTarget():GetPos()) > 80 then 
	--			--return false
	--			ent1:SetSolid(SOLID_NONE) 
	--			ent1.CollisionResetTime = CurTime() + 0.1
	--		end
	--	end
	--end
	--
	--if IsValid(ent2) and ent2:GetClass() == "breakable_entry" and nzConfig.ValidEnemies[ent1:GetClass()] and !ent2:GetTriggerJumps() and ent2.NoPlanks then
	--	if !ent1:GetTarget() then return end

	--	if !ent2.CollisionResetTime then
	--		if !IsValid(ent1:GetTarget()) then return end
	--		if ent2:GetPos():Distance(ent1:GetTarget():GetPos()) > 80 then 
	--			--return false
	--			ent2:SetSolid(SOLID_NONE) 
	--			ent2.CollisionResetTime = CurTime() + 0.1
	--		end
	--	end
	--end
end)

if CLIENT then
	function ENT:Draw()
		if ConVarExists("nz_creative_preview") and !GetConVar("nz_creative_preview"):GetBool() and nzRound:InState( ROUND_CREATE ) then
			self:DrawModel()
		end
	end
else
	function ENT:Think()
		if self.CollisionResetTime and self.CollisionResetTime < CurTime() then
			self:SetSolid(SOLID_VPHYSICS)
			self.CollisionResetTime = nil
		end
	end
end

function ENT:RemoveInvalidZombies()
	if !self.ZombiesTearingDown then return end

	for zmb,_ in pairs(self.ZombiesTearingDown) do
		if !IsValid(zmb) or zmb:Health() <= 0 or zmb:GetPos():DistToSqr(self:GetPos()) >= 200^2 then
			self:RemoveZombie(zmb)
		end
	end
end

function ENT:AddZombie(zombie)
	self.ZombiesTearingDown[zombie] = 1
end

function ENT:RemoveZombie(zombie)
	self.ZombiesTearingDown[zombie] = nil 
end

function ENT:HasZombie(zombie)
	return self.ZombiesTearingDown[zombie]
end

function ENT:HasMaxZombies()
	self:RemoveInvalidZombies()
	return table.Count(self.ZombiesTearingDown) >= self:GetMaxAllowedZombies()
end
