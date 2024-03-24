-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

ENT.Base = "nz_zombiebase"
ENT.PrintName = "PB Zombie Base"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

AccessorFunc( ENT, "bEmerging", "Emerging", FORCE_BOOL)
AccessorFunc( ENT, "fLastFootstepSound", "LastFootstepSound", FORCE_NUMBER)

-- Headcrab
AccessorFunc( ENT, "bDropsHeadcrab", "DropsHeadcrab", FORCE_BOOL)
AccessorFunc( ENT, "sHeadcrabClass", "HeadcrabClass", FORCE_STRING)

-- Crawler
AccessorFunc( ENT, "bCrawler", "Crawler", FORCE_BOOL)
AccessorFunc( ENT, "bCanBeCrawler", "CanBeCrawler", FORCE_BOOL)
AccessorFunc( ENT, "sCrawlerClass", "CrawlerClass", FORCE_STRING)
AccessorFunc( ENT, "fHealthForCrawler", "HealthForCrawler", FORCE_NUMBER)

AccessorFunc( ENT,   "sTorsoModel", "TorsoModel", FORCE_STRING)
AccessorFunc( ENT,  "sLegsModel", "LegsModel", FORCE_STRING)

AccessorFunc( ENT, "bFlying", "Flying", FORCE_BOOL)
--AccessorFunc( ENT, "bLanding", "Landing", FORCE_BOOL)
AccessorFunc( ENT, "bLandAfterDealingDamage", "LandAfterDealingDamage", FORCE_BOOL)
AccessorFunc( ENT, "bLandWhenNearTarget", "LandWhenNearTarget", FORCE_BOOL)

-- Leaping
AccessorFunc( ENT, "bFlyOnLeap", "FlyOnLeap", FORCE_BOOL) -- Technically Flying
AccessorFunc( ENT, "fLeapFlyTime", "LeapFlyTime", FORCE_NUMBER) -- Technically Flying

AccessorFunc( ENT, "bLeapDealtDamage", "LeapDealtDamage", FORCE_BOOL)
AccessorFunc( ENT, "bLeapAtPlayers", "LeapAtPlayers", FORCE_BOOL)
AccessorFunc( ENT, "fLastLeap", "LastLeap", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapDelayMin", "LeapDelayMin", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapDelayMax", "LeapDelayMax", FORCE_NUMBER)
AccessorFunc( ENT, "bLeaping", "Leaping", FORCE_BOOL)
AccessorFunc( ENT, "fMaxLeapRange", "MaxLeapRange", FORCE_NUMBER)
AccessorFunc( ENT, "fMinLeapRange", "MinLeapRange", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapDamage", "LeapDamage", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapDamageRadius", "LeapDamageRadius", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapPower", "LeapPower", FORCE_NUMBER)
AccessorFunc( ENT, "fLeapXYMin", "LeapXYMin")
AccessorFunc( ENT, "fLeapXYMax", "LeapXYMax")
AccessorFunc( ENT, "fLeapZMin", "LeapZMin")
AccessorFunc( ENT, "fLeapZMax", "LeapZMax")

DEFINE_BASECLASS(ENT.Base)

ENT.AttackRange = 40

ENT.Gibs = {} -- Add models in here to enable the ability for us to turn into gibs from certain damage instead of a single ragdoll
ENT.ExplosionDamageForGibs = 150

function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)
    self:NetworkVar("Bool", 21, "HeadcrabDetached")
    self:NetworkVar("Int", 21, "EmergeSequenceIndex")
