AddCSLuaFile()

nzConfig.AddValidEnemy("nz_zombie_special_dog", {
    Valid = true,
    SpecialSpawn = true,
    ScaleDMG = function(zombie, hitgroup, dmginfo)
        --if hitgroup == HITGROUP_HEAD then dmginfo:ScaleDamage(2) end
    end,
    OnHit = function(zombie, dmginfo, hitgroup)
        local attacker = dmginfo:GetAttacker()
        if attacker:IsPlayer() and attacker:GetNotDowned() then
            attacker:GivePoints(10)
        end
    end,
    OnKilled = function(zombie, dmginfo, hitgroup)
        local attacker = dmginfo:GetAttacker()
        if attacker:IsPlayer() and attacker:GetNotDowned() then
            if dmginfo:GetDamageType() == DMG_CLUB then
                attacker:GivePoints(130)
            elseif hitgroup == HITGROUP_HEAD then
                attacker:GivePoints(100)
            else
                attacker:GivePoints(50)
            end
        end
    end
})

ENT.Base = "nz_zombie_special_base_moo"
ENT.PrintName = "Hellhound"
ENT.Category = "Brainz"
ENT.Author = "GhostlyMoo"

DEFINE_BASECLASS(ENT.Base)

game.AddParticles("particles/bo1overhaul_blood_fx.pcf")
game.AddParticles("particles/nbnz_burning_fx.pcf")
game.AddParticles("particles/insurgency/world_fx_ins.pcf")
game.AddParticles("particles/cod/hound.pcf")
PrecacheParticleSystem("hound_summon")
PrecacheParticleSystem("ins_skybox_lightning")
PrecacheParticleSystem("hound_explosion")
PrecacheParticleSystem("firestaff_victim_burning")

if CLIENT then return end -- Client doesn't really need anything beyond the basics

ENT.SpeedBasedSequences = true
ENT.IsMooZombie = true
ENT.RedEyes = true
ENT.IsMooSpecial = true
ENT.AttackRange = 80
ENT.AttackDamage = 25

ENT.Models = {
    {Model = "models/moo/_codz_ports/t5/hellhound/moo_codz_t5_devildoggo.mdl", Skin = 0, Bodygroups = {0,0}},
}

local spawn = {"idle"}

local AttackSequences = {
    {seq = "nz_dog_run_attack", dmgtimes = {0.3}},
}

local JumpSequences = {
    {seq = ACT_JUMP, speed = 150},
}


ENT.BarricadeTearSequences = {
    --Leave this empty if you don't intend on having a special enemy use tear anims.
}

ENT.IdleSequence = "nz_dog_idle"

ENT.DeathSequences = {
    "nz_dog_death_front",
}

ENT.ElectrocutionSequences = {
    "nz_dog_tesla_death_a",
    "nz_dog_tesla_death_b",
    "nz_dog_tesla_death_c",
    "nz_dog_tesla_death_d",
    "nz_dog_tesla_death_e",
}

ENT.AttackSounds = {
    "nz_moo/zombies/vox/_hellhound/attack/attack_00.mp3",
    "nz_moo/zombies/vox/_hellhound/attack/attack_01.mp3",
    "nz_moo/zombies/vox/_hellhound/attack/attack_02.mp3",
    "nz_moo/zombies/vox/_hellhound/attack/attack_03.mp3",
    "nz_moo/zombies/vox/_hellhound/attack/attack_04.mp3",
    "nz_moo/zombies/vox/_hellhound/attack/attack_05.mp3"
}

local walksounds = {
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_00.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_01.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_02.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_03.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_04.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_05.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_06.mp3"),
    Sound("nz_moo/zombies/vox/_hellhound/movement/movement_07.mp3"),
}

local runsounds = {
    Sound("nz/hellhound/close/close_00.wav"),
    Sound("nz/hellhound/close/close_01.wav"),
    Sound("nz/hellhound/close/close_02.wav"),
    Sound("nz/hellhound/close/close_03.wav"),
}

ENT.DeathSounds = {
    "nz_moo/zombies/vox/_hellhound/death/death_00.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_01.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_02.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_03.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_04.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_05.mp3",
    "nz_moo/zombies/vox/_hellhound/death/death_06.mp3",
}

