-- Converted nZombies fog from clientside to serverside

-- The reason: More reliable and much more control over it 
-- including optimization with FarZ (which is not supported in clientside fog)  
-- this is what controls what can/can't render in fog. This means
-- that doing the fog serverside actually increases game 
-- peformance, and allows uers to optimize their configs!

local function RemoveClass(class)
    for _,v in pairs(ents.FindByClass(class)) do
        if (IsValid(v)) then
            v:Remove()
        end
    end
end

nzFog = nzFog or {}
nzFog.FadeOrder = nzFog.FadeOrder or {}
nzFog.NoFog = false 
nzFog.SpecialDefaults = {
    ["fogstart"] = 0,
    ["fogend"] = 2000,
    ["fogmaxdensity"] = 0.6,
    ["fogcolor"] = "255 255 255"
}

nzFog.EditCache = nzFog.EditCache or {}
nzFog.EditSpecialCache = nzFog.EditSpecialCache or {}

function nzFog.UnsupportedColors()
	local fogEdit = ents.FindByClass("edit_fog")[1]
	return IsValid(fogEdit) and fogEdit.GetFarZUnsupportedColors and fogEdit:GetFarZUnsupportedColors()
end

local function RoundColor(color)
    if (!nzFog.Optimized()) then return color end -- Rounding the color is only required if the FarZ is set, since unrounded colors are not compatible with it
    if !color.r or !color.g or !color.b then return end 
	
	-- Check if the config creator wants to force full colors or not. 
	if (nzFog.UnsupportedColors()) then return color end 
    
	local returnBig
    if (color.r > 1) then returnBig = true color.r = color.r / 255 end
    if (color.g > 1) then color.g = color.g / 255 end
    if (color.b > 1) then color.b = color.b / 255 end
    color.r = returnBig and math.Round(color.r) * 255 or math.Round(color.r)
    color.g = returnBig and math.Round(color.g) * 255 or math.Round(color.g)
    color.b = returnBig and math.Round(color.b) * 255 or math.Round(color.b)
    color.a = 1
    return color
end

function nzFog.IsSpecialFog()
    if (nzFog.NoFog) then
        return IsValid(nzFog.Entity) and tonumber(nzFog.Entity:GetKeyValues()["fogmaxdensity"]) > 0
    else
        return istable(nzFog.FadeOrder) and (table.ToString(nzFog.FadeOrder[1]) == table.ToString(nzFog.SpecialFogTable)) 
    end
end

function nzFog.ResetFadeOrder() -- Order swapped each time a special round starts/ends (This is a stupid way to handle it but I was bored)
    if (!IsValid(nzFog.Entity)) then return end -- Doesn't matter, we have no fog to control
    local fogEdit = ents.FindByClass("edit_fog")[1]
    -- Fog and special fog exist, switch between the two for special rounds
    if (table.Count(nzFog.EditSpecialCache) > 0 and table.Count(nzFog.EditCache) > 0) then
        nzFog.FadeOrder = {
            [1] = {["Color"] = RoundColor(nzFog.EditCache["fogcolor"] * 255)},
            [2] = {["Color"] = RoundColor(nzFog.EditSpecialCache["fogcolor"] * 255)}
        }

    -- Fog set, but no special fog configured, just do white fog for special fog
    elseif (table.Count(nzFog.EditCache) > 0 and table.Count(nzFog.EditSpecialCache) <= 0) then
        nzFog.FadeOrder = {
            [1] = {["Color"] = RoundColor(nzFog.EditCache["fogcolor"] * 255)},
            [2] = {["Color"] = Vector(255, 255, 255)}
        }  
    -- No fog set, just use the special round fog's settings and return to nothing 
    elseif (table.Count(nzFog.EditCache) <= 0 and table.Count(nzFog.EditSpecialCache) > 0) then
        nzFog.FadeOrder = {
            [1] = {["Color"] = false},
            [2] = {["Color"] = RoundColor(nzFog.EditSpecialCache["fogcolor"] * 255)}
        }

        nzFog.NoFog = true
     -- No fog entities, just do white fog on special round and return to nothing
    elseif (table.Count(nzFog.EditCache) <= 0 and table.Count(nzFog.EditSpecialCache) <= 0) then 
        nzFog.FadeOrder = {
            [1] = {["Color"] = false},
            [2] = {["Color"] = Vector(255, 255, 255)}
        }

        nzFog.NoFog = true
    end

    -- Special and normal fog may have different values, add them to this:
    if (table.Count(nzFog.EditCache) > 0) then
        nzFog.FadeOrder[1]["fogstart"] = nzFog.EditCache["fogstart"]
        nzFog.FadeOrder[1]["fogend"] = nzFog.EditCache["fogend"]
        nzFog.FadeOrder[1]["fogmaxdensity"] = nzFog.EditCache["fogmaxdensity"]
        nzFog.FadeOrder[1]["fogcolor"] = nzFog.EditCache["fogcolor"]
    end

    if (table.Count(nzFog.EditSpecialCache) > 0) then
        nzFog.FadeOrder[2]["fogstart"] = nzFog.EditSpecialCache["fogstart"]
        nzFog.FadeOrder[2]["fogend"] = nzFog.EditSpecialCache["fogend"]
        nzFog.FadeOrder[2]["fogmaxdensity"] = nzFog.EditSpecialCache["fogmaxdensity"]
        nzFog.FadeOrder[2]["fogcolor"] = nzFog.EditSpecialCache["fogcolor"]
    else
        nzFog.FadeOrder[2]["fogstart"] = nzFog.SpecialDefaults["fogstart"]
        nzFog.FadeOrder[2]["fogend"] = nzFog.SpecialDefaults["fogend"]
        nzFog.FadeOrder[2]["fogmaxdensity"] = nzFog.SpecialDefaults["fogmaxdensity"]
        nzFog.FadeOrder[2]["fogcolor"] = nzFog.SpecialDefaults["fogcolor"]
    end

    -- Apply hardcoded limits for FarZ fog and Special fog (To make sure it always looks good)
    if (nzFog.Optimized()) then
        local keyVals = nzFog.Entity:GetKeyValues()
        local farz = keyVals.farz
 
        if (nzFog.FadeOrder[2].fogend > farz) then -- World can't render at this point, if fog goes past it, it will look terrible
            nzFog.FadeOrder[2].fogend = farz - 100 
        end

        nzFog.FadeOrder[2].fogmaxdensity = 1 -- Any density lower than 1 looks terrible with FarZ set
    end

    --nzFog.SpecialFogColor = nzFog.FadeOrder[2]["Color"]
    nzFog.SpecialFogTable = nzFog.FadeOrder[2]
