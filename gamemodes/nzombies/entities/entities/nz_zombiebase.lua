-- Please don't ever override this with a brand new base. All zombies shall always rely on this one way or another.
AddCSLuaFile()

game.AddParticles("particles/blackops3zombies_fx.pcf")


--debug cvars
CreateConVar( "nz_zombie_debug", "0", { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_CHEAT } )

--[[
    This Base is not really spawnable but it contains a lot of useful functions for its children
--]]

ENT.Base = "base_nextbot"
ENT.PrintName = "Zombie"
ENT.Category = "Brainz"
ENT.Author = "Lolle, Zet0r, Ethorbit"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.NZDisallowText = true

-- Zombie Stuffz
ENT.Models = nil -- REQUIRED! Can be a function.
-- Add these as well if randomized skins/bodygroups are BAD for your enemy. Can be functions.
ENT.Skins = nil
ENT.Bodygroups = nil

ENT.DeathDropHeight = 99999999999 -- Set to big number by Ethorbit because a drop height limit is retarded IMO
ENT.StepHeight = 22 --Default is 18 but it makes things easier
ENT.JumpHeight = 70
ENT.AttackRange = 65 --75 -- Any higher than 80 and stabbing will be almost impossible. This used to be 65, but increased for challenge.
ENT.AttackRangePassive = 65 -- Target not visible, we're breaking barricade, etc. It's best to leave at 65 or lower or we'll hit through walls far
ENT.RunSpeed = 200
ENT.WalkSpeed = 200
ENT.Acceleration = 400  --15000 -- Set to big number by Ethorbit, we want zombies to turn quickly for the difficulty
ENT.Deceleration = 400 --15000
ENT.DamageLow = 50
ENT.DamageHigh = 50

ENT.SlowOnAttack = true -- Slow down when attacking, will not work if you have PauseOnAttack set to true.
ENT.PauseOnAttack = false -- Makes them stop while attacking, usually after they swing once. Too easy to dodge, which is why it's disabled by default.
ENT.AttackDelay = 0.7 -- ^^ How long to stop or slow down when pausing on attack

--ENT.CanStrafe = true -- (OBSOLETE) Whether or not zombies will randomly move to the sides of their path. Makes them more unpredictable but also slower to reach their target. This can also be a function.

ENT.IgnoreDistractions = false -- Whether or not to ignore inanimate objects like Monkey Bombs.

ENT.BarricadeRemoveAmount = 1 -- Amount of planks to remove at once
ENT.BarricadeWaitForZombies = true -- When a barricade zombie limit is reached, wait for the zombies to go through.

-- important for ent:IsZombie()
ENT.bIsZombie = true
ENT.bSelfHandlePath = true -- PathFollower will not auto-check for barricades or navlocks

--The Accessors will be partially shared, but should only be used serverside
AccessorFunc( ENT, "fWalkSpeed", "WalkSpeed", FORCE_NUMBER)
AccessorFunc( ENT, "fRunSpeed", "RunSpeed", FORCE_NUMBER)
AccessorFunc( ENT, "fAttackRange", "AttackRange", FORCE_NUMBER)
AccessorFunc( ENT, "fAttackRangePassive", "AttackRangePassive", FORCE_NUMBER)
AccessorFunc( ENT, "fLastLand", "LastLand", FORCE_NUMBER)
AccessorFunc( ENT, "fLastTargetCheck", "LastTargetCheck", FORCE_NUMBER)
AccessorFunc( ENT, "fLastAtack", "LastAttack", FORCE_NUMBER)
AccessorFunc( ENT, "fLastHurt", "LastHurt", FORCE_NUMBER)
AccessorFunc( ENT, "fLastTargetChange", "LastTargetChange", FORCE_NUMBER)
AccessorFunc( ENT, "fTargetCheckRange", "TargetCheckRange", FORCE_NUMBER)
AccessorFunc( ENT, "fNextPlayerTarget", "NextPlayerTarget", FORCE_NUMBER)
--AccessorFunc( ENT, "fLastPlayerTarget", "LastPlayerTarget", FORCE_NUMBER)
AccessorFunc( ENT, "bAttackingPaused", "AttackingPaused", FORCE_BOOL)

--sounds
AccessorFunc( ENT, "fNextMoanSound", "NextMoanSound", FORCE_NUMBER)

--Stuck prevention
AccessorFunc( ENT, "fLastActive", "LastActive", FORCE_NUMBER)
AccessorFunc( ENT, "fLastPositionSave", "LastPositionSave", FORCE_NUMBER)
AccessorFunc( ENT, "fLastPush", "LastPush", FORCE_NUMBER)
AccessorFunc( ENT, "iStuckCounter", "StuckCounter", FORCE_NUMBER)
AccessorFunc( ENT, "vStuckAt", "StuckAt")
AccessorFunc( ENT, "bTimedOut", "TimedOut")

-- spawner accessor
AccessorFunc(ENT, "hSpawner", "Spawner")

--AccessorFunc( ENT, "bSpawned", "Spawned", FORCE_BOOL)

AccessorFunc( ENT, "bFrozen", "Frozen", FORCE_BOOL)
AccessorFunc( ENT, "bWandering", "Wandering", FORCE_BOOL)
AccessorFunc( ENT, "bJumping", "Jumping", FORCE_BOOL)
AccessorFunc( ENT, "bAttacking", "Attacking", FORCE_BOOL)
AccessorFunc( ENT, "bBarricadeBlocked", "BarricadeBlocked", FORCE_BOOL)
AccessorFunc( ENT, "bClimbing", "Climbing", FORCE_BOOL)
AccessorFunc( ENT, "bStop", "Stop", FORCE_BOOL)

-- Strafing
-- AccessorFunc( ENT, "bStrafing", "Strafing", FORCE_BOOL)
-- AccessorFunc( ENT, "fLastStrafe", "LastStrafe", FORCE_NUMBER)
-- AccessorFunc( ENT, "vStrafeDestination", "StrafeDestination", FORCE_VECTOR)
-- AccessorFunc( ENT, "vStrafeDirection", "StrafeDirection", FORCE_VECTOR)

-- Fleeing
AccessorFunc( ENT, "bFleeing", "Fleeing", FORCE_BOOL)
AccessorFunc( ENT, "fLastFlee", "LastFlee", FORCE_NUMBER)

AccessorFunc( ENT, "bSpecialAnim", "SpecialAnimation", FORCE_BOOL)
AccessorFunc( ENT, "bBlockAttack", "BlockAttack", FORCE_BOOL)

AccessorFunc( ENT, "bLastInvalidPath", "LastInvalidPath", FORCE_BOOL)
AccessorFunc( ENT, "bTargetUnreachable", "TargetUnreachable", FORCE_BOOL)

AccessorFunc( ENT, "iActStage", "ActStage", FORCE_NUMBER)

ENT.ActStages = {}

ENT.HeadshotSounds = { -- Added by Ethorbit since people want to extend this
     "nzr/zombies/death/headshot_0.wav",
     "nzr/zombies/death/headshot_1.wav",
     "nzr/zombies/death/headshot_2.wav",
     "nzr/zombies/death/headshot_3.wav",
}

local holidayEnabled = GetConVar("nzc_holiday_events")
function ENT:SetupDataTables()
    -- If you want decapitation in you zombie and overwrote ENT:SetupDataTables() make sure to add self:NetworkVar("Bool", 0, "Decapitated") again.
    self:NetworkVar("Bool", 31, "Decapitated")
    self:NetworkVar("Bool", 30, "Spawned")
    if self.InitDataTables then self:InitDataTables() end
end

function ENT:Precache()
    self.Models = !isfunction(self.Models) and self.Models or self:Models()

    for _,v in pairs(self.Models) do
        util.PrecacheModel(v.Model or v )
    end

    -- Let's merge all of these into 1 loop - Ethorbit
    for _,soundtbl in pairs({
        self.HeadshotSounds,
        self.AttackSounds, self.AttackHitSounds,
        self.PainSounds, self.DeathSounds,
        self.WalkSounds, self.RunSounds
    }) do
        if soundtbl then
            for _,v in pairs(soundtbl) do
                util.PrecacheSound( v )
            end
        end
    end
end
--Init

function ENT:GetDebugging()
    return self.debugvar and self.debugvar:GetBool()
end


-- Collision helper functions added by Ethorbit so that custom enemies don't need to hardcode the collision type
function ENT:EnableCollision()
    if (nzMapping and nzMapping.Settings and !nzMapping.Settings.zombiecollisions) then
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    else
        self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
    end
end

function ENT:DisableCollision()
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
end