ENT.AppearSounds = {
    "nz_moo/zombies/vox/_hellhound/appear/appear_00.mp3",
    "nz_moo/zombies/vox/_hellhound/appear/appear_01.mp3",
    "nz_moo/zombies/vox/_hellhound/appear/appear_02.mp3",
    "nz_moo/zombies/vox/_hellhound/appear/appear_03.mp3"
}

ENT.SequenceTables = {
    {Threshold = 0, Sequences = {
        {
            SpawnSequence = {spawn},
            MovementSequence = {
                "nz_dog_walk",
            },
            AttackSequences = {AttackSequences},
            JumpSequences = {JumpSequences},
            PassiveSounds = {walksounds},
        },
    }},
    {Threshold = 36, Sequences = {
        {
            SpawnSequence = {spawn},
            MovementSequence = {
                "nz_dog_trot",
            },
            AttackSequences = {AttackSequences},
            JumpSequences = {JumpSequences},
            PassiveSounds = {walksounds},
        },
    }},
    {Threshold = 71, Sequences = {
        {
            SpawnSequence = {spawn},
            MovementSequence = {
                "nz_dog_run",
            },
            AttackSequences = {AttackSequences},
            JumpSequences = {JumpSequences},
            PassiveSounds = {runsounds},
        },
    }}
}


function ENT:SetupDataTables()
    --self:NetworkVar("Bool", 5, "DogRunning")
    self:NetworkVar("Entity", 5, "DogTarget")
    BaseClass.SetupDataTables(self)
end

function ENT:StatsInitialize()
    if SERVER then
        self.Sprinting = false
        self.IgnitedFoxy = false
        self:SetRunSpeed( 36 )
        self.loco:SetDesiredSpeed( 36 )
    end
    self:SetCollisionBounds(Vector(-13,-13, 0), Vector(13, 13, 45))
end