end

function nzFog.Init()
    hook.Remove("Think", "NZFogFade")
    
    local fogEnt = ents.FindByClass("edit_fog")[1]
    local specialFogEnt = ents.FindByClass("edit_fog_special")[1]
    if (IsValid(fogEnt)) then
        nzFog.EditCache["fogstart"] = fogEnt:GetFogStart()
        nzFog.EditCache["fogend"] = fogEnt:GetFogEnd()
        nzFog.EditCache["fogmaxdensity"] = fogEnt:GetDensity()
        nzFog.EditCache["fogcolor"] = fogEnt:GetFogColor()
        nzFog.EditCache["farz"] = fogEnt:GetFarZ()
    end

    if (nzFog.EditCache["fogend"] and nzFog.EditCache["farz"] and tonumber(nzFog.EditCache["fogend"]) >= tonumber(nzFog.EditCache["farz"])) then
        nzFog.EditCache["fogend"] = nzFog.EditCache["farz"] - 100
        nzFog.Entity:SetKeyValue("fogend", nzFog.EditCache["fogend"])
    end

    if (IsValid(specialFogEnt)) then
        nzFog.EditSpecialCache["fogstart"] = specialFogEnt:GetFogStart()
        nzFog.EditSpecialCache["fogend"] = specialFogEnt:GetFogEnd()
        nzFog.EditSpecialCache["fogmaxdensity"] = specialFogEnt:GetDensity()
        nzFog.EditSpecialCache["fogcolor"] = specialFogEnt:GetFogColor()
    end
    
    nzFog.Entity = !IsValid(nzFog.Entity) and ents.Create("env_fog_controller") or nzFog.Entity

    if (!nzFog.EditCache["fogend"]) then 
        nzFog.Entity:SetKeyValue("farz", 100000)
    end
    
    nzFog.NoFog = false
    nzFog.Entity:SetName("NZFog")
    nzFog.Entity:SetKeyValue("fogenable", 1)
    nzFog.Entity:SetKeyValue("fogend", nzFog.EditCache["fogend"] or nzFog.SpecialDefaults["fogend"])
    nzFog.Entity:SetKeyValue("fogstart", nzFog.EditCache["fogstart"] or nzFog.SpecialDefaults["fogstart"])
    nzFog.Entity:SetKeyValue("spawnflags", 1)
    nzFog.Entity:SetKeyValue("fogmaxdensity", nzFog.EditCache["fogmaxdensity"] or 0)

    if (nzFog.EditCache["farz"] and tonumber(nzFog.EditCache["farz"]) < 10000) then
        nzFog.SetOptimized(true)
        nzFog.Entity:SetKeyValue("farz", nzFog.EditCache["farz"])
    else
        nzFog.SetOptimized(false)
    end

    for _,v in pairs(player.GetAll()) do
        nzFog.Emit(v)
    end
    
    nzFog.SetColor(nzFog.EditCache["fogcolor"] or string.ToColor(nzFog.SpecialDefaults["fogcolor"]):ToVector())
    nzFog.ResetFadeOrder()