function ENT:Initialize()
    self:SetSpawned(false)
    self.debugvar = GetConVar("nz_zombie_debug")

    self:SetAttackingPaused(false)
    self.FrozenTime = 0

    self.LastSpawnTime = CurTime()
    self.spawnedat = self:GetPos() -- Property added by Ethorbit for auto zombie unstucker
    self:Precache()

    if self.Models then
        local mdl = self.Models[math.random( #self.Models )]
        if mdl then
            self:SetModel( mdl.Model or mdl )
        end
    end

    self:SetStop(false)
    self:SetBarricadeBlocked(false)
    self:SetJumping( false )
    self:SetLastHurt(0)
    self:SetLastLand( CurTime() + 1 ) --prevent jumping after spawn
    self:SetLastTargetCheck( CurTime() )
    self:SetLastTargetChange( CurTime() )
    self:SetTargetUnreachable(true)
    self:SetFleeing(false)
    self:SetLastFlee(0)
    --self:SetLastStrafe(0)

    self:SetNextPlayerTarget(0)
    --self:SetLastPlayerTarget(0)

    --self:SetRenderMode(RENDERMODE_TRANSCOLOR)


    if CLIENT and NZEvent and NZEvent != "NONE" then
        if (holidayEnabled and holidayEnabled:GetInt() > 0) then
            if (NZEvent == "Christmas") then
                self.CustomModelColor = table.Random({Color(255, 0, 0), Color(0, 255, 0)})
            end
        end

        --self.CustomModelColor = Color(255,255,255,1)
        --self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    end

    --sounds
    self:SetNextMoanSound( CurTime() + 1 )

    --stuck prevetion
    self:SetLastPush( CurTime() )
    self:SetLastPositionSave( CurTime() )
    self:SetLastActive(CurTime())
    self:SetStuckAt( self:GetPos() )
    self:SetStuckCounter( 0 )

    self:SetAttacking( false )
    self:SetLastAttack( CurTime() )
    self:SetAttackingPaused(false)
    self:SetAttackRange(self.AttackRange)
    self:SetAttackRangePassive(self.AttackRangePassive)
    self:SetTargetCheckRange(0) -- 0 for no distance restriction (infinite)

    --target ignore
    self:ResetIgnores()

    self:SetHealth( 75 ) --fallback
    if SERVER then
        self:SetMaxHealth( 75 ) -- additional fallback by Ethorbit so that the zombie won't die instantly
    end
    
    self:SetRunSpeed( self.RunSpeed ) --fallback
    self:SetWalkSpeed( self.WalkSpeed ) --fallback

    self:SetCollisionBounds(Vector(-16,-16, 0), Vector(16, 16, 70))

    self:EnableCollision()

    self:SetActStage(0)
    self:SetSpecialAnimation(false)

    self:StatsInitialize()
    self:SpecialInit()

    self:SetCustomCollisionCheck(false)

    if SERVER then
        self.loco:SetDeathDropHeight( self.DeathDropHeight )
        self.loco:SetDesiredSpeed(self:GetRunSpeed())
        self.loco:SetAcceleration(self.Acceleration)
        self.loco:SetDeceleration(self.Deceleration)
        self.loco:SetJumpHeight(self.JumpHeight)
        self.loco:SetMaxYawRate(400)
        self.loco:SetAvoidAllowed(false)

        if GetConVar("nz_zombie_lagcompensated"):GetBool() then
            self:SetLagCompensated(true)
        end
        self.BarricadeJumpTries = 0

        if (nzRound:GetSpawnRadius() == 0) then
            self:SetTargetCheckRange(0) -- 0 is Infinite
        else
            self:SetTargetCheckRange(math.Clamp(nzRound:GetSpawnRadius() or 2500, 1200, math.huge))
        end
    end

    -- Set bodygroups (Improved by Ethorbit)
    local bodygroups = self.Bodygroups and isfunction(self.Bodygroups) and self:Bodygroups() or self.Bodygroups or nil

    for i,v in ipairs(self:GetBodyGroups()) do
        if !bodygroups then
             self:SetBodygroup( i-1, math.random(0, self:GetBodygroupCount(i-1) - 1))
        else
             if bodygroups[i - 1] then
                 if istable(bodygroups[i - 1]) then -- They want a random part from this bodygroup
                     self:SetBodygroup(i - 1, table.Random(bodygroups[i - 1]))
                 else -- They just want a specific part from the group
                     self:SetBodygroup(i - 1,  bodygroups[i - 1])
                 end
             end
        end
    end

    -- Set skins (Improved by Ethorbit)
    local skin
    if self.Skins then
         skinVal = isfunction(self.Skins) and self:Skins() or self.Skins
         skin = skinVal[math.random(#skinVal)]
    else
         skin = math.random(self:SkinCount()) - 1
    end

    if skin then
         self:SetSkin(skin)
    end

    self.ZombieAlive = true

    self:SetWandering(false)
    self:SetFrozen(false)

    self:CreateTrigger()
    self:OnInitialize()
end

function ENT:OnInitialize() -- OVERRIDE
end

function ENT:StatsInitialize() end -- OVERRIDE

function ENT:CreateTrigger() -- By Ethorbit, Zombies now have triggers that cover their collision bounds so we can do really cool things like force projectiles to collide!
    if CLIENT then return end

    self:RemoveTrigger()

    self.CollisionTrigger = ents.Create("nz_trigger")
    self.CollisionTrigger:SetPos(self:GetPos())
    self.CollisionTrigger:SetParent(self, 0)

    -- No idea if this positioning will work for all entities, I know it works with Zombie, Nova Crawler, Panzer and Dogs.
    local max = self:OBBMaxs() + (self.ExtraTriggerBounds or Vector(0,0,0))
    self.CollisionTrigger:SetLocalPos(Vector(-max[1] / 2, -max[2] / 2, 0))
    self.CollisionTrigger:SetMaxBound(max)

    self.CollisionTrigger:Spawn()

    self.ForcedCollisions = {}
    self.CollisionTrigger:ListenToTriggerEvent(function(event, ent)
        if event != "Touch" then return end
        if ent:IsPlayer() then return end

        if !self.ForcedCollisions[ent] or CurTime() > self.ForcedCollisions[ent] then
            local phys_obj = ent:GetPhysicsObject()

            -- Simulate PhysicsCollide if it's defined (So projectiles actually hit us)
            if ent.PhysicsCollide then
                self.ForcedCollisions[ent] = CurTime() - 0.1

                if !IsValid(phys_obj) then
                    phys_obj = ent
                end

                local ent_speed = ent:GetVelocity():Length2D()
                local ents_dir = (ent:GetPos() - self:GetPos()):GetNormalized()

                ent:PhysicsCollide({ -- Simulate PhysicsCollide (This is what most projectiles rely on)
                    ["HitPos"] = ent:GetPos(),
                    ["HitEntity"] = self,
                    ["OurOldVelocity"] = ent:GetVelocity(),
                    ["TheirOldVelocity"] = self:GetVelocity(),
                    ["Speed"] = ent_speed, -- Is this right?
                    ["HitSpeed"] = ent_speed, -- Is this right?
                    ["DeltaTime"] = CurTime(), -- Is this right??
                    ["HitNormal"] = ents_dir
                }, phys_obj)
            end
        end
    end)

    return self.CollisionTrigger
end

function ENT:RemoveTrigger()
    if CLIENT then return end
    if IsValid(self:GetTrigger()) then
        self:GetTrigger():Remove()
    end
end

function ENT:GetTrigger()
    if CLIENT then return end
    return self.CollisionTrigger
end

-- Created by Ethorbit to replace the C++ BecomeRagdoll function.
-- The original BecomeRagdoll has been identified as the root cause for a majority of crashes.

-- BecomeRagdoll is one of those functions that Facepunch didn't add to lua, meaning the functionality of it is
-- in the C++ source code and as such, there's no way to replace the function or modify its code.

-- Instead, I took a slightly different approach, but feel free to improve upon it.
function ENT:StableBecomeRagdoll(dmginfo) -- Deletes zombie, tells clients to render the ragdoll in its place
    local pos,mdl = self:GetPos(),self:GetModel()

    SafeRemoveEntity(self)

    nzRagdolls.Create(mdl, pos, dmginfo, nzRagdolls.GetBodyGroupTableFromEntity(self), self.DeathSounds and {
            ["SoundName"] = self.DeathSounds[ math.random( #self.DeathSounds ) ],
            ["Channel"] = CHAN_VOICE
        } or nil
    )
end

function ENT:ScaleNPCDamage( npc, hitgroup, dmginfo ) -- Added from the nextbot base to make it more obvious, by: Ethorbit
    if hitgroup == HITGROUP_LEFTARM ||
    hitgroup == HITGROUP_RIGHTARM ||
    hitgroup == HITGROUP_LEFTLEG ||
    hitgroup == HITGROUP_RIGHTLEG ||
    hitgroup == HITGROUP_GEAR then
        dmginfo:ScaleDamage( 0.25 )
    end
end

-- We can't actually override GetMaxHealth or SetMaxHealth. It was all an illusion. Sad..
--function ENT:GetMaxHealth() -- Added to easily know the max health of a specific zombie (useful for weapons and stuff)
--    return self.MaxAllowedHealth
--end
 
--function ENT:SetMaxHealth(hp) -- ^^^
--    print(self, "SetMaxHealth", hp)
--    self.MaxAllowedHealth = hp
--end

function ENT:GetLastSpawnTime() -- Used to see how long a zombie has existed for, added by: Ethorbit
    return self.LastSpawnTime
end

--init for class related attributes hooks etc...
function ENT:SpecialInit()
    --print("PLEASE Override the base class!")
end

function ENT:StatsInit()
    --print("PLEASE Override the base class!")
end

function ENT:MakeDust(magnitude) -- Added by Ethorbit, moved the original base's dust code here.
    -- We use SNPC particles which apparently breaks this NZ classic smoke and causes tearing / glitching across the screen
    --magnitude = magnitude or 1000

    --local effectData = EffectData()
    --effectData:SetStart( self:GetPos() + Vector(0,0,32) )
    --effectData:SetOrigin( self:GetPos() + Vector(0,0,32) )
    --effectData:SetMagnitude(magnitude)
    --util.Effect("zombie_spawn_dust", effectData)
    

    -- This is the new SNPC particle:
    ParticleEffect("bo3_zombie_spawn",self:GetPos()+Vector(0,0,1),self:GetAngles(),self)
    self:EmitSound("nz/zombies/spawn/zm_spawn_dirt"..math.random(1,2)..".wav",80,math.random(95,105))
end

function ENT:Think()
    if CLIENT then
        if (self.CustomModelColor) then
            self:SetColor(self.CustomModelColor)
        end
    end

    if SERVER then --think is shared since last update but all the stuff in here should be serverside
        -- This will only happen if a retard overrides the gamemode's damage handling or breaks it from outside.
        -- So not actually necessary, but it doesn't hurt.
        --if self:Health() < 0 then
        --    self:SetHealth(0)
        --end

        -- This can happen if the zombie died without OnKilled getting called
        if self:GetMaxHealth() <= 0 or !self.Health or self:Health() == nil then
            print("zombie's MaxHealth just went under Health. Killing so it's not invincible.", self)
            self:Kill()
        end

        if self.SlowOnAttack and self:GetAttackingPaused() then
            self.loco:SetVelocity(self:GetForward() * math.Clamp(self:GetRunSpeed(), self:GetRunSpeed(), 150))
        elseif (self:IsAllowedToMove() and self.loco:GetCurrentAcceleration():Length2D() < self:GetRunSpeed()) then
            --if isStrafe then -- Force them to look where they're strafing so they don't spin out of control and look dumb
            --    self.loco:SetVelocity(strafeVel)
            --elseif CurTime() - 0.1 > self:GetLastStrafe() then  -- Fix made by Ethorbit, to make the zombies NOT SLOW DOWN FOR PLAYERS which ruined the game immersion
            self.loco:SetVelocity(self:GetForward() * self:GetRunSpeed())
            --self.loco:SetAcceleration(self:GetRunSpeed() * 20)
            --end
        end

        if !self:IsJumping() and !self:GetSpecialAnimation() and (self:GetSolidMask() == MASK_NPCSOLID_BRUSHONLY or self:GetSolidMask() == MASK_SOLID_BRUSHONLY) then
            local occupied = false
            local tr = util.TraceHull( {
                start = self:GetPos(),
                endpos = self:GetPos(),
                filter = self,
                mins = Vector( -20, -20, -0 ),
                maxs = Vector( 20, 20, 70 ),
                mask = MASK_NPCSOLID
            } )

            if !tr.HitNonWorld then
                self:SetSolidMask(MASK_NPCSOLID)
                --self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                --print("No longer no-colliding")
            end
            --[[for _,ent in pairs(ents.FindInBox(self:GetPos() + Vector( -16, -16, 0 ), self:GetPos() + Vector( 16, 16, 70 ))) do
                if ent:GetClass() == "nz_zombie*" and ent != self then occupied = true end
            end
            if !occupied then self:SetSolidMask(MASK_NPCSOLID) end]]
        end

        if self.loco:IsUsingLadder() then
            --self:SetSolidMask(MASK_NPCSOLID_BRUSHONLY)
        end

        if self:GetLastTargetCheck() + 0.1 < CurTime() then
            if (IsInDeadlyTrigger(self)) then
                self:Kill()
            end
        end

        --this is a very costly operation so we only do it every second
        if self:GetLastTargetCheck() + 1 < CurTime() then
            self:SetTarget(self:GetPriorityTarget())

            -- It is OK to do this, the Anti-Cheat stops players from going this far too. Fair is fair.
            local nav = navmesh.GetNearestNavArea(self:GetPos(), false, 75, false, true)
            if (IsValid(self) and !IsValid(nav) and !self:IsJumping() and self:IsOnGround()) then
                if (self:Health() > 0) then
                    ServerLog("Zombie went too far from navmesh\n")
                    self:RespawnZombie()
                end
            end
        end

        -- We don't want to say we're stuck if it's because we're attacking or timed out
        if !self:GetAttacking() and !self:GetTimedOut() and self:GetLastPositionSave() + 4 < CurTime() then
            if self:GetPos():Distance( self:GetStuckAt() ) < 10 then
                self:SetStuckCounter( self:GetStuckCounter() + 1)
            else
                self:SetStuckCounter( 0 )
            end

            if self:GetStuckCounter() > 2 then
                local tr = util.TraceHull({
                    start = self:GetPos(),
                    endpos = self:GetPos(),
                    maxs = self:OBBMaxs(),
                    mins = self:OBBMins(),
                    filter = self
                })
                if tr.Hit then
                    --if there bounding box is intersecting with something there is now way we can unstuck them just respawn.
                    --make a dust cloud to make it look less ugly
                    self:MakeDust(1)
                    self:RespawnZombie()
                    self:SetStuckCounter( 0 )
                end

                if self:GetStuckCounter() <= 3 then
                    --try to unstuck via random velocity
                    self:ApplyRandomPush()
                end

                -- if self:GetStuckCounter() > 3 and self:GetStuckCounter() <= 5 then
                --  --try to unstuck via jump
                --  self:Jump()
                -- end

                --print(self:GetStuckCounter())

                if self:GetStuckCounter() > 5 then
                    --Worst case:
                    --respawn the zombie after 32 seconds with no Position change
                    self:RespawnZombie()
                    self:SetStuckCounter( 0 )
                end

            end
            self:SetLastPositionSave( CurTime() )
            self:SetStuckAt( self:GetPos() )
        end

        --sounds
        self:SoundThink()

        -- if self:ZombieWaterLevel() == 3 then
        --  self:RespawnZombie()
        -- end

        self:DebugThink()

    end
    self:OnThink()
end

function ENT:DebugThink()
    if self:GetDebugging() then
        local spacing = Vector(0,0,64)
        local target = self:GetTarget()
        if target then
            debugoverlay.Text( self:GetPos() + spacing, tostring(target), FrameTime() * 2 )
        else
            debugoverlay.Text( self:GetPos() + spacing, "NO_TARGET", FrameTime() * 2 )
        end
        spacing = spacing + Vector(0,0,8)
        local attacking = self:IsAttacking()
        if attacking then
            debugoverlay.Text( self:GetPos() + spacing, "IN_ATTACK", FrameTime() * 2 )
        elseif self:IsTimedOut() then
            debugoverlay.Text( self:GetPos() + spacing, "TIMED_OUT", FrameTime() * 2 )
        elseif target then
            debugoverlay.Text( self:GetPos() + spacing, "MOVING_TO_TARGET", FrameTime() * 2 )
        else
            debugoverlay.Text( self:GetPos() + spacing, "ERROR", FrameTime() * 2 )
        end
        spacing = spacing + Vector(0,0,8)
        debugoverlay.Text( self:GetPos() + spacing, "HitPoints: " .. tostring(self:Health()), FrameTime() * 2 )
        spacing = spacing + Vector(0,0,8)
        debugoverlay.Text( self:GetPos() + spacing, tostring(self), FrameTime() * 2 )
    end
end

function ENT:SoundThink()
    if CurTime() > self:GetNextMoanSound() and !self:GetStop() then
        local soundtbl = self.ActStages[self:GetActStage()] and self.ActStages[self:GetActStage()].sounds or self.WalkSounds
        if soundtbl then
            local soundName = soundtbl[math.random(#soundtbl)]
            self:EmitSound( soundName, 80 )
            local nextSound = SoundDuration( soundName ) + math.random(0,4) + CurTime()
            self:SetNextMoanSound( nextSound )
        end
    end
end

function ENT:GetFleeDestination(target) -- Get the place where we are fleeing to, added by: Ethorbit
    return self:GetPos() + (self:GetPos() - target:GetPos()):GetNormalized() * (self.FleeDistance or 300)
end

function ENT:RunBehaviour()

    self:SpawnZombie()

    while (true) do
        if !self:GetStop() and self:GetFleeing() then -- Admittedly this was rushed, I took no time to understand how this can be achieved with nextbot pathing so I just made a short navmesh algorithm for fleeing. Sorry. Created by Ethorbit.
            self:SetTimedOut(false)

            local target = self:GetTarget()
            if IsValid(target) then
                self:SetLastFlee(CurTime())
                self:MoveToPos(self:GetFleeDestination(target), {lookahead = 0, maxage = 3})
                self:SetLastFlee(CurTime())
            end
        end

        if !self:GetFleeing() and !self:GetStop() and CurTime() > self:GetLastFlee() + 2 then
            self:SetTimedOut(false)
            if self:HasTarget() then
                local pathResult = self:ChaseTarget( {
                    maxage = 1,
                    draw = false,
                    tolerance = self:GetSpecialAnimation() and 0 or ((self:GetAttackRange() -30) > 0 ) and self:GetAttackRange() - 20
                } )

                if pathResult == "failed" then
                    self:SetTargetUnreachable(true)
                end

                if pathResult == "ok" then
                    if self:TargetInAttackRange() then
                        self:OnTargetInAttackRange()
                    else

                        --self:TimeOut(1)
                        --self:TimeOut(0) -- Commented out because putting any kind of timeout here will needlessly slow down the zombies
                    end
                elseif pathResult == "timeout" then --asume pathing timedout, maybe we are stuck maybe we are blocked by barricades
                    local barricade, dir = self:CheckForBarricade()
                    if barricade then
                        self:OnBarricadeBlocking( barricade, dir )
                    else
                        self:SetTargetUnreachable(true)
                        self:OnPathTimeOut()
                    end
                else
                    --self:TimeOut(2)
                    self:TimeOut(0)
                    -- path failed what should we do :/?
                end
            else
                -- Game over! Walk around randomly
                if nzRound:InState( ROUND_GO ) then -- Moved out of OnNoTarget by Ethorbit, why should an enemy override this? What else is there to do?
                    self:WanderAround()
                else
                    self:OnNoTarget()
                end
            end

            self:RunBehaviourLoop()

            coroutine.yield() -- Added by Ethorbit, probably should've been here. Not that it really matters..
        else
            --self:TimeOut(2)
            self:TimeOut(0.1)
        end
    end
end

function ENT:WanderAround()
    self:SetWandering(true)
    self:StartActivity(ACT_WALK)
    self.loco:SetDesiredSpeed(40)
    self:MoveToPos(self:GetPos() + Vector(math.random(-512, 512), math.random(-512, 512), 0), {
        repath = 3,
        maxage = 5
    })
end

function ENT:RunBehaviourLoop() end -- This is for other 'bases' so that they don't need to override RunBehaviour to add code onto to the loop.

function ENT:DissolveEffect()
    local effect = EffectData()
    effect:SetScale(1)
    effect:SetMagnitude(1)
    effect:SetScale(3)
    effect:SetRadius(1)
    effect:SetStart(self:GetPos())
    effect:SetOrigin(self:GetPos())
    effect:SetEntity(self)
    effect:SetMagnitude(100)
    util.Effect("TeslaHitboxes", effect)

    self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav")
end

function ENT:OnTakeDamage(dmginfo)
    if (dmginfo:GetDamageType() == DMG_DISSOLVE and dmginfo:GetDamage() >= self:Health() and self:Health() > 0) then
        self:DissolveEffect()
    end

    self:SetLastHurt(CurTime())
end

function ENT:Stop()
    self:SetStop(true)
    self:SetTarget(nil)
end

--Draw correct eyes
local eyeglow =  Material( "nzr/nz/zlight" )
local defaultColor = Color(0, 255, 255, 255)

local holidayEnabled = GetConVar("nzc_holiday_events")

function ENT:Draw()
    --if !self:GetSpawned() then return end -- Do not render zombies that haven't spawned yet - Ethorbit
    self:DrawModel()

    if CLIENT then
        if (NZEvent == "April Fools") then
            if (!self.AprilFoolsModelScale) then
                self.AprilFoolsModelScale = math.Rand(0.45, 1.5)
            else
                self:SetModelScale(self.AprilFoolsModelScale)
            end

            -- if (self.CustomModelColor) then
            --  self:SetColor(self.CustomModelColor)
            -- end
        end
    end

    if (!zombieEyeRenderInt or zombieEyeRenderInt and zombieEyeRenderInt > 0) then
        local eyeColor
        if (holidayEnabled and holidayEnabled:GetInt() > 0) then
            if (NZEvent == "Christmas") then
                eyeColor = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)) -- Christmas light eyes
            end

            --if (NZEvent == "Halloween") then eyeColor = Color(255,255,255) end
        end

        if (!eyeColor) then
            eyeColor = !IsColor(nzMapping.Settings.zombieeyecolor) and defaultColor or nzMapping.Settings.zombieeyecolor
        end

        if self.RedEyes then
            --local eyes = self:GetAttachment(self:LookupAttachment("eyes")).Pos
            --local leftEye = eyes + self:GetRight() * -1.5 + self:GetForward() * 0.5
            --local rightEye = eyes + self:GetRight() * 1.5 + self:GetForward() * 0.5

            local lefteye = self:GetAttachment(self:LookupAttachment("lefteye"))
            local righteye = self:GetAttachment(self:LookupAttachment("righteye"))

            if !lefteye then lefteye = self:GetAttachment(self:LookupAttachment("left_eye")) end
            if !righteye then righteye = self:GetAttachment(self:LookupAttachment("right_eye")) end

            local righteyepos
            local lefteyepos

            if lefteye and righteye then
                lefteyepos = lefteye.Pos + self:GetForward() * 1.0
                righteyepos = righteye.Pos+ self:GetForward() * 1.0
            else
                local eyes = self:GetAttachment(self:LookupAttachment("eyes"))
                if eyes then
                    lefteyepos = eyes.Pos + self:GetRight() * -1.5 + self:GetForward() * 1.0
                    righteyepos = eyes.Pos + self:GetRight() * 1.5 + self:GetForward() * 1.0
                end
            end

            if lefteyepos and righteyepos then
                cam.Start3D(EyePos(),EyeAngles())
                    render.SetMaterial(eyeglow)
                    render.DrawSprite( lefteyepos, 4, 4, eyeColor)
                    render.DrawSprite( righteyepos, 4, 4, eyeColor)
                cam.End3D()
            end
        end
        if self:GetDebugging() then
            render.DrawWireframeBox(self:GetPos(), Angle(0,0,0), self:OBBMins(), self:OBBMaxs(), Color(255,0,0), true)
            render.DrawWireframeSphere(self:GetPos(), self:GetAttackRange(), 10, 10, Color(255,165,0), true)
        end
    end

    -- local mins, maxs = self:GetCollisionBounds()
    -- mins[3] = mins[3] / 2
    -- maxs[3] = maxs[3] / 2

    -- local startpos = self:GetPos() + self:OBBCenter() / 2
    -- local endpos = startpos + self:GetForward() * 20

    -- debugoverlay.Box(startpos, mins, maxs, 0, Color(255,0,0) )
    -- debugoverlay.Box(endpos, mins, maxs, 0, Color(255,0,0, 50) )

    -- local tr = util.TraceHull({
    --  ["start"] = startpos,
    --  ["endpos"] = endpos,
    --  ["filter"] = self,
    --  ["collisiongroup"] = self:GetCollisionGroup()
    -- })

    if self:GetDebugging() then
        if self:IsMovingIntoObject() then
            debugoverlay.Sphere(self:GetPos(), 20, 0, Color(255,255,255), true)
        end
    end

    self:OnDraw()
end

function ENT:OnDraw()
end

--[[
    Events
    You can easily override them.
    Todo: Add Hooks
--]]

function ENT:SpawnZombie()
    --BAIL if no navmesh is near
    local nav = navmesh.GetNearestNavArea( self:GetPos() )
    if !self:IsInWorld() or !IsValid(nav) or nav:GetClosestPointOnArea( self:GetPos() ):DistToSqr( self:GetPos() ) >= 10000 then
        ErrorNoHalt("Zombie ["..self:GetClass().."]["..self:EntIndex().."] spawned too far away from a navmesh! (at: " .. tostring(self:GetPos()) .. ")")
        self:RespawnZombie()
    end
    
    self:SetSpawned(true)
    self:OnSpawn()
end

function ENT:OnSpawn()

end

function ENT:OnTargetInAttackRange()
    --if self:GetFleeing() then print("hello?") return end

    if !self:GetBlockAttack() then
        self:Attack()

        if self:GetRunSpeed() > 60 then -- Don't stop them if they're slow (just for the challenge)
            self:TimeOut(0.3)
        end
    elseif (self:GetBlockAttack()) then -- DO NOT REMOVE THIS or the game will crash when a player is in attack distance during their barricade animations
        self:TimeOut(0.1)
    end
end

function ENT:OnBarricadeBlocking( barricade, dir )
    if (IsValid(barricade) and barricade:GetClass() == "breakable_entry") then
        local barricade_has_planks = barricade:GetNumPlanks() > 0

        if self.BarricadeWaitForZombies and barricade_has_planks and (barricade:HasMaxZombies() and !barricade:HasZombie(self)) then
            self:TimeOut(0.1)
        return end

        if barricade_has_planks then
            barricade:AddZombie(self)

            timer.Simple(0.3, function()
                barricade:EmitSound("nzr/zombies/barricade_removed/break_board_" .. math.random(0, 5) .. ".wav", 100, math.random(90, 130))
                barricade:RemovePlank(self.BarricadeRemoveAmount)
            end)

            self:SetAngles(Angle(0,(barricade:GetPos()-self:GetPos()):Angle()[2],0))

            local seq, dur

            local attacktbl = self.ActStages[1] and self.ActStages[1].attackanims or self.AttackSequences
            if isfunction(attacktbl) then attacktbl = attacktbl() end
            local target = type(attacktbl) == "table" and attacktbl[math.random(#attacktbl)] or attacktbl

            if type(target) == "table" then
                seq, dur = self:LookupSequenceAct(target.seq)
            elseif target then -- It is a string or ACT
                seq, dur = self:LookupSequenceAct(target)
            else
                seq, dur = self:LookupSequence("swing")
            end

            self:SetAttacking(true)
            self:PlayAttackAndWait(seq, 1)
            self:SetLastAttack(CurTime())
            self:SetAttacking(false)
            self:UpdateSequence()
            if coroutine.running() then
                coroutine.wait((2 - dur) + 0.5)
            end

            -- this will cause zombies to attack the barricade until it's destroyed
            local stillBlocked, dir = self:CheckForBarricade()
            if stillBlocked then
                self:SetBarricadeBlocked(true)
                self:OnBarricadeBlocking(stillBlocked, dir)
                return
            else
                --self:TimeOut(0.2)
                self:SetBarricadeBlocked(false)
                barricade:RemoveZombie(self)
            end

            -- Attacking a new barricade resets the counter
            self.BarricadeJumpTries = 0
        -- Modified by Ethorbit, all barricades are jump-through now to get around 
        -- the horrible unfixable player collision exploits and other issues that occur with walk-through barriers
        elseif self.TriggerBarricadeJump then --barricade:GetTriggerJumps() and self.TriggerBarricadeJump then
            local dist = barricade:GetPos():DistToSqr(self:GetPos())
            if dist <= 3500 + (1000 * self.BarricadeJumpTries) then
                self:TriggerBarricadeJump(barricade, dir)
                self.BarricadeJumpTries = 0
            else
                -- If we continuously fail, we need to increase the check range (if it is a bigger prop)
                self.BarricadeJumpTries = self.BarricadeJumpTries + 1
                -- Otherwise they'd get continuously stuck on slightly bigger props :(
            end
        else
            self:SetAttacking(false)
        end
    end
end

function ENT:SetTimedOut()
    --ENT:IsTimedOut(true)
end

function ENT:JumpToTargetHeight(height) -- Created by Ethorbit, mainly to help combat cheaters
    local jumpHeight = height or math.abs(self:GetTarget():GetPos()[3] - self:GetPos()[3]) * 1.5

    self.loco:SetJumpHeight(jumpHeight)
    self:Jump()
    self.loco:SetJumpHeight(self.JumpHeight)
end

function ENT:TimeOut(time, dont_reaquire_target) -- Modified by Ethorbit to make use of the Ignore system
    if !dont_reaquire_target then
        if !nzRound:InState( ROUND_GO ) then
            --self:IgnoreTarget(self:GetTarget())
            local newtarget = self:GetPriorityTarget()

            self:SetTarget(newtarget)
            if (newtarget == nil and !self.NextAllowedResetIgnore or (self.NextAllowedResetIgnore and CurTime() > self.NextAllowedResetIgnore)) then
                self:ResetIgnores()
                --self:RespawnZombie()
            else
                self.NextAllowedResetIgnore = CurTime() + 4 -- So if they have no target for 4 second straight, then we remove all our ignores.
            end
        end
    end

    --time = 0.1
    self:SetTimedOut(true)
    self.timedout = true
    if coroutine.running() then
        coroutine.wait(time)
        self.timedout = false
    end
end

function ENT:OnPathTimeOut()
end

function ENT:OnNoTarget()
    self:IgnoreTarget(self:GetTarget())
    --self:TimeOut(0.5)
    self:TimeOut(0.1)
    -- Start off by checking for a new target
    local newtarget = self:GetPriorityTarget()
    if self:IsValidTarget(newtarget) then
        self:SetTarget(newtarget)
    else
        -- If not visible to players respawn immediately
        if !self:IsInSight() then
            self:RespawnZombie()
        else
            self:ResetIgnores()
            self:UpdateSequence() -- Updates the sequence to be idle animation
            if isnumber(self.CalcIdeal) then
                self:StartActivity(self.CalcIdeal) -- Starts the newly updated sequence
                --self:TimeOut(3) -- Time out even longer if seen
                self:TimeOut(0.1)
            end
        end
    end
end

function ENT:OnContactWithTarget()

end

function ENT:OnLandOnGroundZombie()

end

function ENT:OnThink()
    --debugoverlay.Sphere(self:GetPos(), 53, 1)
end

--Default NEXTBOT Events
function ENT:OnLandOnGround()
    if self:Alive() then
        self:EmitSound("physics/flesh/flesh_impact_hard" .. math.random(1, 6) .. ".wav")
        self:SetJumping( false )
        if self:HasTarget() then
            self.loco:SetDesiredSpeed(self:GetRunSpeed())
        else
            self.loco:SetDesiredSpeed(self:GetWalkSpeed())
        end
        self.loco:SetAcceleration(self.Acceleration)
        self.loco:SetDeceleration(self.Deceleration)
        self.loco:SetStepHeight( 22 )
        self:SetLastLand(CurTime())
        self:OnLandOnGroundZombie()
    end
end

function ENT:OnLeaveGround( ent )
    self:SetJumping( true )
end

function ENT:OnNavAreaChanged(old, new)
    if bit.band(new:GetAttributes(), NAV_MESH_JUMP) != 0 then
        --dont make jumps in the wrong direction
        if old:ComputeGroundHeightChange( new ) < 0 then
            return
        end
        self:Jump()
    end
end

-- COLLISION_GROUP_DEBRIS if players should be allowed through them
            -- COLLISION_GROUP_INTERACTIVE if players are not meant to go through them


function ENT:OnContact( ent )
    -- if nzConfig.ValidEnemies[ent:GetClass()] and nzConfig.ValidEnemies[self:GetClass()] then
    --  --this is a poor approach to unstuck them when walking into each other
    --  self.loco:Approach( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 2000,1000)
    --  --important if the get stuck on top of each other!
    --  --if math.abs(self:GetPos().z - ent:GetPos().z) > 30 then self:SetSolidMask( MASK_NPCSOLID_BRUSHONLY ) end
    -- end
    --buggy prop push away thing comment if you dont want this :)
    
    --self.loco:Approach( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 2000,1000)

    if self:IsTarget( ent ) then
        self:OnContactWithTarget()
    end
end

function ENT:OnInjured( dmgInfo )
    if (IsValid(dmgInfo:GetAttacker()) and dmgInfo:GetAttacker():IsValidZombie()) then -- No team damage, added by: Ethorbit
        dmgInfo:ScaleDamage(0)
    return end

    if (math.floor(self:Health() - dmgInfo:GetDamage()) <= 0) then -- Die from floats correctly, added by: Ethorbit
        dmgInfo:SetDamage(self:Health() * 2)
        self.ForceKilled = true
    return end

    local attacker = dmgInfo:GetAttacker()
    if self:IsValidTarget( attacker ) then
        self:SetTarget( attacker )
    end

    if self.PainSounds then
        local soundName = self.PainSounds[ math.random( #self.PainSounds ) ]
        if soundName then
               self:EmitSound( soundName, 90 )
        end
    end
end

function ENT:OnZombieDeath(dmgInfo)
    self:BecomeRagdoll(dmgInfo)
end

function ENT:Alive()
    return self.ZombieAlive
end

function ENT:OnKilled(dmgInfo)
    --self:TimedEvent(0, function()
    if dmgInfo and dmgInfo:GetDamageType() == DMG_DISSOLVE then
        self:DissolveEffect()
    end

    if dmgInfo and self:Alive() then -- Only call once!
        self:OnZombieDeath(dmgInfo)
    end

    if !self.DidDecapitation then
        self.DidDecapitation = true
        self:TryDecapitation(dmgInfo)
    end
    
    --end)

    self.ZombieAlive = false

    hook.Call("OnZombieKilled", GAMEMODE, self, dmgInfo)
    self:RemoveTrigger()
    self:OnPostKilled()
end

function ENT:TryDecapitation(dmgInfo) -- Added by Ethorbit to move the logic out of OnKilled
    local headbone = self.HeadBone and self:LookupBone(self.HeadBone) or self:LookupBone("ValveBiped.Bip01_Head1")
    if !headbone then headbone = self:LookupBone("j_head") end
    if headbone then
        local headPos = self:GetBonePosition(headbone)
        local dmgPos = dmgInfo:GetDamagePosition()
        local inflictor = dmgInfo:GetInflictor()

        -- it will not always trigger since the offset can be larger than 12
        -- but I think it's fine not to decapitate every headshotted zombie
        if self.SetDecapitated then
            if nzPowerUps:IsPowerupActive("insta") or (!inflictor or !inflictor.NoHeadshots) and (dmgInfo:GetForcedHeadshot() or (headPos and dmgPos and headPos:Distance(dmgPos) < 12)) then
                self:SetDecapitated(true)

                    local soundName = self.HeadshotSounds[ math.random(#self.HeadshotSounds) ]
                    self:EmitSound( soundName, 90 )
            end
        end
    end
end

function ENT:OnPostKilled() -- OVERRIDE
end

function ENT:OnRemove()
    --self:RemoveTrigger()
end

function ENT:OnStuck()
    --
    --self.loco:Approach( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 2000, 1000 )
    --print("Now I'm stuck", self)
end

--Target and pathfidning
function ENT:GetPriorityTarget()
    self:SetLastTargetCheck( CurTime() )

    local curTarget = self:GetTarget()

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
        if (IsValid(target)) then
            if !target:IsPlayer() and target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS then return target end

            if self:IsValidTarget(target) and !self:IsIgnoredTarget(target) then
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
    end

    -- if !bestTarget and self:IsIgnoredTarget(self:GetTarget()) then
    --  self:TimeOut(2, true)
    -- end

    -- Added by Ethorbit to stop zombies from changing player targets way too frequently
    if IsValid(bestTarget) and bestTarget:IsPlayer() then
        if IsValid(curTarget) and curTarget:IsPlayer() and bestTarget:GetTargetPriority() == curTarget:GetTargetPriority() and !self:IsTargetDead(curTarget) then
            if CurTime() < self:GetNextPlayerTarget() then
                return curTarget
            end
        end

        self:SetNextPlayerTarget(CurTime() + math.Rand(2, 5))
    end

    if bestTarget == nil and IsValid(self:GetTarget()) then
        return self:GetTarget()
    end

    return bestTarget
end

function ENT:FleeTarget(time) -- Added by Ethorbit, instead of pathing TO a player, it paths AWAY from them
    local target = self:GetTarget()
    if !IsValid(target) then return end

    local tr = util.TraceLine({
        start = self:GetPos() + Vector(0,0,50),
        endpos = self:GetFleeDestination(target) + Vector(0,0,50),
        filter = self,
        collisiongroup = COLLISION_GROUP_DEBRIS
    })

    if tr.Hit then return end

    self:SetFleeing(true)

    timer.Create(self:GetClass() .. "FleeingTarget" .. self:EntIndex(), time, 1, function()
        if IsValid(self) and self:GetFleeing() then
            self:SetFleeing(false)
        end
    end)
end

function ENT:StopFleeing() -- Cancel the fleeing, created by: Ethorbit
    --self:SetLastFlee(CurTime())
    self:SetFleeing(false)
end

function ENT:ChaseTarget( options )
    options = options or {}

    if !options.target then
        options.target = self:GetTarget()
    end

    local path = self:ChaseTargetPath( options )

    if ( !IsValid(path) ) then
        self:SetLastInvalidPath(CurTime())
        self:IgnoreTarget(self:GetTarget())
        return "failed"
    end

    -- if (IsValid(path)) then
    --  self.ExcludedTargets = {}
    -- end

    while ( path:IsValid() and self:HasTarget() and !self:TargetInAttackRange() ) do
        path:Update( self )

        --if (CurTime() > self:GetLastInvalidPath() + 0.5) then
            --self:SetLastInvalidPath(0)
            self:SetTargetUnreachable(false)
        --end

        --Timeout the pathing so it will rerun the entire behaviour (break barricades etc)
        if ( path:GetAge() > options.maxage ) then
            local segment = path:FirstSegment()
            self.BarricadeCheckDir = segment and segment.forward or Vector(0,0,0)
            return "timeout"
        end

        path:Update( self ) -- This function moves the bot along the path
        if options.draw or self:GetDebugging() then
            path:Draw()
        end

        --the jumping part simple and buggy
        --local scanDist = (self.loco:GetVelocity():Length()^2)/(2*900) + 15
        local scanDist
        --this will probaly need asjustments to fit the zombies speed
        if self:GetVelocity():Length2D() > 150 then scanDist = 30 else scanDist = 20 end
        --debug section
        if self:GetDebugging() then
            debugoverlay.Line( self:GetPos(),  path:GetClosestPosition(self:EyePos() + self.loco:GetGroundMotionVector() * scanDist), 0.05, Color(0,0,255,0) )
            local losColor  = Color(255,0,0)
            if self:IsLineOfSightClear( self:GetTarget():GetPos() + Vector(0,0,35) ) then
                losColor = Color(0,255,0)
            end
            debugoverlay.Line( self:EyePos(),  self:GetTarget():GetPos() + Vector(0,0,35), 0.03, losColor )
            --[[local nav = navmesh.GetNearestNavArea( self:GetPos() )
            if IsValid(nav) and nav:GetClosestPointOnArea( self:GetPos() ):DistToSqr( self:GetPos() ) < 2500 then
                debugoverlay.Line( nav:GetCorner( 0 ),  nav:GetCorner( 1 ), 0.05, Color(255,0,0), true )
                debugoverlay.Line( nav:GetCorner( 0 ),  nav:GetCorner( 3 ), 0.05, Color(255,0,0), true )
                debugoverlay.Line( nav:GetCorner( 1 ),  nav:GetCorner( 2 ), 0.05, Color(255,0,0), true )
                debugoverlay.Line( nav:GetCorner( 2 ),  nav:GetCorner( 3 ), 0.05, Color(255,0,0), true )
                for _,v in pairs(nav:GetAdjacentAreas()) do
                    debugoverlay.Line( v:GetCorner( 0 ),  v:GetCorner( 1 ), 0.05, Color(150,80,0,80), true )
                    debugoverlay.Line( v:GetCorner( 0 ),  v:GetCorner( 3 ), 0.05, Color(150,80,0,80), true )
                    debugoverlay.Line( v:GetCorner( 1 ),  v:GetCorner( 2 ), 0.05, Color(150,80,0,80), true )
                    debugoverlay.Line( v:GetCorner( 2 ),  v:GetCorner( 3 ), 0.05, Color(150,80,0,80), true )
                end
            end ]]--
        end
        --print(self.loco:GetGroundMotionVector(), self:GetForward())
        local goal = path:GetCurrentGoal()
        if !goal then
            local jumpHeight = math.abs(self:GetTarget():GetPos()[3] - self:GetPos()[3]) * 2
            if jumpHeight > 100 then -- While we do want them to jump to make exploiting on props harder, we DON'T want them to jump if the player is not high enough away
                local should_attack = true --math.random(3) == 1 -- We mainly want to jump at cheaters, but let's also hit them randomly so they shit their pants
                if jumpHeight > 150 then -- Hitting them from here won't do shit, just jump.
                    should_attack = false
                end

                if should_attack then -- The reason we force attack instead of letting them auto attack when close enough during jump, is because they can't jump when a player is likely on top of them
                    self:Attack()
                else
                    self:JumpToTargetHeight(jumpHeight)
                end
            end
        end

        -- Teleport to destination when we get stuck moving there.
        -- if self:GetVelocity() == Vector(0,0,0) then
        --  -- if goal then
        --  --  local goal_tr_endpos = self:GetPos() + ((goal.pos - self:GetPos()):GetNormalized() * 20)
        --  --  local goal_tr = self:TraceSelf(self:GetPos(), goal_tr_endpos)

        --  --  if goal_tr.Hit then -- Something's obstructing our path!
        --  --      print("Was I hit?")
        --  --      self:SetPos(goal.pos)
        --  --      if IsValid(goal_tr.Entity) and goal_tr.Entity:IsPlayer() then
        --  --          print("Stair bug")

        --  --      end
        --  --  end
        --  -- end
        -- end

        --height triggered jumping
        if path:IsValid() and math.abs(self:GetPos().z - path:GetClosestPosition(self:EyePos() + self.loco:GetGroundMotionVector() * scanDist).z) > 22 and (goal and goal.type != 1) then
            self:Jump()
        end
        --[[if path:IsValid() and goal.type == 4 then
            --self.loco:SetVelocity( Vector( 0, 0, 1000 ) )
            self:SetPos( path:GetClosestPosition( goal.ladder:GetTopForwardArea():GetCenter() ) )
            self:SetClimbing( true )
            coroutine.wait( 0.5 )
            self:SetSolidMask( MASK_NPCSOLID_BRUSHONLY )
            return "timeout"
            if self.loco:IsUsingLadder() then
                self.loco:SetVelocity( self.loco:GetVelocity() + Vector( 0, 0, 50 ) )
            end
        end --]]

        -- If we're stuck, then call the HandleStuck function and abandon
        if ( self.loco:IsStuck() ) then
            self:HandleStuck()
            return "stuck"
        end

        -- Push us when moving into things
        if self:IsMovingIntoObject() then
            -- Push any props near us before we push ourselves
            for _,ent in pairs(ents.FindInSphere(self:GetPos(), 90)) do 
                if ent != self and !ent:IsValidZombie() and !ent.NZEntity and !ent:IsPlayer() then 
                    local phys = ent:GetPhysicsObject()
                    if IsValid(phys) then
                        DropEntityIfHeld(ent) -- Just in case

                        -- Moved from NZ classic's OnContact to here.
                        local force = -physenv.GetGravity().z * phys:GetMass() / 5 * ent:GetFriction()
                        local dir = ent:GetPos() - self:GetPos()
                        dir:Normalize()
                        phys:ApplyForceCenter(dir * force)
                    end 
                end 
            end 

            self:ApplyRandomPush(400)
        end

        coroutine.yield()

    end

    return "ok"

end

function ENT:ChaseTargetPath( options )
    options = options or {}

    local path = Path( "Follow" )
    path:SetMinLookAheadDistance( 0 )
    path:SetGoalTolerance( 10 )

    --[[local targetPos = options.target:GetPos()
    --set the goal to the closet navmesh
    local goal = navmesh.GetNearestNavArea(targetPos, false, 100)
    goal = goal and goal:GetClosestPointOnArea(targetPos) or targetPos--]]

    -- Strafing added by Ethorbit to make the zombies spread out a bit
    -- Difficulty by unpredictability
    -- local newDest = options.target:GetPos()
    -- local isStrafed = false
    -- self:SetStrafing(false)
    -- local maxOffset = 5 -- Increase for them to spread farther out. The bigger it is, the slower they reach the player.
    -- local canStrafe = isfunction(self.CanStrafe) and self:CanStrafe() or self.CanStrafe
    -- if canStrafe and math.random(100) <= 40 then -- Chance to move right or left instead of towards the target. This makes training a little harder.
    --  if CurTime() + 4 > self:GetLastStrafe() then -- But don't strafe too often, we'd go too far off our path otherwise.
    --         --if options.target:Visible(self) then -- Make sure we are not obstructed from the player, otherwise our strafing would be pointless as it's meant to overwhelm players
    --             if !self:TargetInRange(self:GetAttackRange() + 110) then -- Make sure we're not too close to them, so we don't end up strafing directly into them, unfairly ending a game...
    --                 local dir = (self:GetPos() - options.target:GetPos()):GetNormalized()
    --              dir:Rotate(Angle(0,90,0)) -- This ensures we only go to the right or left from the direction we're looking at the player at
    --              local offset = math.random(-maxOffset, maxOffset)
    --              local offset = math.random(100) <= 50 and -offset or offset
    --              local offsettedPos = dir * offset
    --              local tr = self:TraceSelfToPos(nil, offsettedPos, true) -- Do a trace so we don't try to go through walls lol
    --                 --math.randomseed(CurTime())
    --
    --              if !tr.Hit then
    --                     if self:CanStandOnPosition(tr.HitPos) and options.target:VisibleVec(tr.HitPos) then -- Make sure we don't strafe off a platform and that we're only strafing when inside player view
    --                      self:SetLastStrafe(CurTime())
    --                      newDest = tr.HitPos
    --                      self:SetStrafeDestination(tr.HitPos)
    --                      self:SetStrafeDirection(tr.Normal)
    --                      self:SetStrafing(true)
    --                      isStrafed = true
    --                     end
    --              end
    --          end
    --         --end
    --  end
    -- end

    -- Custom path computer, the same as default but not pathing through locked nav areas.
    -- Change newDest if you want to modify their goal
    path:Compute( self, options.target:GetPos(), function( area, fromArea, ladder, elevator, length )
        if ( !IsValid( fromArea ) ) then
            -- First area in path, no cost
            return 0
        else
            if ( !self.loco:IsAreaTraversable( area ) ) then
                -- Our locomotor says we can't move here
                return -1
            end
            -- Prevent movement through either locked navareas or areas with closed doors
            if (nzNav.Locks[area:GetID()]) then
                if nzNav.Locks[area:GetID()].link then
                    if !nzDoors:IsLinkOpened( nzNav.Locks[area:GetID()].link ) then
                        self:IgnoreTarget(self:GetTarget())
                        return -1
                    end
                elseif nzNav.Locks[area:GetID()].locked then
                return -1 end

                -- if !nzNav.Locks[area:GetID()] then
                -- end
            end
            -- Compute distance traveled along path so far
            local dist = 0
            --[[if ( IsValid( ladder ) ) then
                dist = ladder:GetLength()
            elseif ( length > 0 ) then
                --optimization to avoid recomputing length
                dist = length
            else
                dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
            end]]--
            local cost = dist + fromArea:GetCostSoFar()
            --check height change
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
            if ( deltaZ >= self.loco:GetStepHeight() ) then
                -- use player default max jump height even thouh teh zombie will jump a bit higher
                if ( deltaZ >= 64 ) then
                    --Include ladders in pathing:
                    --currently disableddue to the lack of a loco:Climb function
                    --[[if IsValid( ladder ) then
                        if ladder:GetTopForwardArea():GetID() == area:GetID() then
                            return cost
                        end
                    end --]]
                    --too high to reach
                    return -1
                end
                --jumping is slower than flat ground
                local jumpPenalty = 1.1
                cost = cost + jumpPenalty * dist
            elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
                --too far to drop
                return -1
            end
            return cost
        end
    end)

    -- this will replace nav groups
    -- we do this after pathing to know when this happens
    local lastSeg = path:LastSegment()

    -- a little more complicated that i thought but it should do the trick
    if lastSeg then
        if IsValid(self:GetTargetNavArea()) and lastSeg.area:GetID() != self:GetTargetNavArea():GetID() then -- and !self:GetStrafing()
            if !nzNav.Locks[self:GetTargetNavArea():GetID()] or nzNav.Locks[self:GetTargetNavArea():GetID()].locked then
                if (!self:IsIgnoredTarget(self:GetTarget())) then
                    -- We won't be getting to this player, so let's
                    -- go after someone else. /Ethorbit
                    self:IgnoreTarget(self:GetTarget(), 2)
                    self:SetLastTargetCheck(CurTime() - 1)
                else
                    -- All players are out of reach and ignored,
                    -- we should pause so the game doesn't lag out /Ethorbit
                    self:SetNextPlayerTarget(0)
                    self:TimeOut(1)
                end

                return nil
            end
        else
            self:FreeIgnores()
            --self:ResetIgnores()
            return path
        end
    end

    return path

end

function ENT:GetLadderTop( ladder )
    return ladder:GetTopForwardArea() or ladder:GetTopBehindArea() or ladder:GetTopRightArea() or ladder:GetTopLeftArea()
end

function ENT:TargetInAttackRange()
    local range = self:GetAttackRange()
    local isInRange = self:TargetInRange(range - 10)

    if isInRange then
        if (self:GetAttackRange() <= self:GetAttackRangePassive()) then return true end -- Nothing else to do..

        -- Change range to Passive if we're doing Passive things..
        local target = self:GetTarget()

        if !target:Visible(self) then
            range = self:GetAttackRangePassive()
        else
            local tr = util.TraceLine({
                start = (self:GetPos() + self:OBBCenter() / 2),
                endpos = target:GetPos(),
                filter = self
            })

            if IsValid(tr.Entity) and tr.Entity:GetClass() == "breakable_entry" then
                range = self:GetAttackRangePassive()
            end
        end

        return self:GetRangeTo(target:GetPos()) < range
    else
        return false
    end
end

function ENT:TargetInZRange() -- Made to help detect when players are blocking zombies just out of their reach, created by: Ethorbit
    if self:GetVelocity() != Vector(0,0,0) then return false end -- We only really care if they have blocked us from moving

    local target = self:GetTarget()
    if !IsValid(target) then return false end

    local diff = target:GetPos() - self:GetPos()
    local zDot = diff:Dot(self:GetUp())
    return zDot >= 70 and zDot < 82 and target:GetPos():DistToSqr(self:GetPos()) <= 82^2
end

function ENT:TargetInRange( range )
    local target = self:GetTarget()
    if !IsValid(target) then return false end

    local in_z_range = self:TargetInZRange()
    if in_z_range then
        if !target:Visible(self) then
            return false
        else
            return true
        end
    end

    return self:GetRangeTo( target:GetPos() ) < range
end

function ENT:CheckForBarricade(distance)
    --we try a line trace first since its more efficient
    local dataL = {}
    dataL.start = self:GetPos() + Vector( 0, 0, self:OBBCenter().z )
    dataL.endpos = self:GetPos() + Vector( 0, 0, self:OBBCenter().z ) + self.BarricadeCheckDir * (48 or distance)
    dataL.filter = function( ent ) if ( ent:GetClass() == "breakable_entry" ) then return true end end
    dataL.ignoreworld = true
    local trL = util.TraceLine( dataL )

    --debugoverlay.Line(self:GetPos() + Vector( 0, 0, self:OBBCenter().z ), self:GetPos() + Vector( 0, 0, self:OBBCenter().z ) + self.BarricadeCheckDir * 32)
    --debugoverlay.Cross(self:GetPos() + Vector( 0, 0, self:OBBCenter().z ), 1)

    if IsValid( trL.Entity ) and trL.Entity:GetClass() == "breakable_entry" then
        return trL.Entity, trL.HitNormal
    end

    -- Perform a hull trace if line didnt hit just to make sure
    local dataH = {}
    dataH.start = self:GetPos()
    dataH.endpos = self:GetPos() + self.BarricadeCheckDir * (48 or distance)
    dataH.filter = function( ent ) if ( ent:GetClass() == "breakable_entry" ) then return true end end
    dataH.mins = self:OBBMins() * 0.65
    dataH.maxs = self:OBBMaxs() * 0.65
    local trH = util.TraceHull(dataH )

    if IsValid( trH.Entity ) and trH.Entity:GetClass() == "breakable_entry" then
        return trH.Entity, trH.HitNormal
    end

    return nil

end

-- function ENT:TargetIsVisible(target)

-- end

function ENT:GetTargetDirection() -- Made by Ethorbit because I'm lazy
    if !IsValid(self:GetTarget()) then return Vector(0,0,0) end -- whatever...
    return (self:GetPos() - self:GetTarget():GetPos()):GetNormalized()
end

-- A standard attack you can use it or create something fancy yourself
function ENT:Attack( data, force )
    self:SetLastAttack(CurTime())
    --if self:Health() <= 0 then coroutine.yield() return end

    data = data or {}
    data.attacksound = data.attacksound
    data.attackmisssound = data.attackmisssound

    if !force then
        data.attackseq = data.attackseq
        if !data.attackseq then
            local curstage = self:GetActStage()
            local actstage = self.ActStages[curstage]
            if !actstage and curstage <= 0 then actstage = self.ActStages[1] end

            local attacktbl = actstage and actstage.attackanims or self.AttackSequences
            if isfunction(attacktbl) then attacktbl = attacktbl() end

            local target = type(attacktbl) == "table" and attacktbl[math.random(#attacktbl)] or attacktbl
            if target and target.dmg then
                data.dmglow = target.dmg
                data.dmghigh = target.dmg
            end

            if !data.attacksound and !self.BlodHardcodedAttackSound then
                local soundtbl = target.attacksounds or self.AttackSounds
                data.attacksound = soundtbl and soundtbl[math.random(#soundtbl)] or Sound( "npc/vort/claw_swing1.wav" )
            end

            if !data.attackmisssound and !self.BlodHardcodedAttackMissSound then
                local soundtbl = target.attackmisssounds or self.AttackMissSounds
                data.attackmisssound = soundtbl and soundtbl[math.random(#soundtbl)] or Sound( "npc/vort/claw_swing1.wav" )
            end

            if type(target) == "table" then
                local id, dur = self:LookupSequenceAct(target.seq)
                data.attackseq = {seq = id, dmgtimes = target.dmgtimes or {0.5}}
                data.attackdur = dur
            elseif target then -- It is a string or ACT
                local id, dur = self:LookupSequenceAct(attacktbl)
                data.attackseq = {seq = id, dmgtimes = {dur/2}}
                data.attackdur = dur
            else
                local id, dur = self:LookupSequence("swing")
                data.attackseq = {seq = id, dmgtimes = {1}}
                data.attackdur = dur
            end
        end
    end


    -- if !data.attacksound and !self.BlodHardcodedAttackSound then
    --  local actstage = self.ActStages[self:GetActStage()]
    --  local soundtbl = actstage and actstage.attacksounds or self.AttackSounds
    --  data.attacksound = soundtbl and soundtbl[math.random(#soundtbl)] or Sound( "npc/vort/claw_swing1.wav" )
    -- end

    data.hitsound = data.hitsound
    if !data.hitsound then
        local actstage = self.ActStages[self:GetActStage()]
        local soundtbl = actstage and actstage.attackhitsounds or self.AttackHitSounds
        data.hitsound = soundtbl and soundtbl[math.random(#soundtbl)] or Sound( "npc/zombie/zombie_hit.wav" )
    end

    data.viewpunch = data.viewpunch or VectorRand():Angle() * 0.05
    data.dmglow = data.dmglow or self.DamageLow or 25
    data.dmghigh = data.dmghigh or self.DamageHigh or 45
    data.dmgtype = data.dmgtype or DMG_CLUB

    local dmgForceMultiplier = isfunction(self.GetDamageForceMultiplier) and self:GetDamageForceMultiplier() or self.DamageForceMultiplier
    local dmgForceExtra = isfunction(self.GetDamageForceExtra) and self:GetDamageForceExtra() or self.DamageForceExtra
    data.dmgforce = data.dmgforce or (self:GetTarget():GetPos() - self:GetPos()) * (7 + (dmgForceMultiplier or 0)) + Vector( 0, 0, 16 ) + (dmgForceExtra or Vector(0,0,0))
    data.dmgforce.z = math.Clamp(data.dmgforce.z, 1, 16)

    if !self.BlockHardcodedSwingSound then
        self:EmitSound("npc/zombie_poison/pz_throw2.wav", 50, math.random(75, 125))
    end

    self:SetAttacking( true )

    self:TimedEvent(0.1, function()
        if data.attacksound then
            self:EmitSound( data.attacksound )
        end
    end)

    if self:GetTarget():IsPlayer() then
        --if (self:Visible(self:GetTarget())) then
            if force then
                data.attackseq = {}
                data.attackseq.dmgtimes = {0}
            end

            data = self.GetNewAttackData and self:GetNewAttackData(table.Copy(data)) or data -- you could technically remove table.Copy so coders don't need to specify a return, but we want to keep consistency.

            for k,v in pairs(data.attackseq.dmgtimes) do
                local v = isfunction(v) and v(self) or v
                self:TimedEvent( v, function()
                    if !self:GetStop() and self:IsValidTarget( self:GetTarget() ) and self:TargetInRange( self:GetAttackRange() + 10 ) then
                        if !self:CanHurtTarget(data) then return end

                        local dmgAmount = math.random( data.dmglow, data.dmghigh )
                        local dmgInfo = DamageInfo()
                            dmgInfo:SetAttacker( self )
                            dmgInfo:SetDamage( dmgAmount )
                            dmgInfo:SetDamageType( data.dmgtype )
                            dmgInfo:SetDamageForce( data.dmgforce )
                        self:GetTarget():TakeDamageInfo(dmgInfo)

                        if !IsValid(self:GetTarget()) then return end
                        self:GetTarget():EmitSound( data.hitsound, 50, math.random( 80, 160 ) )

                        if (isfunction(self:GetTarget().ViewPunch)) then
                            self:GetTarget():ViewPunch( data.viewpunch )
                        end

                        self:GetTarget():SetVelocity( data.dmgforce )

                        --if self:GetTarget():IsPlayer() then
                            -- local ply = self:GetTarget()
                            -- ply:SetRunSpeed(ply:GetRunSpeed("hurt"))
                            -- ply:SetWalkSpeed(ply:GetWalkSpeed("hurt"))

                            -- timer.Simple(0.5, function()
                            --     if IsValid(ply) then
                            --         ply:SetRunSpeed(ply:GetRunSpeed("default"))
                            --         ply:SetWalkSpeed(ply:GetWalkSpeed("default"))
                            --     end
                            -- end)
                        --end

                        local blood = ents.Create("env_blood")
                        blood:SetKeyValue("targetname", "carlbloodfx")
                        blood:SetKeyValue("parentname", "prop_ragdoll")
                        blood:SetKeyValue("spawnflags", 8)
                        blood:SetKeyValue("spraydir", math.random(500) .. " " .. math.random(500) .. " " .. math.random(500))
                        blood:SetKeyValue("amount", dmgAmount * 5)
                        blood:SetCollisionGroup( COLLISION_GROUP_WORLD )
                        blood:SetPos( self:GetTarget():GetPos() + self:GetTarget():OBBCenter() + Vector( 0, 0, 10 ) )
                        blood:Spawn()
                        blood:Fire("EmitBlood")
                        SafeRemoveEntityDelayed( blood, 2) -- Just to make sure everything gets cleaned

                        self:OnAttack(self:GetTarget())
                    elseif data.attackmisssound then
                        self:EmitSound(data.attackmisssound)
                    end
                end)
            end
        --end
    end

    if IsValid(self) then
        self:SetAttackingPaused(true)

        self:TimedEvent(self.AttackDelay, function()
            if IsValid(self) then
                self:SetAttackingPaused(false)
            end
        end)
    end

    if !force then
        self:TimedEvent(data.attackdur, function()
            self:SetAttacking(false)
            self:SetLastAttack(CurTime())
        end)

        self:PlayAttackAndWait(data.attackseq.seq, 1)
    end
end

function ENT:CanHurtTarget() -- OVERRIDE
    return true
end

function ENT:OnAttack(target) -- OVERRIDE
end

function ENT:PlayAnimation(name, speed) -- Play an animation without disrupting movement. Created by: Ethorbit.
    local len = self:SetSequence( name )
    speed = speed or 1

    self:ResetSequenceInfo()
    self:SetCycle( 0 )
    self:SetPlaybackRate( speed )

    local endtime = CurTime() + len / speed
    return {["len"] = len, ["speed"] = speed, ["endtime"] = endtime}
end

ENT.AllowedAnimations = {}
ENT.StoppingAnimations = {}

-- Adds the activity to the BodyUpdate queue, if it has the highest priority,
-- GetBodyUpdateActivity() will return it until the animation or specified time is up
function ENT:StartBodyUpdateSequence(sequence_name, cb, playback_rate, priority, time) -- (Created by Ethorbit)
    if self:GetTimedOut() or self:GetClimbing() or self:GetJumping() or self:IsGettingPushed() then return end
    if self:GetWandering() then return end
    if self.FrozenTime and CurTime() < self.FrozenTime then return end

    local sequence_int = self:LookupSequence(sequence_name)
    time = time or self:SequenceDuration(sequence_int)
    priority = priority or table.Count(self.AllowedAnimations)
    playback_rate = playback_rate or 1

    local activity_name = self:GetSequenceActivity(sequence_int) -- BodyUpdate only cares about Activity names

    local i = #self.AllowedAnimations + 1
    self.AllowedAnimations[i] = {
        ["priority"] = priority,
        ["activity_name"] = activity_name,
        ["sequence_name"] = sequence_name,
        ["playback_rate"] = playback_rate
    }

    table.SortByMember(self.AllowedAnimations, "priority")

    if !self.StoppingAnimations[i] then
        self.StoppingAnimations[i] = true

        self:TimedEvent(time / playback_rate, function()
            if playback_rate != 1 then
                self:SetPlaybackRate(1)
            end

            self.AllowedAnimations[i] = nil
            self.StoppingAnimations[i] = false

            if isfunction(cb) then
                cb()
            end
        end)
    end

    return {["duration"] = time, ["endtime"] = time / playback_rate}
end

function ENT:StopBodyUpdateSequence(sequence_name) -- Stop the sequence name played with: StartBodyUpdateSequence, created by: Ethorbit
    for k,anim in pairs(self.AllowedAnimations) do
        if anim.sequence_name == sequence_name then
            self.StoppingAnimations[k] = false
            table.remove(self.AllowedAnimations, k)
        end
    end
end

function ENT:IsPlayingCustomBodyActivity() -- Check if an animation from StartBodyUpdateSequence is running, created by: Ethorbit
    return #self.AllowedAnimations > 0
end

function ENT:GetBodyUpdateData() -- Get current BodyUpdate sequence details, created by: Ethorbit
    return #self.AllowedAnimations > 0 and self.AllowedAnimations[1] or nil
end

function ENT:GetBodyUpdateActivity() -- For use inside BodyUpdate, returns the active animation with the highest priority. Set the CalcIdeal to this. Created by: Ethorbit
    return #self.AllowedAnimations > 0 and self.AllowedAnimations[1].activity_name or nil
end

function ENT:PlayIdleAndWait( name, speed ) -- Play an animation, but don't move when doing it. Created by: Ethorbit
    local data = self:PlayAnimation(name, speed)

    while ( true ) do

        if ( data.endtime < CurTime() ) then
            if !self:GetStop() then
                self:StartActivity( ACT_WALK )
                self.loco:SetDesiredSpeed( self:GetRunSpeed() )
            end
            return
        end
        -- if self:IsValidTarget( self:GetTarget() ) and self:TargetInRange( self:GetAttackRange() * 2  ) then
        --  self.loco:SetDesiredSpeed( self:GetRunSpeed() / 3 )
        --  self.loco:Approach( self:GetTarget():GetPos(), 10 )
        --  self.loco:FaceTowards( self:GetTarget():GetPos() )
        -- end

        coroutine.yield()

    end

end

function ENT:PlayAttackAndWait( name, speed ) -- Modified by Ethorbit, moved the animating part to its own method
    local data = self:PlayAnimation(name, speed)

    while ( true ) do

        if ( data.endtime < CurTime() ) then
            if !self:GetStop() then
                self:StartActivity( ACT_WALK )
                self.loco:SetDesiredSpeed( self:GetRunSpeed() )
            end
            return
        end
        if self:IsValidTarget( self:GetTarget() ) and self:TargetInRange( self:GetAttackRange() * 2  ) then
            self.loco:SetDesiredSpeed( self:GetRunSpeed() / 3 )
            self.loco:Approach( self:GetTarget():GetPos(), 10 )
            self.loco:FaceTowards( self:GetTarget():GetPos() )
        end

        coroutine.yield()

    end

end

--we do our own jump since the loco one is a bit weird.
function ENT:Jump(vel)
    if (self:GetStop()) then return end

    --local nav = navmesh.GetNavArea(self:GetPos(), 100)
    --if (!IsValid(nav) or IsValid(nav) and nav:HasAttributes(NAV_MESH_NO_JUMP)) then return end
    if CurTime() < self:GetLastLand() + 0.5 then return end
    if !self:IsOnGround() then return end
    self.loco:SetDesiredSpeed( 450 )
    self.loco:SetAcceleration(5000)
    self.loco:SetDeceleration(self.Deceleration)
    self:SetJumping( true )
    --self:SetSolidMask( MASK_NPCSOLID_BRUSHONLY )
    self.loco:Jump()
    --Boost them
    self:TimedEvent( 0.5, function() self.loco:SetVelocity( vel or (self:GetForward() * 5) ) end)
end

function ENT:Flames( state )
    if state then
        self.FlamesEnt = ents.Create("env_fire")
        if IsValid( self.FlamesEnt ) then
            self.FlamesEnt:SetParent(self)
            self.FlamesEnt:SetOwner(self)
            self.FlamesEnt:SetPos(self:GetPos() - Vector(0, 0, -50))
            --no glow + delete when out + start on + last forever
            self.FlamesEnt:SetKeyValue("spawnflags", tostring(128 + 32 + 4 + 2 + 1))
            self.FlamesEnt:SetKeyValue("firesize", (1 * math.Rand(0.7, 1.1)))
            self.FlamesEnt:SetKeyValue("fireattack", 0)
            self.FlamesEnt:SetKeyValue("health", 0)
            self.FlamesEnt:SetKeyValue("damagescale", "-10") -- only neg. value prevents dmg

            self.FlamesEnt:Spawn()
            self.FlamesEnt:Activate()
        end
    elseif IsValid( self.FlamesEnt )  then
        self.FlamesEnt:Remove()
        self.FlamesEnt = nil
    end
end

function ENT:Explode(dmg, suicide)

    suicide = suicide or true

    local ex = ents.Create("env_explosion")
    if !IsValid(ex) then return end
    ex:SetPos(self:GetPos())
    ex:SetKeyValue( "iMagnitude", tostring( dmg ) )
    ex:SetOwner(self)
    ex:Spawn()
    ex:Fire("Explode",0,0)
    ex:EmitSound( "weapons/explode" .. math.random( 3, 5 ) .. ".wav" )
    ex:Fire("Kill",0,0)

    if suicide then self:TimedEvent( 0, function() self:Kill() end ) end

end

function ENT:Kill(dmginfo, noprogress, noragdoll)
    dmginfo = dmginfo or DamageInfo()
    --if (self:Health() <= 0) then return end -- This would cause a crash with some things like Paralyzer

    local dmg = dmginfo or DamageInfo()

    if noragdoll then
        self:Fire("Kill",0,0)
        self:BecomeRagdoll(dmg)
    end
    if !noprogress then
        nzEnemies:OnEnemyKilled(self, dmg:GetAttacker(), dmg, 0)
    end
    self:OnKilled(dmginfo)
    --self:TakeDamage( 10000, self, self )
end

function ENT:RespawnZombie()
    if SERVER then
        if self:GetSpawner() then
            self:GetSpawner():IncrementZombiesToSpawn()
            self:GetSpawner():DecrementZombiesSpawned()
            self:GetSpawner():MarkNextZombieAsRespawned()
        end

        self:Remove()
    end
end

function ENT:Freeze(time)
    --self:TimeOut(time)
    self:SetFrozen(true)
    self:SetStop(true)
    self.FrozenTime = CurTime() + time

    self:TimedEvent(time, function()
        self:SetFrozen(false)
    end)
end

function ENT:IsInSight(ply)
    local players = ply and {ply} or player.GetAll()
    for _, ply in pairs(players) do
        --can player see us or the teleport location
        if ply:Alive() and ply:IsLineOfSightClear( self ) then
            if ply:GetAimVector():Dot((self:GetPos() - ply:GetPos()):GetNormalized()) > 0 then
                return true
            end
        end
    end
end

function ENT:TeleportToTarget( silent )

    if !self:HasTarget() then return false end

    --that's probably not smart, just like me. SORRY D:
    local locations = {
        Vector( 256, 0, 0),
        Vector( -256, 0, 0),
        Vector( 0, 256, 0),
        Vector( 0, -256, 0),
        Vector( 256, 256, 0),
        Vector( -256, -256, 0),
        Vector( 512, 0, 0),
        Vector( -512, 0, 0),
        Vector( 0, 512, 0),
        Vector( 0, -512, 0),
        Vector( 512, 512, 0),
        Vector( -512, -512, 0),
        Vector( 1024, 0, 0),
        Vector( -1024, 0, 0),
        Vector( 0, 1024, 0),
        Vector( 0, -1024, 0),
        Vector( 1024, 1024, 0),
        Vector( -1024, -1024, 0)
    }

    --resource friendly shuffle
    local rand = math.random
    local n = #locations

    while n > 2 do

        local k = rand(n) -- 1 <= k <= n

        locations[n], locations[k] = locations[k], locations[n]
        n = n - 1

    end

    for _, v in pairs( locations ) do

        local area = navmesh.GetNearestNavArea( self:GetTarget():GetPos() + v )

        if area then

            local location = area:GetRandomPoint() + Vector( 0, 0, 2 )

            local tr = util.TraceHull( {
                start = location,
                endpos = location,
                maxs = Vector( 16, 16, 40 ), --DOGE is small
                mins = Vector( -16, -16, 0 ),
            } )

            --debugoverlay.Box( location, Vector( -16, -16, 0 ), Vector( 16, 16, 40 ), 5, Color( 255, 0, 0 ) )

            if silent then
                if !tr.Hit then
                    local inFOV = false
                    for _, ply in pairs( player.GetAllPlayingAndAlive() ) do
                        --can player see us or the teleport location
                        if ply:Alive() and ply:IsLineOfSightClear( location ) or ply:IsLineOfSightClear( self ) then
                            inFOV = true
                        end
                    end
                    if !inFOV then
                        self:SetPos( location )
                        return true
                    end
                end
            else
                self:SetPos( location )
            end
        end
    end

    return false

end

--broken
function ENT:InFieldOfView( pos )

    local fov = math.rad( math.cos( 110 ) )
    local v = ( Vector( pos.x, pos.y, 0 ) - Vector( self:GetPos().x, self:GetPos().y, 0 ) ):GetNormalized()

    if self:GetAimVector():Dot( v ) > fov then
        local tr = util.TraceLine( {
            start = self:GetShootPos(),
            endpos = pos + Vector( 0, 0, 64),
            filter = self
        } )

        if !tr.Hit then return true end

    end

    return true

end

function ENT:IsAllowedToMove() -- Added by Ethorbit to help with my new stutter and speed fixes
    if self:GetTargetUnreachable() then
        return false
    end

    if self:GetTimedOut() or self:GetClimbing() or self:GetJumping() or self:IsGettingPushed() then
        return false
    end

    if self:GetWandering() then
        return false
    end

    if self.FrozenTime and CurTime() < self.FrozenTime then
        return false
    end

    if !self:IsOnGround() then
        return false
    end

    if self.PauseOnAttack and self:GetAttackingPaused() then
        return false
    end

    return true
end

function ENT:BodyUpdate()

    self.CalcIdeal = ACT_IDLE

    local velocity = self:GetVelocity()

    local len2d = velocity:Length2D()

    local range = 10

    local curstage = self.ActStages[self:GetActStage()]
    local nextstage = self.ActStages[self:GetActStage() + 1]

    if self:GetActStage() <= 0 then -- We are currently idling, no range to start walking
        if nextstage and len2d >= nextstage.minspeed then -- We DO NOT apply the range here, he needs to walk at 5 speed!
            self:SetActStage( self:GetActStage() + 1 )
        end
        -- If there is no minspeed for the next stage, someone did something wrong and we just idle :/
    elseif (curstage and len2d <= curstage.minspeed - range) then
        self:SetActStage( self:GetActStage() - 1 )
    elseif (nextstage and len2d >= nextstage.minspeed + range) then
        self:SetActStage( self:GetActStage() + 1 )
    elseif !self.ActStages[self:GetActStage() - 1] and len2d < curstage.minspeed - 4 then -- Much smaller range to go back to idling
        self:SetActStage(0)
    end

    curstage = self.ActStages[self:GetActStage()]

    if curstage and curstage.act then
        local act = curstage.act
        if type(act) == "table" then -- A table of sequences
            local new = act[math.random(#act)]
            self.CalcIdeal = new
        elseif act then
            self.CalcIdeal = act
        end
    end

    if self:IsJumping() and self:WaterLevel() <= 0 then
        self.CalcIdeal = ACT_JUMP
    end

    local data = self:GetBodyUpdateData()
    if data then
        self:SetStuckCounter(0) -- Might want to remove this, I assume if a special animation is playing, the enemy is active and probably not stuck.
        self.CalcIdeal = data.activity_name
        self:SetPlaybackRate(data.playback_rate)
    end

    if !self:GetSpecialAnimation() and !self:IsAttacking() then
        if self:GetActivity() != self.CalcIdeal and !self:GetStop()  then self:StartActivitySeq(self.CalcIdeal) end

        if self.ActStages[self:GetActStage()] and !self.FrozenTime then
            self:BodyMoveXY()
        end
    end

    if self.FrozenTime then
        if self.FrozenTime < CurTime() then
            self.FrozenTime = nil
            self:SetStop(false)
        end
        self:BodyMoveXY()
        --self:FrameAdvance()
    else
        self:FrameAdvance()
    end

end

function ENT:UpdateSequence()
    self:SetActStage(0)
    self:BodyUpdate()
    local actstage = self.ActStages[self:GetActStage()]
    local act = actstage and actstage.act
    if type(act) == "table" then -- A table of sequences
        local new = act[math.random(#act)]
        self:StartActivitySeq(new)
    elseif act then
        self:StartActivitySeq(act)
    else
        self:StartActivitySeq(self.CalcIdeal)
    end
end

function ENT:GetCenterBounds() -- Used for supporting trace functions. Created by: Ethorbit.
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()
    mins[3] = mins[3] / 2
    maxs[3] = maxs[3] / 2

    return {["mins"] = mins, ["maxs"] = maxs}
end

function ENT:TraceSelf(start, endpos, dont_adjust, line_trace) -- Creates a hull trace the size of ourself, handy if you'd want to know if we'd get stuck from a position offset. Created by: Ethorbit
    local bounds = self:GetCenterBounds()

    if !dont_adjust then
        start = start and start + self:OBBCenter() / 1.01 or self:GetPos() + self:OBBCenter() / 2
    end

    --debugoverlay.Box(start, bounds.mins, bounds.maxs, 0, Color(255,0,0,55))

    if endpos then
        if !dont_adjust then
            endpos = endpos + self:OBBCenter() / 1.01
        end

        --debugoverlay.Box(endpos, bounds.mins, bounds.maxs, 0, Color(255,0,0,55))
    end

    local tbl = {
        start = start,
        endpos = endpos or start,
        filter = self,
        mins = bounds.mins,
        maxs = bounds.maxs,
        collisiongroup = self:GetCollisionGroup(),
        mask = MASK_NPCSOLID
    }

    return !line_trace and util.TraceHull(tbl) or util.TraceLine(tbl)
end

-- Get a trace hull from us to this position, no bullshit code required, added by Ethorbit
-- Pass first arg as nil to default the start position to the zombie itself
-- Set addStartToEnd to true if you're simply passing a direction as endPos
function ENT:TraceSelfToPos(startPos, endPos, addStartToEnd)
    local bounds = self:GetCenterBounds()
    local stuck_tr = self:TraceSelf()
    local startpos = startPos or (self:GetPos() + self:OBBCenter() / 2)
    local endpos = addStartToEnd and (startpos + endPos) or endPos
    local tr = stuck_tr.Hit and stuck_tr or util.TraceHull({
        ["start"] = startpos,
        ["endpos"] = endpos,
        ["filter"] = self,
        ["mins"] = bounds.mins,
        ["maxs"] = bounds.maxs,
        ["collisiongroup"] = self:GetCollisionGroup(),
        ["mask"] = MASK_NPCSOLID
    })

    return tr
end

function ENT:IsStuck()
    return self:TraceSelf().Hit
end

function ENT:IsMovingIntoObject() -- Added by Ethorbit as this can be helpful to know
    local tr = self:TraceSelfToPos(nil, self:GetForward() * 10, true)

    -- debugoverlay.Box(startpos, mins, maxs, 0, Color(255,0,0) )
    -- debugoverlay.Box(endpos, mins, maxs, 0, Color(255,0,0, 50))

    local ent = tr.Entity
    if IsValid(ent) and (ent:IsPlayer() or ent:IsScripted()) then return false end --ent:GetClass() == "breakable_entry") then return false end

    return tr.Hit
end

function ENT:CanStandOnPosition(pos) -- Check if this position is able to be stood on or if we'll just fall.
    local tr = util.TraceLine({
        start = pos,
        endpos = pos - Vector(0,0,300),
        filter = self,
        collisiongroup = self:GetCollisionGroup(),
        mask = MASK_NPCSOLID
    })

    return tr.Hit
end

function ENT:TriggerBarricadeJump( barricade, dir )
    local jumping = barricade:GetTriggerJumps() --and self.TriggerBarricadeJump -- Now that all barricades are jumpable, we need to use this as a conditional

    if !self:GetSpecialAnimation() and (!self.NextBarricade or CurTime() > self.NextBarricade) then
        self:SetSpecialAnimation(true)
        self:SetBlockAttack(true)

        local id, dur, speed
        local actstage = self.ActStages[self:GetActStage()]
        local animtbl = actstage and actstage.barricadejumps or (self.ActStages[1] and self.ActStages[1].barricadejumps)

        if jumping then 
            if type(animtbl) == "number" then -- ACT_ is a number, this is set if it's an ACT
                id = self:SelectWeightedSequence(animtbl)
                dur = self:SequenceDuration(id)
                speed = self:GetSequenceGroundSpeed(id)
                if speed < 10 then
                    speed = 20
                end
            else
                local targettbl = animtbl and animtbl[math.random(#animtbl)] or self.JumpSequences
                if targettbl then -- It is a table of sequences
                    id, dur = self:LookupSequenceAct(targettbl.seq) -- Whether it's an ACT or a sequence string
                    speed = targettbl.speed
                    --dur = targettbl.time or dur
                else
                    id = self:SelectWeightedSequence(ACT_JUMP)
                    dur = self:SequenceDuration(id)
                    speed = 30
                end
            end
        else 
            id = self:SelectWeightedSequence(self:GetActivity()) --self:SelectWeightedSequence(ACT_JUMP)
            dur = self:SequenceDuration(id)
            speed = self:GetRunSpeed() --self.loco:GetDesiredSpeed()
        
            if speed < 10 then
                speed = 20
            end
        end 
        
        self:SetSolidMask(MASK_SOLID_BRUSHONLY)
        --self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
        --self.loco:SetAcceleration( 5000 )
        self.loco:SetDesiredSpeed(speed or 30)
        self:SetVelocity(self:GetForward() * (speed or 30))
        
        if jumping then
            self:SetSequence(id)
        end

        self:SetPlaybackRate(1)
        self:SetClimbing(true)
        --self:BodyMoveXY()
        --PrintTable(self:GetSequenceInfo(id))

        self:TimedEvent(jumping and dur or 1, function()
            if (self:IsStuck()) then -- We tried to climb through a barricade, and now we're stuck. Time to cheat past it.. - by Ethorbit
                local pos = barricade:GetPos() - dir * 40
                self:SetPos(pos)
            end

            self.NextBarricade = CurTime() + 2
            self:SetSpecialAnimation(false)
            self:SetBlockAttack(false)
            self.loco:SetAcceleration(self.Acceleration)
            self.loco:SetDesiredSpeed(self:GetRunSpeed())
            self:UpdateSequence()
        end)

        local pos = barricade:GetPos() - dir * 40

        --debugoverlay.Cross(pos, 5, 5)
        -- This forces us to move straight through the barricade
        -- in the opposite direction of where we hit the trace from
        self:MoveToPos(pos, {
            lookahead = 40,
            tolerance = 1,
            draw = false,
            maxage = 3,
            repath = 3,
        })
    end
end

function ENT:GetAimVector()

    return self:GetForward()

end

function ENT:GetShootPos()

    return self:EyePos()

end

function ENT:LookupSequenceAct(id)
    if type(id) == "number" then
        local id = self:SelectWeightedSequence(id)
        local dur = self:SequenceDuration(id)
        return id, dur
    else
        return self:LookupSequence(id)
    end
end

function ENT:StartActivitySeq(act)
    if type(act) == "number" then
        self:StartActivity(act)
    else
        local id, dur = self:LookupSequence(act)
        --self:ResetSequenceInfo()
        --self:ResetSequence(id)
        self:SetSequence(id)
    end
end

--Helper function
function ENT:TimedEvent(time, callback)
    if !time then return end
    timer.Simple(time, function()
        if (IsValid(self) and self:Health() > 0) then
            callback()
        end
    end)
end

function ENT:TimedEvents(time, amount, callback) -- Added by Ethorbit for a repeating TimedEvent
    self:TimedEvent(time, function()
        callback()

        local next = amount - 1
        if next > 0 then
            self:TimedEvents(time, next, callback)
        end
    end)
end

function ENT:Push(vec, time) -- Push us towards a vector, created by: Ethorbit
    if CurTime() < self:GetLastPush() + 0.2 or !self:IsOnGround() then return end

    self.GettingPushed = true
    self.loco:SetVelocity( vec )

    self:TimedEvent(time or 0.5, function()
        self.GettingPushed = false
    end)

    self:SetLastPush( CurTime() )
end

function ENT:ApplyRandomPush( power ) -- Push us in a random direction with the provided amount of force, created by: Ethorbit
    power = power or 100

    if self.loco then
        local vec = self.loco:GetVelocity() + VectorRand() * power
        vec.z = math.random( 100 )
        self:Push(vec)
    end
end

function ENT:IsGettingPushed() -- Check if we're :Push'd, created by: Ethorbit
    return self.GettingPushed
end

function ENT:ZombieWaterLevel()
    local pos1 = self:GetPos()
    local halfSize = self:OBBCenter()
    local pos2 = pos1 + halfSize
    local pos3 = pos2 + halfSize
    if bit.band( util.PointContents( pos3 ), CONTENTS_WATER ) == CONTENTS_WATER or bit.band( util.PointContents( pos3 ), CONTENTS_SLIME ) == CONTENTS_SLIME then
        return 3
    elseif bit.band( util.PointContents( pos2 ), CONTENTS_WATER ) == CONTENTS_WATER or bit.band( util.PointContents( pos2 ), CONTENTS_SLIME ) == CONTENTS_SLIME then
        return 2
    elseif bit.band( util.PointContents( pos1 ), CONTENTS_WATER ) == CONTENTS_WATER or bit.band( util.PointContents( pos1 ), CONTENTS_SLIME ) == CONTENTS_SLIME then
        return 1
    end

    return 0
end

--Targets
function ENT:HasTarget()
    return self:IsValidTarget( self:GetTarget() )
end

function ENT:GetTarget()
    return self.Target
end

function ENT:GetTargetNavArea()
    return self:HasTarget() and navmesh.GetNearestNavArea( self:GetTarget():GetPos(), false, 100)
end

function ENT:SetTarget( target ) -- Modified by Ethorbit for better support

    -- if self:GetTargetUnreachable() then
    --  self:SetTarget(nil)
    -- end

    if (target == self:GetTarget()) then return end

    if (!IsValid(target)) then
        self:IgnoreTarget(self:GetTarget())
    return end

    self.Target = target
    if self.Target != target then
        self:SetLastTargetChange(CurTime())
    end

    self:OnNewTarget(target)
end

function ENT:OnNewTarget(target) -- OVERRIDE
end

function ENT:IsTarget( ent )
    return self.Target == ent
end

function ENT:RemoveTarget()
    self:SetTarget( nil )
end

function ENT:IsTargetDead(ent)
    if IsValid(ent) then
        if ent:IsPlayer() then
            if ent:IsInCreative() then return false end
            if ent:IsSpectating() or !ent:GetNotDowned() then return true end
        end
    else
        return true -- Well if the entity doesn't exist, why would we consider it a thing?
    end
end

function ENT:IsValidTarget( ent ) -- Modified by Ethorbit for better support
    if self:IsTargetDead(ent) then return false end -- Fixes spectator zombie exploits
    return IsValid(ent) and ent:GetTargetPriority() != TARGET_PRIORITY_NONE and (self.IgnoreDistractions and ent:GetTargetPriority() != TARGET_PRIORITY_SPECIAL or true)
end

function ENT:GetIgnoredTargets()
    return self.tIgnoreList
end

function ENT:IgnoreTarget(target, next_allowed_target) -- Modified by Ethorbit for better support
    if (IsValid(target)) then
        if !target:IsPlayer() and (target:GetTargetPriority() == TARGET_PRIORITY_ALWAYS or target:GetTargetPriority() == TARGET_PRIORITY_SPECIAL) then return end -- Ignoring them would go against the very purpose of these target priorities
        self.tIgnoreList[target] = {
            ["ent"] = target,
            ["pos"] = target:GetPos(),
            ["next_allowed_target"] = next_allowed_target or 0
        }
    end
end

function ENT:AllowTarget(target) -- Remove target from the Ignore List, created by: Ethorbit
    self.tIgnoreList[target] = nil
end

function ENT:IsIgnoredTarget(ent) -- Modified by Ethorbit ^^^^^^^^
    return self.tIgnoreList[ent] != nil and IsValid(self.tIgnoreList[ent].ent)
end

function ENT:FreeIgnores() -- Stop ignoring targets that don't need to be ignored still, created by: Ethorbit
    for _,v in pairs(self.tIgnoreList) do
        if (IsValid(v.ent)) then
            if (self:TargetInRange(self:GetAttackRange() * 2)) then self.tIgnoreList[v.ent] = nil end
            if (v.ent:GetPos():DistToSqr(v.pos) >= 200000) then
                if (!self.tIgnoreList[v.next_allowed_target] or CurTime() > self.tIgnoreList[v.next_allowed_target]) then
                    self.tIgnoreList[v.ent] = nil
                end
            end
        end
    end
end

function ENT:ResetIgnores()
    self.tIgnoreList = {}
end

--AccessorFuncs
function ENT:IsJumping()
    return self:GetJumping()
end

function ENT:IsClimbing()
    return self:GetClimbing()
end

function ENT:IsAttacking()
    return self:GetAttacking()
end

function ENT:IsTimedOut()
    return self:GetTimedOut()
end

function ENT:SetInvulnerable(bool)
    self.Invulnerable = bool
end

function ENT:IsInvulnerable()
    return self.Invulnerable
end
