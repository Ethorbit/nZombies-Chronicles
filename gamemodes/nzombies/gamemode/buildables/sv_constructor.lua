-- Created by Ethorbit, recoded itemcarrying from scratch because of how bad the code was

-- This file handles keeping track and managing our buildable entities 
-- (The helper functions for this are in the sh_functions.lua)

---- Parts
nzParts = nzParts or {}
nzParts.Data = nzParts.Data or {} -- To store the part entities, positions, angles, etc used for the resetting and respawning functionality below

function nzParts:Add(pos, angle, model, buildclass) -- Add a part to the map
    nzParts.Data[model] = nzParts.Data[model] or {}

    --nzParts.Entities[model] = nzParts.Entities[model] or {}

    local newEnt = ents.Create("nz_workbench_prop")
    newEnt:SetModel(model)
    newEnt:SetPos(pos)
    newEnt:SetAngles(angle)

    if buildclass != nil then
        newEnt:SetBuildClass(buildclass)
    end

    newEnt:Spawn()
    newEnt:Activate()
    newEnt:PhysicsInit( SOLID_VPHYSICS )
    newEnt:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    --nzParts.Entities[model][#nzParts.Entities[model] + 1] = newEnt
    nzParts.Data[model][#nzParts.Data[model] + 1] = {
        ["pos"] = pos,
        ["angles"] = angle,
        ["buildclass"] = buildclass,
        ["entity"] = newEnt
    }
end

function nzParts:Clear() -- Properly remove all parts from the map
    for _,v in pairs(nzParts:GetAll()) do
        v:Remove()
    end

    nzParts.Data = {}
    nzParts.Network:RemoveAll()
end

function nzParts:KeepOneOfEach() -- Keep one part for each model
    for _,mdlTbl in pairs(nzParts.Data) do
        if mdlTbl then
            local keep = table.Random(mdlTbl) -- Randomly decide which model part stays
            for _,dataTbl in pairs(mdlTbl) do -- Remove all but the one we decided to keep
                if (dataTbl != keep and IsValid(dataTbl.entity)) then
                    dataTbl.entity:Remove()
                end
            end
        end
    end
end

function nzParts:RemoveByModel(model)
    for _,mdlTbl in pairs(nzParts.Data[model]) do
        for _,dataTbl in pairs(mdlTbl) do
            if IsValid(dataTbl.entity) then
                dataTbl.entity:Remove()
            end
        end
    end
    
    nzParts.Data[model] = {}
end

function nzParts:RemoveByEntity(ent)
    for k,mdlTbl in pairs(nzParts.Data) do
        if mdlTbl then
            for k2,dataTbl in pairs(mdlTbl) do
                if dataTbl.entity == ent then 
                    dataTbl.entity:Remove()
                    nzParts.Data[k][k2] = nil -- Remove the data for this entity as we are getting rid of it
                end
            end
        end
    end
end

function nzParts:UpdateEntity(ent)
    for k,mdlTbl in pairs(nzParts.Data) do
        if mdlTbl then
            for k2,dataTbl in pairs(mdlTbl) do
                if dataTbl.entity == ent then  
                    nzParts.Data[k][k2] = { -- Update it
                        ["pos"] = ent:GetPos(),
                        ["angles"] = ent:GetAngles(),
                        ["buildclass"] = ent:GetBuildClass(),
                        ["entity"] = ent
                    }
                end
            end
        end
    end
end

function nzParts:ResetAll() -- Properly resets parts by removing them and then recreating them
    local build_data = table.Copy(nzParts.Data) -- Save the data (angles, positions, etc) before clearing
    
    -- Remove all parts from Workbenches before we recreate them (Or else the build count may stack on them)
    for _,table in pairs(nzBenches:GetAll()) do
        table:RemoveParts()
    end
    
    nzParts:Clear()

    -- Add all the parts back from data
    for k,mdlTbl in pairs(build_data) do
        if mdlTbl then
            for _,dataTbl in pairs(mdlTbl) do
                nzParts:Add(dataTbl.pos, dataTbl.angles, k, dataTbl.buildclass)
            end
        end
    end
end

---- Workbenches
nzBenches = nzBenches or {}

function nzBenches:Add(pos, angle, data) -- Add a workbench to the map
	local bench = ents.Create("buildable_table")
    bench:SetPos(pos)
    bench:SetAngles(angle)

    if data.buildclass != nil then bench:SetBuildClass(data.buildclass) end
    if data.wonderweapon != nil then bench:SetTreatAsWonderWeapon(tobool(data.wonderweapon)) end
    if data.refillammo != nil then bench:SetRefillAmmo(tobool(data.refillammo)) end
    if data.craftuses != nil then bench:SetCraftUses(data.craftuses) end
    if data.maxcrafts != nil then bench:SetMaxCrafts(data.maxcrafts) end
    if data.cooldowntime != nil then bench:SetCooldownTime(data.cooldowntime) end
    if data.addtobox != nil then bench:SetAddToBox(tobool(data.addtobox)) end
    if data.boxchance != nil then bench:SetBoxChance(data.boxchance) end

    bench:Spawn()
    bench:Activate()
    bench:PhysicsInit( SOLID_VPHYSICS )
 
	local phys = bench:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
end

function nzBenches:ResetAll()
    for _,v in pairs(nzBenches:GetAll()) do
        v:Reset()
    end
end
