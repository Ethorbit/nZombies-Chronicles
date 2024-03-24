AddCSLuaFile()
game.AddParticles("particles/tank_fx.pcf")
PrecacheParticleSystem("tank_ground_pound")
PrecacheParticleSystem("tank_rock_throw_ground_generic")
PrecacheParticleSystem("tank_rock_throw_ground_generic_dust")

ENT.Base = "nz_bossbase"

DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Tank"
ENT.Category = "Brainz"
ENT.Author = "Berb, Ethorbit"

ENT.TankMusic = "tank/music/l4d2.wav"

ENT.Skins = {} -- Default is good enough
ENT.Bodygroups = {} -- Default is good enough

ENT.AttackRange = 125
ENT.DamageLow = 120
ENT.DamageHigh = 120
ENT.RockDamage_NoJugg = 80
ENT.RockDamage_Jugg = 190

ENT.AttackSequences = {
     {seq = "Attack"},
     {seq = "Attack_Incap_03"},
     {seq = "melee3"}
}

ENT.DeathSequences = {
     "death"
}

ENT.AttackSounds = {
     "tank/voice/attack/tank_attack_01.wav",
     "tank/voice/attack/tank_attack_02.wav",
     "tank/voice/attack/tank_attack_03.wav",
     "tank/voice/attack/tank_attack_04.wav",
     "tank/voice/attack/tank_attack_05.wav",
     "tank/voice/attack/tank_attack_06.wav",
     "tank/voice/attack/tank_attack_07.wav",
     "tank/voice/attack/tank_attack_08.wav",
     "tank/voice/attack/tank_attack_09.wav",
     "tank/voice/attack/tank_attack_01.wav",

}

ENT.PainSounds = {
     "tank/voice/pain/tank_pain_01.wav",
     "tank/voice/pain/tank_pain_02.wav",
     "tank/voice/pain/tank_pain_03.wav",
     "tank/voice/pain/tank_pain_04.wav",
     "tank/voice/pain/tank_pain_05.wav",
     "tank/voice/pain/tank_pain_06.wav",
     "tank/voice/pain/tank_pain_07.wav",
     "tank/voice/pain/tank_pain_08.wav",
     "tank/voice/pain/tank_pain_09.wav",
     "tank/voice/pain/tank_pain_10.wav"

}

ENT.AttackHitSounds = {
     "tank/hit/hulk_punch_01.wav",
     "tank/hit/pound_victim_1.wav",
     "tank/hit/pound_victim_2.wav"


}

ENT.WalkSounds = {
     "tank/voice/yell/tank_yell_01.wav",
     "tank/voice/yell/tank_yell_02.wav",
     "tank/voice/yell/tank_yell_01.wav"

}

ENT.ActStages = {
     [1] = {
	  act = ACT_WALK,
	  minspeed = 1,
     },
     [2] = {
	  act = ACT_RUN,
	  minspeed = 150,

     }
}

function ENT:OnInitialize()
     if SERVER then
          self.HelmetDamage = 0 -- Used to save how much damage the light has taken
          self:SetUsingClaw(false)
          self.NextAction = 0
          self.NextClawTime = 0
          self.NextFlameTime = 0
     end
end

function ENT:GetTankHealth() -- To be called within all registered tanks' spawnfuncs
     local hp = (nzRound:GetNumber() * 220) + 10000 --2500
     return hp
end

function ENT:StatsInitialize()
     if SERVER then
    	  self:SetRunSpeed(212)
    	  self:SetHealth(self:GetTankHealth())
    	  self:SetMaxHealth(self:GetTankHealth())
    	  shooting = false
    	  dying = false
    	  helmet = true
    	  counting = false
    	  hasTaunted = false
     end
end