function ENT:OnSpawn()
    -- shit doesn't work, using OG method instead
    self:SetMaterial("invisible")

    self:SetNoDraw(true)
   
    timer.Simple(1.3, function()
        if IsValid(self) then
            self:SetNoDraw(false)
        end
    end)
    
    self:SetInvulnerable(true)
    self:SetBlockAttack(true)
    self:SolidMaskDuringEvent(MASK_PLAYERSOLID)

    self:EmitSound("nz/hellhound/spawn/prespawn.wav",511,100)
    ParticleEffect("hound_summon",self:GetPos(),self:GetAngles(),nil)
    --ParticleEffect("fx_hellhound_summon",self:GetPos(),self:GetAngles(),nil)

    self:TimeOut(0.85)
    
    self:EmitSound("nz/hellhound/spawn/strike.wav",511,100)
    ParticleEffectAttach("ins_skybox_lightning",PATTACH_ABSORIGIN_FOLLOW,self,0)
    
    self:SetMaterial("")
    self:SetInvulnerable(nil)
    self:SetBlockAttack(false)
    self:CollideWhenPossible()
    self:EmitSound(self.AppearSounds[math.random(#self.AppearSounds)], 511, math.random(85, 105), 1, 2)

    nzRound:SetNextSpawnTime(CurTime() + 3) -- This one spawning delays others by 3 seconds
end

function ENT:PerformDeath(dmgInfo)
    if self:GetSpecialAnimation() then
        self:PlaySound(self.DeathSounds[math.random(#self.DeathSounds)], 90, math.random(85, 105), 1, 2)
        if IsValid(self) then
            if self.IgnitedFoxy then
                ParticleEffect("hound_explosion",self:GetPos(),self:GetAngles(),self)
                self:Explode( math.random( 25, 50 )) -- Doggy goes Kaboom! Since they explode on death theres no need for them to play death anims.
                self:Remove()
            else
                self:Remove()
            end
        end
    else
        if dmgInfo:GetDamageType() == DMG_SHOCK then
            self:PlaySound(self.DeathSounds[math.random(#self.DeathSounds)], 90, math.random(85, 105), 1, 2)
            self:DoDeathAnimation(self.ElectrocutionSequences[math.random(#self.ElectrocutionSequences)])
        else
            self:PlaySound(self.DeathSounds[math.random(#self.DeathSounds)], 90, math.random(85, 105), 1, 2)
            self:DoDeathAnimation(self.DeathSequences[math.random(#self.DeathSequences)])
        end
    end

    BaseClass.PerformDeath(self, dmgInfo)
end

function ENT:DoDeathAnimation(seq)
    self.BehaveThread = coroutine.create(function()
        self:PlaySequenceAndWait(seq)
        if IsValid(self) then
            if self.IgnitedFoxy then
                ParticleEffect("hound_explosion",self:GetPos(),self:GetAngles(),self)
                self:Explode( math.random( 25, 50 )) -- Doggy goes Kaboom! Since they explode on death theres no need for them to play death anims.
                self:Remove()
            else
                self:Remove()
            end
        end
    end)
end


function ENT:OnPathTimeOut()
    local distToTarget = self:GetPos():Distance(self:GetTargetPosition())
    if IsValid(self:GetTarget()) then
        if not self.Sprinting and distToTarget < 750 then
            self.Sprinting = true
            self.IgnitedFoxy = true
            self:SetRunSpeed( 71 )
            self.loco:SetDesiredSpeed( 71 )
            self:SpeedChanged()
            ParticleEffectAttach("firestaff_victim_burning",PATTACH_ABSORIGIN_FOLLOW,self,0)
        end
    end
end


function ENT:PlayAttackAndWait( name, speed )

    local len = self:SetSequence( name )
    speed = speed or 1

    self:ResetSequenceInfo()
    self:SetCycle( 0 )
    self:SetPlaybackRate( speed )

    local endtime = CurTime() + len / speed

    while ( true ) do

        if ( endtime < CurTime() ) then
            if !self:GetStop() then
                self:ResetMovementSequence()
                self.loco:SetDesiredSpeed( self:GetRunSpeed() )
            end
            return
        end
        if self:IsValidTarget( self:GetTarget() ) then
            self.loco:FaceTowards( self:GetTarget():GetPos() )
        end

        coroutine.yield()

    end

end

function ENT:IsValidTarget( ent )
    if not ent then return false end
    return IsValid( ent ) and ent:GetTargetPriority() ~= TARGET_PRIORITY_NONE and ent:GetTargetPriority() ~= TARGET_PRIORITY_SPECIAL and ent:GetTargetPriority() ~= TARGET_PRIORITY_FUNNY
end

-- Hellhounds target differently
-- (Taken from OG dog since moo base's targeting uses nz_zombiebase's again)
-- Slightly modified since 'Running' is not a function anymore and is just based on animation set by navigation
function ENT:GetPriorityTarget()
    if (IsValid(self:GetDogTarget())) then --and self:CanDogTarget(self:GetDogTarget())) then   
        return self:GetDogTarget() -- Just go after our initial target

        -- if (self:IsValidTarget(self:GetDogTarget()) and self:GetDogTarget():GetNotDowned() and (!self:GetDogTarget():IsSpectating() or self:GetDogTarget():IsInCreative()) and !self:IsIgnoredTarget(self:GetDogTarget())) then
        --  return self:GetDogTarget() -- Just go after our initial target
        -- end
    end

    if self:Health() <= 0 then return end
    self:SetLastTargetCheck( CurTime() )

    --if you really would want something that atracts the zombies from everywhere you would need something like this
    local allEnts = ents.GetAll()
    --[[for _, ent in pairs(allEnts) do
        if ent:GetTargetPriority() == TARGET_PRIORITY_ALWAYS and self:IsValidTarget(ent) then
            return ent
        end
    end]]

    -- Disabled the above for for now since it just might be better to use that same loop for everything

    local bestTarget = nil
    local highestPriority = TARGET_PRIORITY_NONE
    local maxdistsqr = self:GetTargetCheckRange()^2
    local targetDist = maxdistsqr + 10

    --local possibleTargets = ents.FindInSphere( self:GetPos(), self:GetTargetCheckRange())
    for _, target in pairs(allEnts) do
        if self:IsValidTarget(target) and !self:IsIgnoredTarget(target) then
            if target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end

            local dist = self:GetRangeSquaredTo( target:GetPos() )
            if maxdistsqr <= 0 or dist <= maxdistsqr then -- 0 distance is no distance restrictions
                local priority = target:GetTargetPriority()
                if target:GetTargetPriority() > highestPriority then
                    highestPriority = priority
                    bestTarget = target
                    targetDist = dist
                elseif target:GetTargetPriority() == highestPriority then
                    if targetDist > dist then
                        highestPriority = priority
                        bestTarget = target
                        targetDist = dist
                    end
                end
                --print(highestPriority, bestTarget, targetDist, maxdistsqr)
            end
        end
    end

    if self:IsValidTarget(bestTarget) then -- If we found a valid target
        -- local targetDist = self:GetRangeSquaredTo( bestTarget:GetPos() )
        -- if targetDist < 1000 then -- Under this distance, we will break into sprint
        --  self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
        --  self.sprinting = true -- Once sprinting, you won't stop
        --  self:SetRunSpeed(250)
        -- else -- Otherwise we'll just search (towards him)
        --  self:SetRunSpeed(100)
        --  self.sprinting = nil
        -- end
        -- self.loco:SetDesiredSpeed( self:GetRunSpeed() )

        -- Apply the new target numbers
        bestTarget.hellhoundtarget = bestTarget.hellhoundtarget and bestTarget.hellhoundtarget + 1 or 1
    end

    if (!IsValid(bestTarget) or !bestTarget:IsPlayer()) then -- We can't return nil or they break, resort to old target code..
        -- Otherwise, we just loop through all to try and target again
        local allEnts = ents.GetAll()

        local bestTarget = nil
        local lowest

        --local possibleTargets = ents.FindInSphere( self:GetPos(), self:GetTargetCheckRange())

        for _, target in pairs(allEnts) do
            if self:IsValidTarget(target) then
                if target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end
                if !lowest then
                    lowest = target.hellhoundtarget -- Set the lowest variable if not yet
                    bestTarget = target -- Also mark this for the best target so he isn't ignored
                end

                if lowest and (!target.hellhoundtarget or target.hellhoundtarget < lowest) then -- If the variable exists and this player is lower than that amount
                    bestTarget = target -- Mark him for the potential target
                    lowest = target.hellhoundtarget or 0 -- And set the new lowest to continue the loop with
                end

                if !lowest then -- If no players had any target values (lowest was never set, first ever hellhound)
                    local players = player.GetAllTargetable()
                    bestTarget = players[math.random(#players)] -- Then pick a random player
                end
            end
        end

        -- if self:IsValidTarget(bestTarget) then -- If we found a valid target
        --  -- local targetDist = self:GetRangeSquaredTo( bestTarget:GetPos() )
        --  -- if targetDist < 1000 then -- Under this distance, we will break into sprint
        --  --  self:EmitSound( self.SprintSounds[ math.random( #self.SprintSounds ) ], 100 )
        --  --  self.sprinting = true -- Once sprinting, you won't stop
        --  --  self:SetRunSpeed(250)
        --  -- else -- Otherwise we'll just search (towards him)
        --  --  self:SetRunSpeed(100)
        --  --  self.sprinting = nil
        --  -- end
        --  --self.loco:SetDesiredSpeed( self:GetRunSpeed() )

        --  -- Apply the new target numbers
        --  bestTarget.hellhoundtarget = bestTarget.hellhoundtarget and bestTarget.hellhoundtarget + 1 or 1
        --  self:SetTarget(bestTarget) -- Well we found a target, we kinda have to force it

        --  if (self:GetDogRunning()) then
        --      self:SetDogTarget(bestTarget)
        --  end

        --  return bestTarget
        -- else
        --  if (self:GetDogRunning()) then
        --      self:SetDogTarget(bestTarget)
        --  end

        --  print(bestTarget)
        --  return self:GetTarget()
        -- end
    end

    --if (self:GetDogRunning()) then
        self:SetDogTarget(bestTarget)
    --end

    return bestTarget
end
