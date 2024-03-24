AddCSLuaFile()

ENT.Author = "Ethorbit"
ENT.Base = "nz_zombiebase"
ENT.NZBoss = true -- So nZombies knows that we're actually a boss. ENT.BossType is applied automatically in rounds, but this is still useful.
ENT.PauseOnAttack = false -- It's too easy if we stop before each attack
ENT.IgnoreDistractions = true -- Ignore stuff like monkey bombs, we only care about the player.

-- We should shred right through barricades
ENT.BarricadeRemoveAmount = 999
ENT.BarricadeWaitForZombies = false

ENT.CanStrafe = false -- We want to reach our target as quickly as possible. Let the zombies overwhelm them.