end

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)

    if SERVER then
        self:SetBloodColor(BLOOD_COLOR_ZOMBIE)
    end

    self.bTargetInLeapRange = false
    self.NextLeapDelay = 0
    self:SetLastLeap(0)
    self:SetLeaping(false)

    -- Change to drop headcrabs
    self:SetDropsHeadcrab(false)
    self:SetHeadcrabClass("")

    -- Change for crawlers
    self:SetCrawler(false)
    self:SetCanBeCrawler(false)
    self:SetCrawlerClass("")
    self:SetHealthForCrawler(500)

    -- Only change this if we become a crawler (So the legs pop off)
    self:SetLegsModel("")

    -- Change this to have automatic player leap functionality
    self:SetLeapAtPlayers(false)
    self:SetLeapDelayMin(3)
    self:SetLeapDelayMax(3)
    self:SetMaxLeapRange(300.0)
    self:SetMinLeapRange(0.0)
    self:SetLeapDamage(10.0)
    self:SetLeapDamageRadius(90.0)
    self:SetLeapPower(2)
    self:SetLeapXYMin(0)
    self:SetLeapXYMax(0)
    self:SetLeapZMin(0)
    self:SetLeapZMax(0)

    self:SetFlyOnLeap(false)
    self:SetLeapFlyTime(3.0)
    self:SetLandAfterDealingDamage(true)
    self:SetLandWhenNearTarget(true)

    self:SetLastFootstepSound(CurTime())
end

function ENT:SpecialInit()
	--make them invisible for a really short duration to blend the emerge sequences
	self:SetNoDraw(true)
	self:TimedEvent(0.1, function() -- Tiny delay just to make sure they are fully initialized
		self:TimedEvent( 0.5, function()
			self:SetNoDraw(false)
		end)

		local _, dur = self:LookupSequence(self.EmergeSequences[self:GetEmergeSequenceIndex()])
		dur = dur - (dur * self:GetCycle()) -- Subtract the time we are already thruogh the animation
	end)
end

function ENT:OnThink()
	BaseClass.OnThink(self)

	-- HL2 Zombies have small attack ranges, but we want to retain the original
	-- when in the air because it helps us fight off the map exploiters
	if self:IsOnGround() then
		self:SetAttackRange(self.AttackRange)

        -- if (self:GetFlying()) then
        --     self:HL2Land()
        -- end

        if (self:GetLeaping()) then
            self:SetLeaping(false)
            self:SetLeapDealtDamage(false)
            self:OnLeapFinished()
        end
    elseif (self:GetLeaping()) then
        self:SetAttackRange(self:GetLeapDamageRadius())
	else
		self:SetAttackRange(80)
	end

    if self:GetFlying() and self:GetLandWhenNearTarget() and IsValid(self:GetTarget()) then
        if self:GetRangeSquaredTo(self:GetTarget():GetPos()) <= self:GetAttackRange() then
            self:TimedEvent(0.3, function()
                self:HL2Land()
            end)
        end
    end

    -- Try to leap at players (if allowed to)
    if self:Health() > 0 and self:GetLeapAtPlayers() and self:IsAllowedToMove() and !self:GetEmerging() then
        local target = self:GetTarget()
        if (CurTime() > (self:GetLastLeap() + self.NextLeapDelay) and IsValid(target) and self:IsInLeapRange(target) and self:CanLeapAtTarget(target)) then
           if !self:IsIgnoredTarget(target) and !self:GetTargetUnreachable() and target:Visible(self) then
                self.NextLeapDelay = math.Rand(self:GetLeapDelayMin(), self:GetLeapDelayMax())

                if (self:GetFlyOnLeap()) then
                    self:HL2Fly(target, self:GetLeapFlyTime())
                else
                    self:HL2Leap(target)
                end
            end
        end
    end

    if self:GetLeaping() then
        if self:TargetInAttackRange() then
            self:OnLeapTargetInRange()
            self.bTargetInLeapRange = true
        else
            self.bTargetInLeapRange = false
        end
    else
        self.bTargetInLeapRange = false
    end
end

function ENT:OnLeapFinished() -- OVERRIDE
end

function ENT:TargetInLeapRange()
    return self.bTargetInLeapRange
end

function ENT:OnLeapTargetInRange()
    if !self:GetLeapDealtDamage() then
        self:SetLeapDealtDamage(true) -- We don't wanna hurt multiple times with a leap attack, that would be too broken!

        local target = self:GetTarget()
        if (target:IsPlayer()) then
            local data = {}
            data.dmglow = self:GetLeapDamage()
            data.dmghigh = self:GetLeapDamage()
            data.isleapdmg = true

            self:Attack(data, true)
            self:OnLeapHurtPlayer(target)

            if self:GetFlying() then
                self:HL2Land()
            end
        end
    end
