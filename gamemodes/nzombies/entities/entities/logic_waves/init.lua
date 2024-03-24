ENT.Type = "point"

ENT.NZEntity = true

function ENT:Initialize()
	-- Remove it as soon as it spawns, if gamemode extensions hasn't been enabled in Map Settings
	if !nzMapping.Settings.gamemodeentities then
		self:Remove()
	end
	self.Wave = self.Wave or -1
end

function ENT:Think()
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	elseif name == "advancewave" then
		-- We do not allow manually advancing rounds
		return true
	elseif name == "endwave" then
		-- Or ending them
		return true
	elseif name == "setwave" then
		-- Or changing which one we're on
		return true
	elseif name == "setwaves" then
		SetGlobalInt("numwaves", tonumber(args) or GAMEMODE.NumberOfWaves)
		return true
	elseif name == "startwave" then
		
		return true
	elseif name == "setwavestart" then
		
		return true
	elseif name == "setwaveend" then

		return true
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	elseif key == "wave" then
		self.Wave = tonumber(value) or -1
	end
end

-- Rounds in nZombies are different than those on Zombie Survival
local conversionrate = 2

-- Reset WavesCalled at the end of every game. /Ethorbit
hook.Add("OnRoundEnd", "nz_zsLogicWavesCalledReset", function()
	for _, ent in pairs(ents.FindByClass("logic_waves")) do
        ent.WavesCalled = {}
    end
end)

hook.Add("OnRoundStart", "nz_zsLogicWavesRoundStart", function(num)
	local curwave = num / conversionrate
	for _, ent in pairs(ents.FindByClass("logic_waves")) do
        -- Below has been improved by Ethorbit.
        -- I have added compatibility for forced rounds (nz_forceround)
        ent.WavesCalled = ent.WavesCalled or {}
       
        if ent.Wave < curwave and !ent.WavesCalled[ent.Wave] then 
            ent.WavesCalled[ent.Wave] = true
     
            if (hook.Run("OnForcedLogicWaves_onwavestart", ent.Wave) != false) then 
                print("Forced onwavestart", ent.Wave)
                ent:Input("onwavestart", ent, ent, ent.Wave)
            end
        
            -- then we immediately end it because we are not actually on that wave
            timer.Simple(0.1, function()
                if IsValid(ent) and ent.Wave then 
                    if (hook.Run("OnForcedLogicWaves_onwaveend", ent.Wave) != false) then 
                        print("Forced onwaveend", ent.Wave)
                        ent:Input("onwaveend", ent, ent, ent.Wave)
                    end 
                end 
            end) 
        end 
        
        if ent.Wave == curwave or ent.Wave == -1 and !ent.WavesCalled[ent.Wave] then
            ent.WavesCalled[curwave] = true
			
            ent:Input("onwavestart", ent, ent, curwave)
		end
	end
end)

hook.Add("OnRoundPreparation", "nz_zsLogicWavesRoundEnd", function(num)
	local curwave = (num - 1) / conversionrate
	for _, ent in pairs(ents.FindByClass("logic_waves")) do
		if ent.Wave == curwave or ent.Wave == -1 then
			ent:Input("onwaveend", ent, ent, curwave)
		end
	end
end)
