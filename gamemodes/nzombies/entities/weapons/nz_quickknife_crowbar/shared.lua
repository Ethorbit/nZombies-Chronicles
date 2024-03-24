
	-- Weapon base courtesy of CptFuzzies SWEP Bases project
	-- Recoded to do more balanced damage

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 60
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/knife/v_knife.mdl"
SWEP.WorldModel		= "models/weapons/knife/w_knife.mdl"
--SWEP.AnimPrefix		= "crowbar"
SWEP.HoldType		= "knife"

SWEP.UseHands = true

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
SWEP.DrawCrosshair		= false

CROWBAR_RANGE	= 80.0
CROWBAR_REFIRE	= 0.4

--SWEP.Primary.Sound			= "nz/knife/weapons/whoosh.wav"
--SWEP.Primary.Hit			= Sound("nzr/effects/bowie/swing/bowie_swing_01")
SWEP.Primary.Range			= 75
SWEP.Primary.Damage			= 0
SWEP.Primary.DamageType		= DMG_CLUB
SWEP.Primary.Force			= 0.75
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Delay			= CROWBAR_REFIRE
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "None"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "None"

SWEP.NZPreventBox = true

SWEP.HitsToKill = { -- Round = # hits to kill
	[1] = 1, [2] = 2, [3] = 3,
	[4] = 3, [5] = 4, [6] = 5,
	[7] = 5, [8] = 6, [9] = 7,
	[10] = 7, [11] = 8, [12] = 9,
	[13] = 10, [14] = 11, [15] = 12,
	[16] = 13, [17] = 14
}

/*---------------------------------------------------------
   Name: SWEP:Initialize( )
   Desc: Called when the weapon is first loaded
---------------------------------------------------------*/
function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
end

