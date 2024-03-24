-- Recoded Itemcarry from scratch by Ethorbit
-- This file handles keeping track of Parts that players have for both server and client

nzParts = nzParts or {}
nzParts.Equipped = nzParts.Equipped or {} -- Parts the player has
nzParts.PartsForBenches = nzParts.PartsForBenches or {} -- Workbenches that the player has parts for

local function UpdateCompatibleWorkbenches(ply)
    nzParts.PartsForBenches[ply] = {}
    
    if !ply.GetParts then return end
    local benches = nzBenches:GetFromParts(ply:GetParts())
    for _,bench in pairs(benches) do
        nzParts.PartsForBenches[ply][bench] = true
    end
end

local function AddPart(ply, part)
    if !nzParts.Equipped[ply] then nzParts.Equipped[ply] = {} end
    nzParts.Equipped[ply][part] = part
    UpdateCompatibleWorkbenches(ply)

    hook.Call("OnPartAdded", nil, ply, part)
end

local function RemovePart(ply, part)
    if !nzParts.Equipped[ply] then nzParts.Equipped[ply] = {} end
    nzParts.Equipped[ply][part] = nil 

    UpdateCompatibleWorkbenches(ply)

    hook.Call("OnPartRemoved", nil, ply, part)
end

local function RemoveParts(ply, parts)
    for _,part in pairs(parts) do
        RemovePart(ply, part)
    end
end

local function RemoveAllPartsForPlayer(ply)
    nzParts.Equipped[ply] = {}
    nzParts.PartsForBenches[ply] = {}

    for _,v in pairs(nzParts.Equipped[ply]) do
        hook.Call("OnPartRemoved", nil, ply, v)
    end
end

local function RemoveAllParts()
    for _,v in pairs(player.GetAll()) do
        RemoveAllPartsForPlayer(v)
    end
    
    nzParts.Equipped = {}
    nzParts.PartsForBenches = {}
end

if SERVER then
    util.AddNetworkString("NZ.AddedPart")
    util.AddNetworkString("NZ.RemovedPart")
    util.AddNetworkString("NZ.RemovedParts")
    util.AddNetworkString("NZ.RemovedAllPartsForPlayer")
    util.AddNetworkString("NZ.RemovedAllParts")

    nzParts.Network = nzParts.Network or {}

    function nzParts.Network:InitForPlayer(ply) -- Initialize everything, this player has no prior information of networked parts yet
        if nzMapping.Settings.buildablesshare then -- If parts are shared, set our parts to someone who has the updated shared parts
            for _,plyEquipment in pairs(nzParts.Equipped) do
                if plyEquipment != nil then
                    nzParts.Equipped[ply] = table.Copy(plyEquipment)
                    for _,part in pairs(nzParts.Equipped[ply]) do
                        for _,v in pairs(player.GetAll()) do
                            net.Start("NZ.AddedPart")
                            net.WriteEntity(v)
                            net.WriteEntity(part)
                            net.Send(ply)
                        end
                    end
                end
            end
        else
            -- Get all player parts
            for _,v in pairs(player.GetAll()) do
                for _,part in pairs(v:GetParts()) do
                    net.Start("NZ.AddedPart")
                    net.WriteEntity(v)
                    net.WriteEntity(part)
                    net.Send(ply)
                end
            end
        end
    end

    function nzParts.Network:Add(ply, part)
        net.Start("NZ.AddedPart")
        net.WriteEntity(ply)
        net.WriteEntity(part)
        net.Broadcast()
        AddPart(ply, part)
    end

    function nzParts.Network:Remove(ply, part)
        net.Start("NZ.RemovedPart")
        net.WriteEntity(ply)
        net.WriteEntity(part)
        net.Broadcast()
        RemovePart(ply, part)
    end

    function nzParts.Network:RemoveParts(ply, parts)
        net.Start("NZ.RemovedParts")
        net.WriteEntity(ply)
        net.WriteTable(parts)
        net.Broadcast()
        RemoveParts(ply, parts)
    end

    function nzParts.Network:RemoveAllPartsForPlayer(ply)
        net.Start("NZ.RemovedAllPartsForPlayer")
        net.WriteEntity(ply)
        net.Broadcast()
        RemoveAllPartsForPlayer(ply)
    end

    function nzParts.Network:RemoveAll()
        net.Start("NZ.RemovedAllParts")
        net.Broadcast()
        RemoveAllParts()
    end
end

if CLIENT then
    net.Receive("NZ.AddedPart", function()
        local ply = net.ReadEntity()
        local part = net.ReadEntity()
        AddPart(ply, part)
    end)

    net.Receive("NZ.RemovedPart", function()
        local ply = net.ReadEntity()
        local part = net.ReadEntity()
        RemovePart(ply, part)
    end)

    net.Receive("NZ.RemovedParts", function()
        local ply = net.ReadEntity()
        local parts = net.ReadTable()
        RemoveParts(ply, parts)
    end)

    net.Receive("NZ.RemovedAllPartsForPlayer", function()
        local ply = net.ReadEntity()
        RemoveAllPartsForPlayer(ply)
    end)

    net.Receive("NZ.RemovedAllParts", function()
        RemoveAllParts()
    end)
end
