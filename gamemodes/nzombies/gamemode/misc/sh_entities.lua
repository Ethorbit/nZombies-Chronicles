-- Entity misc functions created by Ethorbit,
-- for functions that edit a specific entity or
-- group of entities that don't really belong in
-- the ENTITY meta table.

-- Move spawns, added because Map Scripts for maps like nz_winds need
-- the ability to change the player spawn position dynamically
-- to function as intended.
function nzMisc:MovePlayerSpawns(spawn_positions)
    local previous_spawns = ents.FindByClass("player_spawns")

    for _,spawn_position in pairs(spawn_positions) do
    local new_spawn = ents.Create("player_spawns")
    new_spawn:SetPos(spawn_position)
    new_spawn:Spawn()
    end

    for _,previous_spawn in pairs(previous_spawns) do
     previous_spawn:Remove()
    end

    nzRound:ResetPlayerSpawns()
end 
