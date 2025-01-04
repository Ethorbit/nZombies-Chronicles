-- timing for reading dates added to the gamemode by Ethorbit
-- I did this so that we can schedule events for an Event System

-- Default timezone is UTC. To update the timezone, place this in your game or server addon:
-- For example, this sets 25200 seconds (7 hours) behind UTC, which would be PST:
-- hook.Add("GetTimeZone", "SetTimeZoneValue", function()
--      return os.time() - 25200
-- end)

NZDate = {
    GetDay = function() -- 1-12
        return tonumber(os.date("!%d", hook.Call("GetTimeZone")))
    end,
    GetMonth = function() -- 1-12
        return tonumber(os.date("!%m", hook.Call("GetTimeZone")))
    end,
    GetDayName = function() -- Monday-Sunday
        return os.date("!%A", hook.Call("GetTimeZone"))
    end,
}
