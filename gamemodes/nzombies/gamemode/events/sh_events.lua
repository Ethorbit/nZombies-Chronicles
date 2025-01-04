-- Event System added by Ethorbit, primarily so that nZombies could have its own holiday events
-- Atmos Weather addon will be needed for event weather to work

NZActiveEvents = NZActiveEvents or {}
NZActiveHolidayEvents = NZActiveHolidayEvents or {}

if CLIENT then
    local weatherEnabled = GetConVar("nzc_weather")
    local holidayEnabled = GetConVar("nzc_holiday_events")

    function StormEnable()
        if (weatherEnabled and weatherEnabled:GetInt() > 0) then
            AtmosStorming = true
        end
    end

    function ChristmasSnow()
        if (weatherEnabled and weatherEnabled:GetInt() > 0 and holidayEnabled:GetInt() > 0) then
            AtmosSnowing = true
        end
    end

    function HalloweenStorm()
        if (weatherEnabled and weatherEnabled:GetInt() > 0 and holidayEnabled:GetInt() > 0) then
            AtmosStorming = true
        end
    end
end

local function update_event_table()
    NZEvents = {
        Activate = function(event, holiday)
            NZActiveEvents[event] = true

            if holiday then
                NZActiveHolidayEvents[event] = true
            end
        end,
        Active = function(event)
            return NZActiveEvents[event]
        end,
        Get = function(event)
            return NZEvents[event]
        end,
        Start = function(event)
            if (event == nil) then
                for event,_ in pairs(NZActiveEvents) do
                    NZEvents.Start(event)
                end
            return end

            if (NZEvents and NZEvents[event]) then
                if (NZEvents[event].Enable) then
                    NZEvents[event]:Enable()
                    if CLIENT and (NZEvents[event].AllowEnableMsg == nil or NZEvents[event].AllowEnableMsg == true) then LocalPlayer():ChatPrint(NZEvents[event].EnableMsg or (event .. " event enabled!")) end
                end

                if (NZEvents[event].Initialize) then
                    NZEvents[event]:Initialize()
                    NZEvents[event].Initialize = nil
                end
            end
        end,
        Stop = function(event)
            if (event == nil) then
                for event,_ in pairs(NZActiveEvents) do
                    NZEvents.Stop(event)
                end
            return end

            if (NZEvents and NZEvents[event] and NZEvents[event].Disable) then
                NZEvents[event]:Disable()
                if CLIENT and (NZEvents[event].AllowDisableMsg == nil or NZEvents[event].AllowDisableMsg == true) then LocalPlayer():ChatPrint(NZEvents[event].DisableMsg or (event .. " event disabled!")) end
            end
        end,
        StartHoliday = function()
            for event,_ in pairs(NZActiveHolidayEvents) do
                NZEvents.Start(event)
            end
        end,
        StopHoliday = function()
            for event,_ in pairs(NZActiveHolidayEvents) do
                NZEvents.Stop(event)
            end
        end,
        ["Christmas"] = SERVER and {
            ["Initialize"] = function()
                hook.Add("OnEntityCreated", "ChristmasPrecipitationRemover", function(ent)
                    if (IsValid(ent) and ent:GetClass() == "func_precipitation") then
                        ent:Remove()
                    end
                end)

                timer.Create("ChristmasSnow", 60, 1, function()
                    BroadcastLua("ChristmasSnow()")
                end)

                hook.Add("PlayerSpawn", "ChristmasSnow", function(ply)
                    if (NZEvents.Active("Christmas")) then -- Christmas snow
                        ply:SendLua("ChristmasSnow()")
                    end
                end)
            end
        } or {
            ["Enable"] = function()
                ChristmasSnow()

                for _,v in pairs(ents.GetAll()) do
                    if (IsValid(v) and v:IsValidZombie()) then
                        v.CustomModelColor = table.Random({Color(255, 0, 0), Color(0, 255, 0)})
                    end
                end
            end,
            ["Disable"] = function()
                AtmosSnowing = false

                for _,v in pairs(ents.GetAll()) do
                    if (IsValid(v) and v:IsValidZombie()) then
                        v.CustomModelColor = nil
                        v:SetColor(Color(255, 255, 255))
                    end
                end
            end
        },
        ["Halloween"] = CLIENT and {
            ["DisableMsg"] = "Halloween event disabled! (Some stuff could not be disabled and will remain on)",
            ["Enable"] = function()

            end,
            ["Disable"] = function()

            end
        },
        ["April Fools"] = SERVER and {
            ["Initialize"] = function()
                hook.Add("OnGameBegin", "FkTheServerspeedsUp", function()
                    game.SetTimeScale(1.2)
                end)
            end
        } or {
            ["AllowEnableMsg"] = false,
            ["AllowDisableMsg"] = false,
            ["Enable"] = function()
                hook.Add("EntityEmitSound", "LowPitchEverythingCusWhyNot", function(data)
                    if (data.Pitch and data.Pitch > 20) then
                        data.Pitch = 20
                    return true end
                end)
            end,
            ["Disable"] = function()
                hook.Add("EntityEmitSound", "LowPitchEverythingCusWhyNot", function(data)
                    if (data.Pitch and data.Pitch > 20) then
                        data.Pitch = 20
                    return true end
                end)

                --hook.Remove("EntityEmitSound", "HighPitchEverythingCusWhyNot")

                -- for _,v in pairs(ents.GetAll()) do
                --     if (IsValid(v) and v:IsValidZombie()) then
                --         v:SetModelScale(1)
                --     end
                -- end
            end
        }
    }
end

update_event_table()

local hookName = "Initialize"
if CLIENT then
    hookName = "InitPostEntity"
end

hook.Add(hookName, "NZUpdateEventsTable", function()
    update_event_table()

    if (CLIENT and GetConVar("nzc_holiday_events"):GetInt() < 1) then NZEvents.StopHoliday() return end
end)

hook.Add(hookName, "NZDoEventCheck", function() -- Holiday events
    -- if (NZDate.GetMonth() == 3) then
    --    NZEvents.Activate("April Fools", true)
    -- return end

    if (NZDate.GetMonth() == 12) then --or NZDate.GetMonth() == 1 and NZDate.GetDay() <= 2)
        NZEvents.Activate("Christmas", true)
    end

    -- if (NZDate.GetMonth() == 9 and NZDate.GetDay() >= 21) then
    --     NZEvents.Activate("Halloween", true)
    -- end

    NZEvents.Start()
end)

hook.Add("NZ.VarChanged", "NZEvents.HolidayCommandHandler", function(name, old, new)
    if name == "nzc_holiday_events" then
        if tonumber(new) < 1 then
            NZEvents.StopHoliday()
        else
            NZEvents.StartHoliday()
        end
    end
end)
