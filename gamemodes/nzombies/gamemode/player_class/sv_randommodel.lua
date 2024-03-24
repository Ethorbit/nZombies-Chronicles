NZAssignedModels = istable(NZAssignedModels) and !table.IsEmpty(NZAssignedModels) and NZAssignedModels or {}
NZDefaultModels = {
    {["Path"] = "models/player/dempsey_bo3.mdl"},
    {["Path"] = "models/player/nikolai_bo3.mdl"},
    {["Path"] = "models/player/richtofen_bo3.mdl"},
    {["Path"] = "models/player/takeo_bo3.mdl"}
}

local function AddAndShuffle()
    NZAssignedModels = {}

    if (!istable(nzMapping.Settings.modelpack)) then
        ServerLog("[NZ] No Model Pack has been set for: " .. game.GetMap() .. "). Using default models...")
        NZAssignedModels = table.Copy(NZDefaultModels)
    else
        NZAssignedModels = table.Copy(nzMapping.Settings.modelpack)
    end

    for i = 1, #NZAssignedModels do
        local rand = math.random(#NZAssignedModels)
        NZAssignedModels[i], NZAssignedModels[rand] = NZAssignedModels[rand], NZAssignedModels[i]
    end

    -- We've got our shuffled models, now repeat them so each player slot can be assigned to a value
    local originalCount = #NZAssignedModels
    while (#NZAssignedModels < game.MaxPlayers() and #NZAssignedModels > 0) do
        for i = 1, originalCount do
            if (#NZAssignedModels >= game.MaxPlayers()) then break end
            NZAssignedModels[#NZAssignedModels + 1] = NZAssignedModels[i]
        end
    end

    --PrintTable(NZAssignedModels)
end

hook.Add("OnRoundInit", "NZRandomizePlayerModels", function(round)
    AddAndShuffle()
end)

local function GetBodygroupID(ent, bodyname) -- Retrieves a bodygroup's ID from a bodygroup name
    local groupID = -99

    if (istable(ent:GetBodyGroups())) then
        for _,v in pairs(ent:GetBodyGroups()) do
            if (v.name == bodyname) then
                groupID = v.id
                break 
            end
        end
    end

    return groupID
end

hook.Add("PlayerSetModel", "NZAssignPlayerModels", function(ply)
    if (LevelData and LevelData["Perks"] and LevelData["Perks"]["Model Choice"] and LevelData["Perks"]["Model Choice"]["Level"] and ply:HighEnoughLevel(LevelData["Perks"]["Model Choice"]["Level"])) then 
        if (ply:GetInfoNum("NZC_OverrideModel", 1) == 0) then
            ply:SendLua("net.Start('lf_playermodel_update') net.SendToServer()")
        return end
    end

    if (#NZAssignedModels < #player.GetAll()) then return end
    
    if (NZAssignedModels and NZAssignedModels[ply:EntIndex()] and NZAssignedModels[ply:EntIndex()]["Path"]) then
        local mdl = NZAssignedModels[ply:EntIndex()]["Path"]
        local skin = 0
        if (NZAssignedModels[ply:EntIndex()]["Skin"]) then   
            skin = NZAssignedModels[ply:EntIndex()]["Skin"]
        end

        if (!isstring(mdl)) then ServerLog("[NZ] The playermodel retrieved by the shuffled ModelPack is NOT a string!") return end

        timer.Simple(0, function()
            ply:SetModel(mdl)
            ply:ConCommand("cl_playermodel " .. mdl)
            
            if (isfunction(TFAVOX_Init)) then -- Seems this doesn't wanna work in Singleplayer..
                TFAVOX_Init(ply, true, true)
            end

            -- Set the model's saved skin
            if (isnumber(skin)) then
                ply:SetSkin(skin)
            end

            ply:SetupHands() -- Update their hands to match the model

            -- Set the saved bodygroups:
            local savedBodyGroups = NZAssignedModels[ply:EntIndex()]["Bodygroups"]
            if (istable(savedBodyGroups)) then      
                for k,v in pairs(savedBodyGroups) do -- We only saved Group names, we need to get the the group IDs from them
                    local id = GetBodygroupID(ply, k)
                    if (id == -99) then return end -- function returned invalid id
                    ply:SetBodygroup(id, v)
                end
            end
        end)
    end
end)