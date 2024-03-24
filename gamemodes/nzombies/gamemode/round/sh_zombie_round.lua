-- Since we can now assign a zombie class to configs, we need this kinda stuff.
nzRound.ZombieData = nzRound.ZombieData or {}
nzRound.ZombieType = nzRound.ZombieType or nil

if SERVER then
	hook.Add( "OnGameBegin", "nzZombieInit", function()
		nzRound:SetZombieType(nzMapping.Settings.zombietype)
	end)
end

function nzRound:GetZombieType()
	return self.ZombieType
end

function nzRound:GetZombieData(id)
    return self.ZombieData[id]
end

function nzRound:GetZombieClass()
    local data = self:GetZombieData(self:GetZombieType()) or self:GetZombieData(self:GetDefaultZombieType())
    if !data then return self:GetDefaultZombieData() end
    
    return data.class
end

function nzRound:AddZombieType(id, class, enemydata)
--	if SERVER then
		if class then
			local data = {}
			-- Which entity to spawn
			data.class = class
			nzRound.ZombieData[id] = data
            nzConfig.AddValidEnemy(class, enemydata)
        else
			nzRound.ZombieData[id] = nil -- Remove it if no valid class was added
			nzConfig.ValidEnemies[class] = nil
        end
--	else
		-- Clients only need it for the dropdown, no need to actually know the data and such
--		nzRound.ZombieData[id] = class
--	end
end

function nzRound:GetDefaultZombieType()
    return "WaW"
end

function nzRound:SetZombieType(id)
    if id == "None" then
        self.ZombieType = nil -- "None" makes a nil key
    else
        self.ZombieType = id or self:GetDefaultZombieType() -- A nil id defaults to "WaW", otherwise id
    end

    hook.Run("OnZombieTypeChanged", id)
end
