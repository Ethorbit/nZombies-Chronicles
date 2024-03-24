-- Fixed by Ethorbit

-- Setup round module
nzTraps = nzTraps or AddNZModule("Traps")
nzLogic = nzLogic or AddNZModule("Logic")
nzTrapsAndLogic = nzTrapsAndLogic or {}

nzTraps.Registry = nzTraps.Registry or {}
nzLogic.Registry = nzLogic.Registry or {}

local function register (tbl, classname)
	table.insert(tbl, classname)
end

function nzTraps:Register(classname)
	if !table.HasValue(self.Registry, classname) then
		register(self.Registry, classname)
	end
end

function nzLogic:Register(classname)
	if !table.HasValue(self.Registry, classname) then
		register(self.Registry, classname)
	end
end

function nzTraps:GetAll()
	return table.Copy(self.Registry)
end

function nzLogic:GetAll()
	return table.Copy(self.Registry)
end

function nzTrapsAndLogic:GetAll()
	local tbl = nzTraps:GetAll()
	table.Add(tbl, nzLogic:GetAll())
	return tbl
end