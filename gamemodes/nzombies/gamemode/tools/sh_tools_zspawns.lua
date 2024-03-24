nzTools:CreateTool("zspawner", {
	displayname = "Special Spawn",
	desc = "LMB: Place Spawnpoint, RMB: Remove Spawnpoint",
	condition = function(wep, ply)
		-- Function to check whether a player can access this tool - always accessible
		return true
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		-- Create a new spawnpoint and set its data to the guns properties
		local ent
		if IsValid(tr.Entity) and tr.Entity.NZSpawner then
			ent = tr.Entity -- No need to recreate if we shot an already existing one
		else
			ent = nzMapping:ZedSpawn(data.spawnertype, tr.HitPos, nil, tobool(data.spawnnearplayers), nil, ply)
		end

		ent.flag = tobool(data.flag)

		if tobool(data.flag) and ent.link != "" then
			ent.link = tostring(data.link)
		else
			ent.link = "disabled"
		end

		-- For the link displayer
		if data.link then
			ent:SetLink(ent.link)
		end

		if data.spawnnearplayers != nil then
			ent:SetSpawnNearPlayers(tobool(data.spawnnearplayers))
		end
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		-- Remove entity if it is a zombie spawnpoint
		if IsValid(tr.Entity) and tr.Entity.NZSpawner then
			tr.Entity:Remove()
		end
	end,
	Reload = function(wep, ply, tr, data)
		-- Nothing
	end,
	OnEquip = function(wep, ply, data)

	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Zombie Spawn Creator",
	desc = "LMB: Place Spawnpoint, RMB: Remove Spawnpoint",
	icon = "icon16/user_green.png",
	weight = 2,
	condition = function(wep, ply)
		return true
	end,
	interface = function(frame, data, idk, skipCombo)
		local valz = {}
		valz["SpawnerType"] = tostring(data.spawnertype)
		valz["Row1"] = tobool(data.flag)
		valz["Row2"] = tostring(data.link)
		valz["Row3"] = tobool(data.spawnnearplayers)

		local DProperties = vgui.Create( "DProperties", frame )
		DProperties:SetSize( 280, 180 )
		DProperties:SetPos( 110, 20 )
		
		function DProperties.CompileData()
			data.spawnertype = tostring(valz["SpawnerType"])
			data.flag = tobool(valz["Row1"])
			data.link = tostring(valz["Row2"])
			data.spawnnearplayers = tobool(valz["Row3"])
			
			return data
		end
		
		function DProperties.UpdateData(data)
			nzTools:SendData(data, "zspawner")
		end

		if !skipCombo then
			local spawnTypeRow = DProperties:CreateRow( "Zombie Spawn", "Spawner Type" )
			spawnTypeRow:Setup("Combo")

			-- Dynamically populate list by iterating through all the spawner entities placed in the gamemode:
			for alias, class in pairs(Spawner:GetAliasAndClasses()) do
				spawnTypeRow:AddChoice(alias, class, alias == "Zombie")
			end

			spawnTypeRow.DataChanged = function(_, val) valz["SpawnerType"] = val DProperties.UpdateData(DProperties.CompileData()) end
			spawnTypeRow:SetValue(valz["SpawnerType"])
		end

		local Row1 = DProperties:CreateRow( "Zombie Spawn", "Enable Flag?" )
		Row1:Setup( "Boolean" )
		Row1:SetValue( valz["Row1"] )
		Row1.DataChanged = function( _, val ) valz["Row1"] = val DProperties.UpdateData(DProperties.CompileData()) end

		local Row2 = DProperties:CreateRow( "Zombie Spawn", "Flag" )
		Row2:Setup( "Integer" )
		Row2:SetValue( valz["Row2"] )
		Row2.DataChanged = function( _, val ) valz["Row2"] = val DProperties.UpdateData(DProperties.CompileData()) end

		local Row3 = DProperties:CreateRow( "Zombie Spawn", "Spawn Near Players?" )
		Row3:Setup( "Boolean" )
		Row3:SetValue( valz["Row3"] )
		Row3.DataChanged = function( _, val ) valz["Row3"] = val DProperties.UpdateData(DProperties.CompileData()) end

		local text = vgui.Create("DLabel", DProperties)
		text:SetText("Special Spawnpoints apply to Hellhounds, bosses")
		text:SetFont("Trebuchet18")
		text:SetPos(0, 130)
		text:SetTextColor( Color(50, 50, 50) )
		text:SizeToContents()
		text:CenterHorizontal()

		local text2 = vgui.Create("DLabel", DProperties)
		text2:SetText("and for respawning with Who's Who")
		text2:SetFont("Trebuchet18")
		text2:SetPos(0, 150)
		text2:SetTextColor( Color(50, 50, 50) )
		text2:SizeToContents()
		text2:CenterHorizontal()

		return DProperties
	end,
	defaultdata = {
		spawnertype = "nz_spawn_zombie_normal",
		flag = 0,
		link = 1,
		spawnable = 1,
		respawnable = 1,
		spawnnearplayers = true
	}
})
