local entMeta = FindMetaTable("Entity")

-- Proper entity fading support added by: Ethorbit
-- I have no idea why Facepunch has not added anything
-- for this after all these years...

-- This was needed for the new nzRagdolls class, for
-- when it removes ragdolls (a fading out effect is nice)
local fade_tbl = {}
local function fade_ent(ent, fadeIn, time, target, cb)
    ent:StopFading() -- Cancel whatever's already in progress..
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR) -- Allow transparency to take place on model

    local fade_hook_name = "NZEntityFading" .. (CurTime() + math.random(1000)) -- Create unique hook name

    fade_tbl[ent] = { -- Keep track of things for the outside
        ["fading_out"] = !fadeIn,
        ["fading_in"] = fadeIn,
        ["time"] = time,
        ["hook_name"] = fade_hook_name
    }

    local end_time = CurTime() + time
    local starting_alpha = math.abs(255 - math.Clamp(target, 0, 255))
    if starting_alpha == 0 then return end

    hook.Add("Think", fade_hook_name, function()
        if CurTime() >= end_time or !IsValid(ent) then
            hook.Remove("Think", fade_hook_name)

            if IsValid(ent) then
                fade_tbl[ent] = nil
                if cb then cb() end
            end
        return end

        local time_left = end_time - CurTime()
        fade_tbl[ent].time_left = time_left

        local ent_col = ent:GetColor()

        -- You might notice this will finish a little before the provided time is up.

        -- I honestly don't know why, but I've tried 60 different ways and I'm exhausted..
        -- If you have a mega brain, please improve this for me.
        ent_col.a = math.Approach(ent_col.a, target, FrameTime() * (starting_alpha / time_left))

        ent:SetColor(ent_col)
    end)
end

function entMeta:FadeOut(time, target, cb)
    fade_ent(self, false, time or 1, target or 0, cb)
end

function entMeta:FadeIn(time, target, cb)
    fade_ent(self, true, time or 1, target or 255, cb)
end

function entMeta:StopFading()
    if !fade_tbl[self] or !fade_tbl[self].hook_name then return end
    hook.Remove("Think", fade_tbl[self].hook_name)
end

function entMeta:IsFadingOut()
    return fade_tbl[self] and fade_tbl[self].fading_out
end

function entMeta:IsFadingIn()
    return fade_tbl[self] and fade_tbl[self].fading_in
end
