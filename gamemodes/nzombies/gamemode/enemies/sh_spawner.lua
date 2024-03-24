Spawner = Spawner or {}

if Spawner != nil then
    function Spawner:GetAll()
        local spawners = {}
    
        for _,ent in pairs(ents.GetAll()) do
            if ent.NZSpawner then
                spawners[#spawners + 1] = ent
            end
        end
    
        return spawners
    end

    function Spawner:GetAliasAndClasses(special_alias) -- Spawners don't have aliases, we just use for stuff like the Tool Menu
        local alias_and_classes = {["Special"] = "nz_spawn_zombie_special"}
        
        for _,scripted_tbl in pairs(scripted_ents.GetList()) do
            local tbl = scripted_tbl.t  
            if tbl and scripted_tbl.Base == "nz_spawner_base" then
                if !special_alias then
                    alias_and_classes[tbl.PrintName or "Undefined"] = tbl.ClassName
                elseif (tbl.SpecialPrintName) then
                    alias_and_classes[tbl.SpecialPrintName] = tbl.ClassName
                end
            end
        end

        return alias_and_classes
    end

    function Spawner:GetClasses()
        return table.ClearKeys(Spawner:GetAliasAndClasses())
    end
end