end
hook.Add("PostConfigLoad", "NZAddFog", nzFog.Init)
hook.Add("OnEntityCreated", "NZNewFog", function(ent)
    if (IsValid(ent)) then
        if (ent:GetClass() == "edit_fog" or ent:GetClass() == "edit_fog_special") then
            timer.Simple(0.2, function()
                nzFog.Init()
            end)
        end
    end
end)

hook.Add("Think", "NZKeepFog", function()
    for _,v in pairs(ents.FindByClass("env_fog_controller")) do
        if (IsValid(nzFog.Entity) and v != nzFog.Entity) then 
            v:Remove() 
        end
    end

    if (#ents.FindByClass("env_fog_controller") == 1 and !IsValid(nzFog.Entity)) then
        nzFog.Entity = ents.FindByClass("env_fog_controller")[1]
    end
end)

hook.Add("EntityRemoved", "NZNewFog2", function(ent)
    if (ent:GetClass() == "edit_fog" or ent:GetClass() == "edit_fog_special") then
        nzFog.Init()
    end
end)

function nzFog.GetFog()
    return self.Entity
end

function nzFog.SetOptimized(bool)
    nzFog.optimized = bool

    if (bool) then 
        -- If it's optimized then that means FarZ was set, 
        -- which means the map's sky needs to go, otherwise
        -- this will look VERY BAD in-game as the FarZ will 
        -- be visibly clipping off the world
        RunConsoleCommand("sv_skyname", "painted")
        RemoveClass("env_skypaint")
        RemoveClass("sky_camera")
		
        nzFog.SkyEnt = ents.Create("env_skypaint")
        nzFog.SkyEnt:SetName("NZSky")
        nzFog.SkyEnt:SetKeyValue("sunsize", 0.0)
        nzFog.SkyEnt:SetKeyValue("starscale", 0.0)
    else
        if (IsValid(nzFog.SkyEnt)) then
            nzFog.SkyEnt:Remove()
        end
    end
end

function nzFog.Optimized()
    return nzFog.optimized
end

function nzFog.SetColor(color) 
    if color and color.r and color.g and color.b then
        color = RoundColor(color)
        local strColor2 = string.format("%f %f %f", color.r * 255, color.g * 255, color.b * 255) --Color(color.r * 255, color.g * 255, color.b * 255)
        local strColor = tostring(color)
        
        if (IsValid(nzFog.Entity)) then
            nzFog.Entity:SetKeyValue("fogcolor", strColor2)
            if (IsValid(nzFog.SkyEnt)) then 
				if !nzFog.UnsupportedColors() then 
					nzFog.SkyEnt:SetKeyValue("topcolor", strColor)
					nzFog.SkyEnt:SetKeyValue("bottomcolor", strColor)
					nzFog.SkyEnt:SetKeyValue("duskcolor", strColor)
				end
            end
        end
    end
end

function nzFog.Emit(ply)
    ply:Input("SetFogController", ply, ply, "NZFog")
end

function nzFog.Fade(fadein) -- Fades fog from one color to another, used in special round transitioning
    if (!IsValid(nzFog.Entity)) then ServerLog("[nZ] No fog entity exists! No special round fog was created!\n") return end
    local fogVals
    if (IsValid(nzFog.Entity)) then
        fogVals = nzFog.Entity:GetKeyValues()
    end

    local fade = 0
    local fadetime = 5

    if (nzFog.NoFog) then -- Map doesn't have fog, just fade the fog in and out normally - with no color mixing BS
        if (fogVals.fogmaxdensity <= 0) then
            nzFog.Entity:SetKeyValue("fogenable", 1)
            hook.Add("Think", "NZFogFade", function()
                if (!IsValid(nzFog.Entity)) then
                    hook.Remove("Think", "NZFogFade")
                return end

                fade = math.Approach(fade, nzFog.FadeOrder[2]["fogmaxdensity"], 0.003)
                nzFog.Entity:SetKeyValue("fogmaxdensity", fade)

                if (fade >= 1) then
                    hook.Remove("Think", "NZFogFade")
                end
            end)
        else
            fade = nzFog.FadeOrder[2]["fogmaxdensity"]
            hook.Add("Think", "NZFogFade", function()
                if (!IsValid(nzFog.Entity)) then
                    hook.Remove("Think", "NZFogFade")
                return end

                fade = fade - 0.003
                nzFog.Entity:SetKeyValue("fogmaxdensity", fade)

                if (fade <= 0) then
                    hook.Remove("Think", "NZFogFade")
                    nzFog.Entity:SetKeyValue("fogenable", 0)
                end
            end)
        end
    return end
    
    local fogcolor
    local fogstart
    local fogend
    local fogmaxdensity
    hook.Add("Think", "NZFogFade", function()  
        if (IsValid(nzFog.Entity) and istable(fogVals)) then
            fade = math.Approach(fade, 1, FrameTime() / fadetime)
            if (!nzFog.FadeOrder) then return end

            local input = nzFog.FadeOrder[1]["Color"] != nil and nzFog.FadeOrder[1]["Color"] or Vector(0, 0, 0)
            local output = nzFog.FadeOrder[2]["Color"] != nil and nzFog.FadeOrder[2]["Color"] or Vector(0, 0, 0)
            fogcolor = LerpVector(fade, input, output) 

            if (nzFog.FadeOrder[1].fogstart and nzFog.FadeOrder[2].fogstart) then
                fogstart = Lerp(fade, nzFog.FadeOrder[1].fogstart, nzFog.FadeOrder[2].fogstart)
            end
            
            if (nzFog.FadeOrder[1].fogend and nzFog.FadeOrder[2].fogend) then
                fogend = Lerp(fade, nzFog.FadeOrder[1].fogend, nzFog.FadeOrder[2].fogend)
            end

            if (nzFog.FadeOrder[1].fogmaxdensity and nzFog.FadeOrder[2].fogmaxdensity) then
                fogmaxdensity = Lerp(fade, nzFog.FadeOrder[1].fogmaxdensity, nzFog.FadeOrder[2].fogmaxdensity)
            end

            local colStr2 = string.format("%f %f %f", fogcolor[1] / 255, fogcolor[2] / 255, fogcolor[3] / 255)
            local colStr = string.format("%f %f %f", fogcolor[1], fogcolor[2], fogcolor[3])
            nzFog.Entity:SetKeyValue("fogcolor", colStr)

            if fogstart then
                nzFog.Entity:SetKeyValue("fogstart", fogstart)
            end

            if fogend then
                nzFog.Entity:SetKeyValue("fogend", fogend)
            end
            
            if fogmaxdensity then
                nzFog.Entity:SetKeyValue("fogmaxdensity", fogmaxdensity)
            end

            if (IsValid(nzFog.SkyEnt)) then
                nzFog.SkyEnt:SetKeyValue("topcolor", colStr2)
                nzFog.SkyEnt:SetKeyValue("bottomcolor", colStr2)
                nzFog.SkyEnt:SetKeyValue("duskcolor", colStr2)
            end

            if fade >= 1 then
                hook.Remove("Think", "NZFogFade")
                nzFog.FadeOrder = table.Reverse(nzFog.FadeOrder)
            return end

            fogVals = nzFog.Entity:GetKeyValues()
        else
            hook.Remove("Think", "NZFogFade")
        end
    end)
end

-- Update when edit_fog is edited (Just like if it was from the edit_fog entity)
hook.Add("VariableEdited", "NZUpdateFog", function(ent, ply, key, val, editor)
    if (IsValid(ent)) then
        if (ent:GetClass() == "edit_fog") then
            nzFog.EditCache[key] = val

            if (IsValid(nzFog.Entity)) then
                nzFog.Entity:SetKeyValue(key, val)
				
				timer.Simple(0, function()
					if nzFog and IsValid(ent) then 
						if tonumber(nzFog.EditCache["farz"]) < 10000.0 then 
							nzFog.SetOptimized(true)
							nzFog.SetColor(ent:GetFogColor())
						else 
							nzFog.SetOptimized(false)
							nzFog.SetColor(ent:GetFogColor())
						end 
					end 
				end) 
				
				if (key == "farzunsupportedcolors") then 
					nzFog.SetColor(ent:GetFogColor())
				end 

                if (key == "fogcolor") then
                    nzFog.SetColor(ent:GetFogColor())
                end

                for _,v in pairs(player.GetAll()) do
                    nzFog.Emit(v)
                end
                --nzFog.Init()
            end

        elseif (ent:GetClass() == "edit_fog_special") then
            nzFog.EditSpecialCache[key] = val
        end
    end
end)

hook.Add("PlayerSpawn", "NZApplyFog", function(ply)
    if (ply:IsInCreative()) then
        nzFog.Init()
    end

    nzFog.Emit(ply)
end)

hook.Add("PlayerInitialSpawn", "NZApplyFog2", function()
    nzFog.Init()
end)

local didSpecialFog = false
hook.Add("OnRoundStart", "NZSpecialFog", function()
    if nzRound:IsSpecial() then
        nzFog.Fade()
    elseif (nzFog.IsSpecialFog()) then
        nzFog.Fade()
    end
end)

hook.Add("OnRoundEnd", "NZResetFog", nzFog.Init)
hook.Add("OnRoundChangeState", "NZResetFog2", function(nzRound, new, old)   
    if (new == 0 or new == 4) then
        nzFog.Init() 
    end
end)
