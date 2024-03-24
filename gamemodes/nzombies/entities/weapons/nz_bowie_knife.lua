if SERVER then
	AddCSLuaFile("nz_bowie_knife.lua")
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= false
	SWEP.AutoSwitchFrom	= true
end

if CLIENT then

	SWEP.PrintName     	    = "Bowie Knife"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

	SWEP.Category			= "nZombies"

end


SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Stab Stab Stab!"
SWEP.Instructions	= "Let the gamemode give you it"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.HoldType = "knife"

SWEP.ViewModel	= "models/weapons/c_bowie_knife.mdl"
SWEP.WorldModel	= "models/weapons/w_bowie_knife.mdl"
SWEP.UseHands = true
SWEP.vModel = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"
SWEP.Primary.DamageType		= DMG_CLUB
SWEP.Primary.Force			= 0

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.NextReload				= 1

SWEP.Primary.Damage 		= 200
SWEP.Range					= 110


function SWEP:Initialize()

	self:SetHoldType( self.HoldType )

end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self.HolsterTime = CurTime() + 2.5
	self:EmitSound("nz/bowie/draw/bowie_start.wav")

	timer.Simple(0.7, function()
		if IsValid(self) then
			self:EmitSound("nz/bowie/draw/bowie_turn.wav")
		end
	end)
	timer.Simple(1.4, function()
		if IsValid(self) then
			self:EmitSound("nz/bowie/draw/bowie_toss.wav")
		end
	end)

	timer.Simple(1.9, function()
		if IsValid(self) then
			self:EmitSound("nz/bowie/draw/bowie_catch.wav")
		end
	end)
end

function SWEP:PrimaryAttack()
	-- Only the player fires this way so we can cast

	local ply = self.Owner;

	if ( !ply ) then
		return
	end

	local vecSrc		= ply:GetShootPos()
	local vecDirection	= ply:GetAimVector()

	-- local trace			= {}
	-- 	trace.start		= vecSrc
	-- 	trace.endpos	= vecSrc + ( vecDirection * self.Range)
	-- 	trace.filter	= ply

	--local traceHit		= util.TraceLine( trace )
	local traceHit = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + ( self.Owner:GetAimVector() * 110 ),
		filter = function(ent) return ent != self.Owner and ent:GetClass() != "breakable_entry" and ent:GetClass() != "breakable_entry_plank" end,
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		mask = MASK_SHOT_HULL
	})

	if ( traceHit.Hit ) then
		self:SendWeaponAnim( ACT_VM_HITCENTER )
		ply:SetAnimation( PLAYER_ATTACK1 )
		if SERVER then -- Fixed by Ethorbit to support new zombie collisions
			local zombie = traceHit.Entity
			
			local slashdmg = DamageInfo()
			slashdmg:SetAttacker(self.Owner)
			slashdmg:SetInflictor(self)
			slashdmg:SetDamage(self.Primary.Damage)
			slashdmg:SetDamageType(self.Primary.DamageType)
			slashdmg:SetDamageForce(self.Owner:GetAimVector() * math.random(3000, 4000))

            if ( IsValid(zombie) and (zombie.Type == "nextbot" or zombie:IsPlayer()) and zombie:Health() > 0 ) then -- They stabbed a zombie
				-- New damage handling by Ethorbit for compatibility with COLLISION_GROUP_DEBRIS_TRIGGER:
				zombie:TakeDamageInfo(slashdmg)

				local effectData = EffectData()
				effectData:SetOrigin(traceHit.HitPos)
				util.Effect("BloodImpact", effectData, true, true)

				self.Owner:EmitSound("nz/bowie/stab/bowie_stab_0"..math.random(0,2)..".wav")
				self.Owner:EmitSound("nzr/effects/knife/knife_flesh_" .. math.random(0, 4) .. ".wav", 60, 100, 1)
			else -- Play default stab sound	
                -- Deal damage anyway so things like func_breakable break.
                if IsValid(zombie) and !zombie:IsValidZombie() and !zombie:IsPlayer() then 
                    --slashdmg:SetDamage(150)
				    zombie:TakeDamageInfo(slashdmg)
                end 
                
                self.Owner:EmitSound("nz/bowie/stab/bowie_stab_0"..math.random(0,2)..".wav")
			end
		end

		-- if math.random(0,1) == 0 then
		-- 	self:SendWeaponAnim( ACT_VM_HITCENTER )
		-- 	ply:SetAnimation( PLAYER_ATTACK1 )
		-- 	self.nzHolsterTime = CurTime() + 1
		-- 	self:EmitSound("nz/bowie/stab/bowie_stab_0"..math.random(0,2)..".wav")
		-- else
		-- 	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		-- 	ply:SetAnimation( PLAYER_ATTACK1 )
		-- 	self.nzHolsterTime = CurTime() + 0.5
		-- 	self:EmitSound("nz/bowie/swing/bowie_swing_0"..math.random(0,2)..".wav")
		-- end

		--local vecSrc = ply:GetShootPos()

		-- if ( SERVER ) then
		-- 	ply:TraceHullAttack( vecSrc, traceHit.HitPos, Vector( -5, -5, -5 ), Vector( 5, 5, 36 ), self.Primary.Damage, self.Primary.DamageType, self.Primary.Force )
		-- end

		return

	end


	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	ply:SetAnimation( PLAYER_ATTACK1 )
	self:EmitSound("nz/bowie/swing/bowie_swing_0"..math.random(0,2)..".wav", 65)

	return
end

function SWEP:DrawAnim()

end

function SWEP:PostDrawViewModel()

end

function SWEP:DrawWorldModel()

end

function SWEP:OnRemove()

end

function SWEP:Think()

end

function SWEP:GetViewModelPosition( pos, ang )

 	local newpos = LocalPlayer():EyePos()
	local newang = LocalPlayer():EyeAngles()
	local up = newang:Up()

	newpos = newpos + LocalPlayer():GetAimVector()*6 - up*65

	return newpos, newang

end
