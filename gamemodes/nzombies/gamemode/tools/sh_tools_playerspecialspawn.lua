nzTools:CreateTool("playerspecialspawn", {
	displayname = "Special Player Spawn",
	desc = "LMB: Place Spawnpoint, RMB: Remove Spawnpoint",
	condition = function(wep, ply)
		-- Function to check whether a player can access this tool - always accessible
		return true
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		-- Create a new spawnpoint and set its data to the guns properties
		local ent
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "nz_spawn_player_special" then
			ent = tr.Entity -- No need to recreate if we shot an already existing one
		else
			ent = nzMapping:PlayerSpecialSpawn(tr.HitPos, nil, ply)
		end

		ent.flag = data.flag
		if tobool(data.flag) and ent.link != "" then
			ent.link = data.link
		end

		-- For the link displayer
		if data.link then
			ent:SetLink(data.link)
		end
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		-- Remove entity if it is a zombie spawnpoint
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "nz_spawn_player_special" then
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
	displayname = "Special Player Spawn",
	desc = "LMB: Place Spawnpoint, RMB: Remove Spawnpoint",
	icon = "icon16/user_gray.png",
	weight = 2,
	condition = function(wep, ply)
		return true
	end,
	interface = function(frame, data)
		local valz = {}
		valz["Row1"] = data.flag
		valz["Row2"] = data.link

		local DProperties = vgui.Create( "DProperties", frame )
		DProperties:SetSize( 280, 180 )
		DProperties:SetPos( 110, 20 )
		
		function DProperties.CompileData()
			local str="nil"
			if valz["Row1"] == 0 then
				str=nil
				data.flag = 0
			else
				str=valz["Row2"]
				data.flag = 1
			end
			data.link = str
			
			return data
		end
		
		function DProperties.UpdateData(data)
			nzTools:SendData(data, "playerspecialspawn")
		end

		local Row1 = DProperties:CreateRow( "Player Spawn", "Enable Flag?" )
		Row1:Setup( "Boolean" )
		Row1:SetValue( valz["Row1"] )
		Row1.DataChanged = function( _, val ) valz["Row1"] = val DProperties.UpdateData(DProperties.CompileData()) end
		local Row2 = DProperties:CreateRow( "Player Spawn", "Flag" )
		Row2:Setup( "Integer" )
		Row2:SetValue( valz["Row2"] )
		Row2.DataChanged = function( _, val ) valz["Row2"] = val DProperties.UpdateData(DProperties.CompileData()) end

		local text = vgui.Create("DLabel", DProperties)
		text:SetText("Works exactly like the Zombie Special Spawn")
		text:SetFont("Trebuchet18")
		text:SetTextColor( Color(50, 50, 50) )
		text:SizeToContents()
		text:Center()

		local text2 = vgui.Create("DLabel", DProperties)
		text2:SetText("but for Who's Who and thirdparty addons,")
		text2:SetFont("Trebuchet18")
		text2:SetPos(0, 100)
		text2:SetTextColor( Color(50, 50, 50) )
		text2:SizeToContents()
		text2:CenterHorizontal()

		local text3 = vgui.Create("DLabel", DProperties)
		text3:SetText("useful for maps where special spawns")
		text3:SetFont("Trebuchet18")
		text3:SetPos(0, 117)
		text3:SetTextColor( Color(50, 50, 50) )
		text3:SizeToContents()
		text3:CenterHorizontal()

		local text4 = vgui.Create("DLabel", DProperties)
		text4:SetText("need to be outside the map")
		text4:SetFont("Trebuchet18")
		text4:SetPos(0, 134)
		text4:SetTextColor( Color(50, 50, 50) )
		text4:SizeToContents()
		text4:CenterHorizontal()

		return DProperties
	end,
	defaultdata = {
		flag = 0,
		link = 1,
		spawnable = 1,
		respawnable = 1,
	}
})