end

function ENT:OnLeapHurtPlayer(player) -- OVERRIDE
end

function ENT:IsInLeapRange(target)
    if !IsValid(target) then return false end
    local dist = self:GetRangeSquaredTo(target:GetPos())
    local maxAllowed = self:GetMaxLeapRange()^2
    local minAllowed = self:GetMinLeapRange()^2

    return dist > minAllowed and dist < maxAllowed
end

function ENT:CanLeapAtTarget(target)
    return true
end

function ENT:OnPreHL2Leap() -- OVERRIDE
end

function ENT:OnPostHL2Leap() -- OVERRIDE
end

function ENT:HL2Leap(target)
    if !self.loco then return end -- We cannot leap without a locomotor

    self:OnPreHL2Leap()

    self:SetLeaping(true)
    self:SetLastLeap(CurTime())
    self.loco:FaceTowards(isvector(target) and target or target:GetPos())

    local destination = isvector(target) and target or target:EyePos()
    local dir = (destination - self:GetPos()):GetNormalized()
    local power = self:GetPos():Distance(destination) * self:GetLeapPower() -- anything to reach them

    -- Do offsetting
    local apply_offset_right = math.random(1,2) == 2
    local offset = (apply_offset_right and self:GetRight() or -self:GetRight()) * (math.random(self:GetLeapXYMin(), self:GetLeapXYMax()))
    offset[3] = math.random(self:GetLeapZMin(), self:GetLeapZMax())
    destination = destination + offset

    self.loco:JumpAcrossGap(destination, destination)
    self:TimedEvent(0.5, function()
        self.loco:SetVelocity(dir * power)
    end)

    self:OnPostHL2Leap()
end

function ENT:HL2Land()
    --self:SetLanding(true)
    -- local landPos = self:GetPos()
    -- landPos[3] = self:GetTarget():GetPos() -- hoping that's good enough
    -- self:HL2Leap(self:GetPos())
    self:SetFlying(false)
    self:OnHL2Land()
    --self:SetLanding(false)
end

function ENT:OnHL2Land() -- OVERRIDE
end

function ENT:HL2Fly(entorpos, time)
    if self:GetFlying() then return end -- Wait until our current flying task has finished
    self:SetFlying(true)
    self:OnHl2PreFly()

    time = time or 3

    timer.Create("HL2Flying" .. self:EntIndex(), 0.1, (time * 10), function()
        if IsValid(self) then
            if !self:GetFlying() then return end
            self:HL2Leap(entorpos)
        end
    end)

    self:TimedEvent(time, function() -- We finished flying, time to land
        self:HL2Land()
    end)
end

function ENT:OnHl2PreFly() -- OVERRIDE
end

function ENT:CanHurtTarget(data)
    if !self:GetLeaping() then
        return true
    end

	return (data and data.isleapdmg) or CurTime() > (self:GetLastLeap() + 0.8)
end

function ENT:IsAllowedToMove()
    if self:GetLeaping() then
        return false
    end

    return BaseClass.IsAllowedToMove(self)
end

function ENT:CreateTorso(pos, dmginfo)
    if self:GetTorsoModel() == "" then return end
    nzRagdolls.Create(self:GetTorsoModel(), self:GetPos(), dmginfo)
end

function ENT:CreateLegs(pos, dmginfo)
    print("lol", self:GetLegsModel())
    if (self:GetLegsModel() == "") then return end
    nzRagdolls.Create(self:GetLegsModel(), self:GetPos(), dmginfo)
end

function ENT:CreateCrawler(pos, health, dmginfo)
    local crawler = ents.Create(self:GetCrawlerClass())
    crawler:SetPos(pos)
    crawler.MakeDust = function() end
    crawler:Spawn()

    crawler:TimedEvent(0.1, function()
        crawler:SetHealth(health)
        crawler:SetMaxHealth(health)
    end)

    self:OnCrawlerCreated(crawler, dmginfo)
end