function ENT:OnInjured(dmgInfo)
     BaseClass.OnInjured(self, dmgInfo) -- IMPORTANT STUFF

     -- local attacker = dmgInfo:GetAttacker()
     -- local isWonderWep = false
     --
     -- if IsValid(attacker) and attacker:IsPlayer() then
     --     local wep = attacker:GetActiveWeapon()
     --     isWonderWep = (IsValid(wep) and wep.NZWonderWeapon)
     -- end

     if (dmgInfo:GetIsMeleeDamage()) then -- Melee does percentage damage to us
	     dmgInfo:SetDamage(self:GetMaxHealth() / 20)
     end

     --print(self:Health())

     -- elseif isWonderWep then -- Let powerful weapons hit us hard (so it's possible to kill with Thundergun,Wunderwaffe,etc)
     --     dmgInfo:ScaleDamage(0.25)
     -- else -- Otherwise we take 75% damage reduction from everything else
	 --     dmgInfo:ScaleDamage(0.25)
     -- end
end

function ENT:SpecialInit()
     if CLIENT then
          --make them invisible for a really short duration to blend the emerge sequences
          self:SetNoDraw(true)
          self:TimedEvent( 0.5, function()
               self:SetNoDraw(false)
          end)

          self:SetRenderClipPlaneEnabled( true )
          self:SetRenderClipPlane(self:GetUp(), self:GetUp():Dot(self:GetPos()))

          self:TimedEvent( 2, function()
               self:SetRenderClipPlaneEnabled(false)
          end)
     end
end

function ENT:InitDataTables()
     self:NetworkVar("Entity", 0, "ClawHook")
     self:NetworkVar("Bool", 1, "UsingClaw")
     self:NetworkVar("Bool", 2, "Flamethrowing")
end

function ENT:OnSpawn()
     local seq = "Rage_at_Enemy_01"
     local _, dur = self:LookupSequence(seq)

     -- play emerge animation on spawn
     -- if we have a coroutine else just spawn the zombie without emerging for now.
     if coroutine.running() then

	  local pos = self:GetPos()
	  counting = true
	  ParticleEffect("tank_ground_pound", self:GetPos(), Angle(0,0,0),nil)

	  -- Stop any other tanks' music
	  for _,v in pairs(ents.GetAll()) do
	       if v.Base == self.Base and v.TankMusic then
		    v:StopSound(v.TankMusic)
	       end
	  end

      self:TimedEvent(0.3, function()
          self:EmitSound(self.TankMusic,577)
      end)

	  if math.random(0,20) == 1 then
	       self:EmitSound("tank/voice/yell/power.mp3",577)
	  end

	  self:SetInvulnerable(true)

	  --[[effectData = EffectData()
	  effectData:SetStart( pos + Vector(0, 0, 1000) )
	  effectData:SetOrigin( pos )
	  effectData:SetMagnitude( 0.75 )
	  util.Effect("lightning_strike", effectData)]]

	  self:TimedEvent(dur, function()
	       self:SetPos(self:GetPos() + Vector(0,0,0))
	       self:SetInvulnerable(false)
	       local effectData = EffectData()
	       effectData:SetStart( self:GetPos() )
	       effectData:SetOrigin( self:GetPos() )
	       effectData:SetMagnitude(1)
	       counting = false
	  end)
	  self:PlaySequenceAndWait(seq)
     end
     self:ResetSequence("walk")
     self:SetCycle(0)
end

function ENT:OnZombieDeath(dmgInfo)
     dying = true
     self:StopSound(self.TankMusic)
     self:ReleasePlayer()
     self:StopFlames()
     self:SetRunSpeed(0)
     self.loco:SetVelocity(Vector(0,0,0))
     self:Stop()
     self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
     local seq, dur = self:LookupSequence(self.DeathSequences[math.random(#self.DeathSequences)])
     self:ResetSequence(seq)
     self:SetCycle(0)
     self:EmitSound("tank/voice/die/tank_death0" .. math.random(1, 7) .. ".wav")
     timer.Simple(dur, function()
	  if IsValid(self) then
	       self:Remove()
	  end
     end)

end

function ENT:BodyUpdate()

     self.CalcIdeal = ACT_IDLE

     local velocity = self:GetVelocity()

     local len2d = velocity:Length2D()

     if ( len2d > 100 ) then self.CalcIdeal = ACT_RUN elseif ( len2d > 5 ) then self.CalcIdeal = ACT_RUN end

     if self:IsJumping() and self:WaterLevel() <= 0 then
	  self.CalcIdeal = ACT_JUMP
     end

     if !self:GetSpecialAnimation() and !self:IsAttacking() then
	  if self:GetActivity() != self.CalcIdeal and !self:GetStop() then self:StartActivity(self.CalcIdeal) end

	  if self.ActStages[self:GetActStage()] then
	       self:BodyMoveXY()
	  end
     end

     self:FrameAdvance()

end

AccessorFunc(ENT, "bThrowingRock", "ThrowingRock", FORCE_BOOL)

function ENT:OnPathTimeOut()
     local target = self:GetTarget()
     if CurTime() < self.NextAction then return end

     if math.random(0,5) == 0 and CurTime() > self.NextClawTime then
	  -- Claw
	  if self:IsValidTarget(target) then
	       -- local tr = util.TraceLine({
    	   --     start = self:GetPos() + Vector(0,50,0),
    	   --     endpos = target:GetPos() + Vector(0,0,50),
    	   --     filter = self,
	       -- })
           local tr = util.TraceHull({
               start = self:GetPos() + Vector(0,50,0),
               endpos = target:GetPos() + Vector(0,0,50),
               mins = self:OBBMins(),
               maxs = self:OBBMaxs(),
               filter = self,
           })

	       if IsValid(tr.Entity) and self:IsValidTarget(tr.Entity) and !IsValid(self.ClawHook) then
		    self:Stop()
		    self:TimedEvent(2.5, function()
		    end)

		    self:TimedEvent(0.5, function()
			 self:EmitSound("tank/attack/rip_up_rock_1.wav")
			 self:StopParticles()
		    end)

		    local clawpos = self:GetBonePosition(self:LookupBone( "ValveBiped.Bip01_Head" ))

            -- I'm sorry, but having multiple identical timers was nothing short of retarded
            self:SetThrowingRock(true)
            self:TimedEvent(2.5, function()
                self.ClawHook = ents.Create("nz_tank_rock")
                self.ClawHook.Damage_Jugg = self.RockDamage_Jugg
                self.ClawHook.Damage_NoJugg = self.RockDamage_NoJugg
                self.ClawHook:SetPos(clawpos)
                self.ClawHook:Spawn()
                local speed = math.Clamp(self:GetPos():Distance(tr.Entity:GetPos()) * 2.5, 1000, 20000) -- Speed should scale by distance to player, that way it's never impossible to dodge unless they're TOO CLOSE of course (there's a min and max defined)
                self.ClawHook:Launch(((tr.Entity:GetPos() + Vector(0,0,50)) - self.ClawHook:GetPos()):GetNormalized(), speed)
                self:SetThrowingRock(false)
                self:SetClawHook(self.ClawHook)
                self:SetBodygroup(1,0)
            end)

            self:TimedEvent(.5, function()
                ParticleEffect("tank_rock_throw_ground_generic", self:GetPos(), Angle(0,0,0), nil)
                ParticleEffect("tank_rock_throw_ground_generic_dust", self:GetPos(), Angle(0,0,0), nil)
                self:EmitSound("tank/voice/yell/tank_throw_0"..math.random(1,9)..".wav")
            end)

		    self:SetBodygroup(1,1)
		    self:PlaySequenceAndWait("Throw_02", self.FaceEnemy)
		    self.loco:SetDesiredSpeed(0)

		    local seq = "taunt"
		    local id, dur = self:LookupSequence(seq)
		    self:ResetSequence(id)
		    self:SetCycle(0)
		    self:SetPlaybackRate(1)
		    self:SetVelocity(Vector(0,0,0))
		    self:TimedEvent(dur, function()
			 shooting = false
			 self.loco:SetDesiredSpeed(self:GetRunSpeed())
			 self:SetSpecialAnimation(false)
			 self:SetBlockAttack(false)
			 self:StopFlames()
		    end)
		    self.NextAction = CurTime() + math.random(1, 5)
		    self.NextClawTime = CurTime() + math.random(3, 15)
	       end
	  end
     elseif  math.random(0,5) == 6 and CurTime() > self.NextFlameTime then
	  -- Flamethrower
	  if self:IsValidTarget(target) and self:GetPos():DistToSqr(target:GetPos()) <= 75000 then
	       self:Stop()
	       self:PlaySequenceAndWait("nz_flamethrower_aim")
	       self.loco:SetDesiredSpeed(0)
	       local ang = (target:GetPos() - self:GetPos()):Angle()
	       self:SetAngles(Angle(ang[1], ang[2] + 10, ang[3]))

	       self:StartFlames()
	       local seq = math.random(0,1) == 0 and "nz_flamethrower_loop" or "nz_flamethrower_sweep"
	       local id, dur = self:LookupSequence(seq)
	       self:ResetSequence(id)
	       self:SetCycle(0)
	       self:SetPlaybackRate(1)
	       self:SetVelocity(Vector(0,0,0))

	       self:TimedEvent(dur, function()
		    self.loco:SetDesiredSpeed(self:GetRunSpeed())
		    self:SetSpecialAnimation(false)
		    self:SetBlockAttack(false)
		    self:StopFlames()
	       end)

	       self.NextAction = CurTime() + math.random(1, 5)
	       self.NextFlameTime = CurTime() + math.random(1, 10)
	  end
     end
end

-- This function is run every time a path times out, once every 1 seconds of pathing

function ENT:OnRemove()
     self:StopSound(self.TankMusic)

     if IsValid(self.ClawHook) then self.ClawHook:Remove() end
     if IsValid(self.GrabbedPlayer) then self.GrabbedPlayer:SetMoveType(MOVETYPE_WALK) end
     if IsValid(self.FireEmitter) then self.FireEmitter:Finish() end
end

function ENT:StartFlames(time)
     self:Stop()
     if time then self:TimedEvent(time, function() self:StopFlames() end) end
end

function ENT:StopFlames()
     self:SetStop(false)
end

function ENT:OnThink()
     local target = self:GetTarget()

     if SERVER then
         if (self:GetThrowingRock() and IsValid(target) and self.Health and self:Health() > 0) then
    	     self.loco:FaceTowards(self:GetTarget():GetPos())
    	     self.loco:SetMaxYawRate(100)
         else
             self.loco:SetMaxYawRate(400)
         end
     end

     if !self:IsAttacking() then
	  if !counting and !dying and !shooting and self:Health() > 0 then
	       counting = true
	       self:TimedEvent(0.3, function()
		    self:EmitSound("footsteps/tank/walk/tank_walk0"..math.random(1,5)..".wav")
		    counting = false
	       end)
	  end
     end
     if self:IsAttacking() then
	  self.loco:SetDesiredSpeed(0)
     end
     if self:GetFlamethrowing() then
	  if !self.NextFireParticle or self.NextFireParticle < CurTime() then
	       local bone = self:LookupBone("j_elbow_ri")
	       local pos, ang = self:GetBonePosition(bone)
	       pos = pos - ang:Forward() * 40 - ang:Up()*10
	       if CLIENT then
		    if !IsValid(self.FireEmitter) then self.FireEmitter = ParticleEmitter(self:GetPos(), false) end

		    local p = self.FireEmitter:Add("particles/fire1.vmt", pos)
		    if p then
			 p:SetColor(math.random(30,60), math.random(40,70), math.random(0,50))
			 p:SetStartAlpha(255)
			 p:SetEndAlpha(0)
			 p:SetVelocity(ang:Forward() * -150 + ang:Up()*math.random(-5,5) + ang:Right()*math.random(-5,5))
			 p:SetLifeTime(0.25)

			 p:SetDieTime(math.Rand(0.75, 1.5))

			 p:SetStartSize(math.random(1, 5))
			 p:SetEndSize(math.random(20, 30))
			 p:SetRoll(math.random(-180, 180))
			 p:SetRollDelta(math.Rand(-0.1, 0.1))
			 p:SetAirResistance(50)

			 p:SetCollide(false)

			 p:SetLighting(false)
		    end
	       else
		    if IsValid(self.GrabbedPlayer) then
			 if self.GrabbedPlayer:GetPos():DistToSqr(self:GetPos()) > 10000 then
			      self:ReleasePlayer()
			      self:StopFlames()
			      self.loco:SetDesiredSpeed(self:GetRunSpeed())
			      self:SetSpecialAnimation(false)
			      self:SetBlockAttack(false)
			      self:SetStop(false)
			 else
			      local dmg = DamageInfo()
			      dmg:SetAttacker(self)
			      dmg:SetInflictor(self)
			      dmg:SetDamage(2)
			      dmg:SetDamageType(DMG_BURN)

			      self.GrabbedPlayer:TakeDamageInfo(dmg)
			      self.GrabbedPlayer:Ignite(1, 0)
			 end
		    else
			 local tr = util.TraceHull({
			      start = pos,
			      endpos = pos - ang:Forward()*150,
			      filter = self,
			      --mask = MASK_SHOT,
			      mins = Vector( -5, -5, -10 ),
			      maxs = Vector( 5, 5, 10 ),
			 })

			 debugoverlay.Line(pos, pos - ang:Forward()*150)

			 if self:IsValidTarget(tr.Entity) then
			      local dmg = DamageInfo()
			      dmg:SetAttacker(self)
			      dmg:SetInflictor(self)
			      dmg:SetDamage(2)
			      dmg:SetDamageType(DMG_BURN)

			      tr.Entity:TakeDamageInfo(dmg)
			      tr.Entity:Ignite(2, 0)
			 end
		    end
	       end

	       self.NextFireParticle = CurTime() + 0.05
	  end
     elseif CLIENT and self.FireEmitter then
	  self.FireEmitter:Finish()
	  self.FireEmitter = nil
     end

     if SERVER and IsValid(self.GrabbedPlayer) and !self:IsValidTarget(self.GrabbedPlayer) then
	  self:ReleasePlayer()
	  self:StopFlames()
     end
end

function ENT:GrabPlayer(ply)
     if CLIENT then return end


     self:SetUsingClaw(false)
     self:SetStop(false)
     self.loco:SetDesiredSpeed(self:GetRunSpeed())

     if self:IsValidTarget(ply) then
	  self.GrabbedPlayer = ply

	  self:TimedEvent(0, function()
	       local att = self:GetAttachment(self:LookupAttachment("clawlight"))
	       local pos = att.Pos + att.Ang:Forward()*10

	       ply:SetPos(pos - Vector(0,0,50))
	       ply:SetMoveType(MOVETYPE_NONE)
	  end)


	  self:SetSequence(self:LookupSequence("nz_grapple_flamethrower"))
	  self:SetCycle(0)
	  self:StartFlames()
	  --[[elseif ply then
	  self.loco:SetDesiredSpeed(self:GetRunSpeed())
	  self:SetSpecialAnimation(false)
	  self:SetBlockAttack(false)
	  self:SetStop(false)]]
     else

     end
end

function ENT:ReleasePlayer()
     if IsValid(self.GrabbedPlayer) then
	  self.GrabbedPlayer:SetMoveType(MOVETYPE_WALK)
     end
     if IsValid(self.ClawHook) then
	  self.ClawHook:Release()
     end
     if !self:GetFlamethrowing() then
	  self:SetStop(false)
     end
     self:SetUsingClaw(false)
     self:SetStop(false)
     self.loco:SetDesiredSpeed(self:GetRunSpeed())
end
