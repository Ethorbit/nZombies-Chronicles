Spawner = Spawner or {}

function Spawner:UpdateHooks(spawner)
	local spawner_class = spawner:GetClass()
	local hooks_added = {}
	local base_ent_tbl = baseclass.Get("base_anim") -- We'll use this to ensure we don't actually add hooks for function names that exist in entities already

	-- Add hooks for all functions that are valid hook names (This is similar to how Map Scripts are handled)
	if !hooks_added[spawner_class] then
		for funcName, func in pairs(spawner:GetTable()) do -- Loop all the table's values
			if (isfunction(func) and !base_ent_tbl[funcName]) then --and hook_tbl[funcName]) 
				local hookName = spawner_class .. "_" .. funcName -- Create our future hook's unique name

				hook.Remove(funcName, hookName) -- Not necessary, but it's a precaution.
				hook.Add(funcName, hookName, function(...) -- Add the hook that our table had a function for
					for _,spawner_ent in pairs(ents.FindByClass(spawner_class)) do -- Call the function for all the spawners of the same class
						func(spawner_ent, ...)
					end
				end) 
			end
		end

		hooks_added[spawner_class] = 1
	end
end

function Spawner:ResetSpawners()
    for _,spawner in pairs(Spawner:GetAll()) do
        spawner:Reset()
		Spawner:UpdateHooks(spawner)
    end
end

function Spawner:GetAllActive(input)
	local active_spawners = {}
	local spawners = input or Spawner:GetAll()

	for _,spawner in pairs(spawners) do
		if spawner:IsActive() then 
			active_spawners[#active_spawners + 1] = spawner
		end
 	end

	return active_spawners
end

function Spawner:GetActiveClasses()
	local added = {}
	local classes = {}

	for _,spawner in pairs(Spawner:GetAllActive()) do
		if !added[spawner:GetClass()] then
			added[spawner:GetClass()] = 1
			classes[#classes + 1] = spawner:GetClass()
		end
	end

	return classes
end