function ENT:TurnToGibs(dmginfo)
    if !self.Gibs then return end

    for _,mdl in pairs(self.Gibs) do
        nzRagdolls.Create(mdl, self:GetPos(), dmginfo)
    end

    SafeRemoveEntity(self)
end

function ENT:StableBecomeRagdoll(dmgInfo)
    if !self.Gibs then
        BaseClass.StableBecomeRagdoll(self, dmgInfo)
    return end

    local should_gib = dmgInfo:GetIsExplosionDamage() and dmgInfo:GetDamage() > (self.ExplosionDamageForGibs or 150)

    if should_gib then
        self:TurnToGibs(dmgInfo)
    else
        BaseClass.StableBecomeRagdoll(self, dmgInfo)
    end
end

function ENT:OnTakeDamage(dmginfo)
	BaseClass.OnTakeDamage(self, dmginfo)

    if (self:GetCanBeCrawler()) then
        if (dmginfo:GetIsExplosionDamage() and self:Health() > 0 and self:Health() <= self:GetHealthForCrawler()) then
            if dmginfo:GetDamage() <= 15 then return end -- Not strong enough to make crawler
            if self:Health() <= dmginfo:GetDamage() then return end

            local crawler_hp = (self:Health() - dmginfo:GetDamage())
            if crawler_hp <= 0 then return end

            self:CreateCrawler(self:GetPos(), crawler_hp, dmginfo)
            self:CreateLegs(self:GetPos(), dmginfo)

            self:Remove() -- We turned into that crawler
        end
    end
end

function ENT:CreateHeadcrab(pos, dmgForce, dmgInfo, isElectricuting) -- Create a live headcrab
    if !self:GetDropsHeadcrab() then return end

    if !dmgForce then
        local max_zombies = nzRound:GetZombiesMax()
        if max_zombies then
            nzRound:SetZombiesMax(nzRound:GetZombiesMax() + 1) -- We don't want the round to end with this new crab alive
        end
    end

    local headcrab = ents.Create(self:GetHeadcrabClass())
    if IsValid(headcrab) then
        headcrab.SpecialInit = function() end
        headcrab.MakeDust = function() end
        headcrab:SetDetachedFromZombie(true)
        headcrab:SetPos(pos)
        headcrab:Spawn()
        self:OnHeadcrabCreated(headcrab, dmgInfo)

        if !dmgForce then
            headcrab.EmergeSequences = {""}
            headcrab:SetLastLeap(CurTime() + 0.5) -- Don't immediately attack the player before they even know a headcrab is here
        else
            headcrab:SetHealth(999999)
            local dir = dmgForce:GetNormalized()

            local dmginfo = DamageInfo()
            dmginfo:SetDamageForce(dir * math.random(1500, 4000))
            dmginfo:SetDamagePosition(pos)

            if isElectricuting then
                dmginfo:SetDamageType(DMG_SHOCK)
                dmginfo:SetDamageForce(Vector(0,0,0))
                headcrab:OnZombieDeath(dmginfo)
            else
                nzRagdolls.Create(headcrab:GetModel(), headcrab:GetPos(), dmginfo)
                headcrab:Remove()

                --headcrab:StableBecomeRagdoll(dmginfo)

                -- timer.Simple(0.1, function() -- Removes weird issue where headcrab appears for a little as its ragdoll is moving across map
                --     headcrab:SetRenderMode(RENDERMODE_NONE)
                --     headcrab:SetNoDraw(false)
                -- end)
            end
        end
    end
end

function ENT:OnHeadcrabCreated(headcrab, dmginfo) -- OVERRIDE
end

function ENT:OnCrawlerCreated(crawler, dmginfo) -- OVERRIDE
end

 -- In Half-Life: 2 (and PB), when you kill a zombie it has unique functionality for its headcrab,
 -- it can die with it on or it can die with its headcrab blasted off or it can even die
 -- with its headcrab still alive
