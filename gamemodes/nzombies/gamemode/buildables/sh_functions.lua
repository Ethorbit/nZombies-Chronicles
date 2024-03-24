-- Recreated itemcarry from scratch by: Ethorbit
-- This file adds useful helper functions for buildable and workbench stuff

-------------- INTERNAL, IGNORE THIS -----------------------------------------------------------------
local function makeTable(in_tbl, condition_func, ...)
    local tbl = {}
    for _,v in pairs(in_tbl) do
        if condition_func(v, ...) then
            tbl[#tbl + 1] = v
        end
    end
    return tbl
end

local function buildclassMatch(ent, buildclass) return ent.GetBuildClass and ent:GetBuildClass() == buildclass end
----------------END OF INTERNAL CODE--------------------------------------------------------------------

----- Parts -----
nzParts = nzParts or {}

function nzParts:IsHeld(part, filter) -- Returns true if any player has this buildable
    for _,v in pairs(player.GetAll()) do
        if (v != filter and nzParts.Equipped[v] and nzParts.Equipped[v][part]) then
            return true
        end
    end
end

function nzParts:GetAll()
    return ents.FindByClass("nz_workbench_prop")
end

function nzParts:GetByModel(model) -- Get all parts using this model
    return nzParts.Data[model]
end

function nzParts:GetByBuildClass(buildclass) -- Get all parts by their buildclass
    return makeTable(nzParts:GetAll(), buildclassMatch, buildclass)
end

----- Workbenches -----
nzBenches = nzBenches or {}

function nzBenches:GetAll()
    return ents.FindByClass("buildable_table")
end

function nzBenches:GetByBuildClass(buildclass) -- Get Workbenches by buildclass
    return makeTable(nzBenches:GetAll(), buildclassMatch, buildclass)
end

function nzBenches:GetFromParts(parts) -- Get all workbenches associated with this part
    if !parts or table.IsEmpty(parts) then return {} end 
    
    local allBenches = nzBenches:GetAll()
    if #allBenches == 1 then return allBenches end -- If there's only 1 Workbench then all parts are allowed to be used on it

    allBenches = {}

    for _,part in pairs(parts) do
        for _,val in pairs(nzBenches:GetByBuildClass(part:GetBuildClass())) do
            allBenches[#allBenches + 1] = val
        end
    end

    return allBenches
end