/*---------------------------------------------------------
   Name: SWEP:PrimaryAttack( )
   Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	local pPlayer		= self.Owner
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	pPlayer:SetAnimation( PLAYER_ATTACK1 )
	self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )

	if SERVER then
		// Only the player fires this way so we can cast

		if ( !pPlayer ) then
			return;
		end

		// Make sure we can swing first
		if ( !self:CanPrimaryAttack() ) then return end

		local vecSrc		= pPlayer:GetShootPos();
		local vecDirection	= pPlayer:GetAimVector();

		local trace			= {}
		trace.start		= vecSrc
		trace.endpos	= vecSrc + ( vecDirection * self:GetRange() )
		trace.filter	= pPlayer

		--local traceHit		= util.TraceLine( trace )

		local traceHit = util.TraceHull({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + ( self.Owner:GetAimVector() * 73 ),
			filter = function(ent) return ent != self.Owner and ent:GetClass() != "breakable_entry" and ent:GetClass() != "breakable_entry_plank" end,
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			mask = MASK_SHOT_HULL
		})

		if ( traceHit.Hit ) then
			local zombie = traceHit.Entity
			
			local slashdmg = DamageInfo()
			slashdmg:SetAttacker(self.Owner)
			slashdmg:SetInflictor(self)
			slashdmg:SetDamageType(self.Primary.DamageType)
			slashdmg:SetDamageForce(self.Owner:GetAimVector() * math.random(3000, 4000))
            
            if ( IsValid(zombie) and zombie.Type == "nextbot" and zombie:Health() > 0 or zombie:IsPlayer() ) then -- They stabbed a zombie
				-- New damage handling by Ethorbit for compatibility with COLLISION_GROUP_DEBRIS_TRIGGER:
				local hits = self.HitsToKill[nzRound:GetNumber()]

				if hits then
					local dmgToDeal = (100 / hits)
					slashdmg:SetDamagePercentage(dmgToDeal)
				else
					slashdmg:SetDamage(20)
					slashdmg:SetMaxDamage(20)
				end

				zombie:TakeDamageInfo(slashdmg)

				local effectData = EffectData()
				effectData:SetOrigin(traceHit.HitPos)
				util.Effect("BloodImpact", effectData, true, true)

				self.Owner:EmitSound("nzr/effects/knife/knife_flesh_" .. math.random(0, 4) .. ".wav")
			else -- Play default stab sound
                -- Deal damage anyway so things like func_breakable break.
                if IsValid(zombie) and !zombie:IsValidZombie() and !zombie:IsPlayer() then 
                    slashdmg:SetDamage(150)
				    zombie:TakeDamageInfo(slashdmg)
                end 
            
                --timer.Simple(0.1, function() self:EmitSound("nz/knife/knife_stab.wav") end)
				self.Owner:EmitSound("nzr/knife/knife_stab.wav")
			end


			-- self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			-- pPlayer:SetAnimation( PLAYER_ATTACK1 )
			-- self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )

			--if math.random(0,1) == 0 and !self.Owner:KeyDown(IN_BACK) then

			-- else
			-- 	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			-- 	pPlayer:SetAnimation( PLAYER_ATTACK1 )
			-- 	self.nzHolsterTime = CurTime() + 0.5
			-- 	timer.Simple(0.1, function() self:EmitSound("nz/knife/knife_slash.wav") end)
			-- 	self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )
			-- end

			self.Weapon:SetNextPrimaryFire( CurTime() + self:GetFireRate() );
			self.Weapon:SetNextSecondaryFire( CurTime() + self.Weapon:SequenceDuration() );

			--timer.Simple(0.1, function() self:Hit( traceHit, pPlayer ); end)
			return
		end

		self.Owner:EmitSound("nzr/effects/knife/knife_swing_" .. math.random(0, 5) .. ".wav", 65)

		-- self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		-- pPlayer:SetAnimation( PLAYER_ATTACK1 );
		-- self.Owner:ViewPunch( Angle( math.Rand(-3, -2.5), math.Rand(-7, -4.5), 0 ) )

		self.Weapon:SetNextPrimaryFire( CurTime() + self:GetFireRate() );
		self.Weapon:SetNextSecondaryFire( CurTime() + self.Weapon:SequenceDuration() );

		self:Swing( traceHit, pPlayer );

		return
	end
end

/*---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	return false
end

/*---------------------------------------------------------
   Name: SWEP:Reload( )
   Desc: Reload is being pressed
---------------------------------------------------------*/
function SWEP:Reload()
	return false
end

//-----------------------------------------------------------------------------
// Purpose: Get the damage amount for the animation we're doing
// Input  : hitActivity - currently played activity
// Output : Damage amount
//-----------------------------------------------------------------------------
function SWEP:GetDamageForActivity( hitActivity )
	return nzRound:InProgress() and 30 + (45/nzRound:GetNumber()) or 75
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()

	self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	self:SetDeploySpeed( self.Weapon:SequenceDuration() )

	return true

end


-- function SWEP:Hit( traceHit, pPlayer )
-- 	local vecSrc = pPlayer:GetShootPos();

-- 	if ( SERVER ) then
-- 		pPlayer:TraceHullAttack( vecSrc, traceHit.HitPos, Vector( -5, -5, -5 ), Vector( 5, 5, 36 ), self:GetDamageForActivity(), self.Primary.DamageType, self.Primary.Force );
-- 	end

-- 	// self:AddViewKick();

-- end



function SWEP:Swing( traceHit, pPlayer )
end


function SWEP:CanPrimaryAttack()
	return true
end


function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:SetDeploySpeed( speed )

	self.m_WeaponDeploySpeed = tonumber( speed / GetConVarNumber( "phys_timescale" ) )

	self.Weapon:SetNextPrimaryFire( CurTime() + speed )
	self.Weapon:SetNextSecondaryFire( CurTime() + speed )

end



function SWEP:Drop( vecVelocity )
if ( !CLIENT ) then
	self:Remove();
end
end

function SWEP:GetRange()
	return	self.Primary.Range;
end

function SWEP:GetFireRate()
	return	self.Primary.Delay;
end