function ENT:TryDecapitation(dmgInfo)
	local head = self:GetAttachment(self:LookupAttachment("headcrab"))
	if head then
		local headPos = head.Pos
		local dmgPos = dmgInfo:GetDamagePosition()
		local dmgType = dmgInfo:GetDamageType()
		local dmgForce = dmgInfo:GetDamageForce()
        local is_melee_dmg = dmgInfo:GetIsMeleeDamage()
		local is_explosion_dmg = dmgInfo:IsExplosionDamage()
        local is_bullet_dmg = dmgInfo:GetIsBulletDamage()

		if self.SetHeadcrabDetached then
			if dmgInfo:GetDamageType() == DMG_SHOCK then
                self:SetBodygroup(1, 0)
                self:CreateHeadcrab(headPos, dmgForce, dmgInfo, true)
            else
                if nzPowerUps:IsPowerupActive("insta") or (dmgInfo:GetForcedHeadshot() or (headPos and dmgPos and headPos:Distance(dmgPos) < 22)) then
                    if !self:GetCrawler() then -- Headcrabs don't get shot off when the crawlers die in HL2
                        self:SetHeadcrabDetached(true)
                        self:EmitSound("nzr/zombies/death/headshot_" .. math.random(0, 3) .. ".wav")
                        self:SetBodygroup(1, 0)

                        -- We're dead, no head, create headcrab ragdoll!
                        local dmgForce2D = dmgForce:Length2D()
                        if is_explosion_dmg or dmgForce2D >= 2000 or self:GetMaxHealth() <= 100 then -- this is a lot of force, pop the headcrab off (unless we were weak to begin with of course)
                            self:CreateHeadcrab(headPos, dmgForce, dmgInfo)
                        else
                            self:SetBodygroup(1, 1) -- Just be dead with headcrab on
                        end
                    else
                        self:SetBodygroup(1, 1)
                    end
                else -- Dead, no decapitation
                    local attacker = dmgInfo:GetAttacker()
                    local attacker_is_player = IsValid(attacker) and attacker:IsPlayer()

                    if is_melee_dmg then
                        self:SetBodygroup(1, 1)
                    else
                        if is_bullet_dmg and attacker_is_player then
                            self:SetBodygroup(1, 0)
                            self:CreateHeadcrab(headPos, nil, dmgInfo)
                        elseif is_explosion_dmg then
                            self:SetBodygroup(1, 0)
                            self:CreateHeadcrab(headPos, dmgForce, dmgInfo)
                        end
                    end
                end
            end
		end

        self:StableBecomeRagdoll(dmgInfo)
	end
end

function ENT:OnZombieDeath(dmgInfo)
	if dmgInfo:GetDamageType() == DMG_SHOCK then
        self:SetRunSpeed(0)
		self.loco:SetVelocity(Vector(0,0,0))
		self:Stop()
		local seq, dur = self:LookupSequence(self.ElectrocutionSequences[math.random(#self.ElectrocutionSequences)])
		self:ResetSequence(seq)
		self:SetCycle(0)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		-- Emit electrocution scream here when added
		timer.Simple(dur, function()
			if IsValid(self) then
			    self:StableBecomeRagdoll(dmgInfo)
				--self:Kill()
			end
		end)
	else
		--self:EmitSound( self.DeathSounds[ math.random( #self.DeathSounds ) ], 100)

        if !self:GetDropsHeadcrab() then -- Otherwise we handle it in TryDecapitation for compatibility with headcrab pop-off logic
            self:StableBecomeRagdoll(dmgInfo)
        end
	end
end

function ENT:OnSpawn()
	local seq = self.EmergeSequences[self:GetEmergeSequenceIndex()]
    if !seq then return end
	local _, dur = self:LookupSequence(seq)

	--dust cloud
	self:MakeDust(dur)

	-- play emerge animation on spawn
	-- if we have a coroutine else just spawn the zombie without emerging for now.
	if coroutine.running() then
        self:SetEmerging(true)
        self:PlaySequenceAndWait("")
		self:PlaySequenceAndWait(seq)
        self:SetEmerging(false)
        self:OnEmergeFinished()
	end

	self:SetLastActive(CurTime())
end

function ENT:OnEmergeFinished() -- OVERRIDE
end
