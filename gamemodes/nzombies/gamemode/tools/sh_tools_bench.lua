-- Recreated by: Ethorbit

nzTools:CreateTool("bench", {
	displayname = "Workbench Placer",
	desc = "LMB: Place Workbench with Given Parameters, RMB: Remove Workbench",
	condition = function(wep, ply)
		return true
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "buildable_table" then
			local pos = tr.Entity:GetPos()
			local ang = tr.Entity:GetAngles()
			tr.Entity:Remove()
			nzBenches:Add(pos, ang, data)
		else
			nzBenches:Add(tr.HitPos, Angle(0,(ply:GetPos() - tr.HitPos):Angle()[2],0), data)
		end
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "buildable_table" then
			tr.Entity:Remove()
		end
	end,
	Reload = function(wep, ply, tr, data)
	--data.entposition = tr.HitPos

	end,
	OnEquip = function(wep, ply, data)

	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Workbench Placer",
	desc = "LMB: Place Workbench with Given Parameters, RMB: Remove Workbench",
	icon = "icon16/bricks.png",
	weight = 5,
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	interface = function(frame, data)
		local valz = {}
		valz["Row2"] = data.buildclass == nil and "" or data.buildclass
		valz["Row3"] = data.wonderweapon == nil and false or data.wonderweapon
		valz["Row4"] = data.refillammo == nil and false or data.refillammo
		valz["Row5"] = data.craftuses == nil and 99999 or data.craftuses
		valz["Row6"] = data.maxcrafts == nil and 99999 or data.maxcrafts
		valz["Row7"] = data.cooldowntime == nil and 0 or data.cooldowntime
		valz["Row8"] = data.addtobox == nil and false or data.addtobox
		valz["Row9"] = data.boxchance == nil and 10 or data.boxchance

		local DProperties = vgui.Create( "DProperties", frame )
		DProperties:SetSize( 400, 450 )
		DProperties:SetPos( 10, 10 )
		DProperties:Dock(FILL) 
		
		function DProperties.CompileData()
			data.buildclass = valz["Row2"]
			data.wonderweapon = valz["Row3"]
			data.refillammo = valz["Row4"]
			data.craftuses = valz["Row5"]
			data.maxcrafts = valz["Row6"]
			data.cooldowntime = valz["Row7"]
			data.addtobox = valz["Row8"]
			data.boxchance = valz["Row9"]
			return data
		end
		
		function DProperties.UpdateData(data)
			nzTools:SendData(data, "bench")
		end
		
		local Row2 = DProperties:CreateRow( "Bench Settings", "Weapon Given" )
		Row2:Setup( "Combo" )
		for k,v in pairs(weapons.GetList()) do
			if !v.NZTotalBlacklist then
				if v.Category and v.Category != "" then
					Row2:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
				else
					Row2:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
				end
			end
		end
		Row2:SetValue(valz["Row2"])
		Row2.DataChanged = function( _, val ) valz["Row2"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row2:SetToolTip("The weapon this Workbench can craft")

		local Row3 = DProperties:CreateRow( "Bench Settings", "Treat as Wonder Weapon?" )
		Row3:Setup("Bool")
		Row3:SetValue(valz["Row3"])
		Row3.DataChanged = function( _, val ) valz["Row3"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row3:SetToolTip("If on, nobody will be able to grab this weapon if someone is already using it just like Wonder Weapons from the Box.")

		local Row4 = DProperties:CreateRow( "Bench Settings", "Refill ammo on Re-Equip" )
		Row4:Setup("Bool")
		Row4:SetValue(valz["Row4"])
		Row4.DataChanged = function( _, val ) valz["Row4"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row4:SetToolTip("If off, give the weapon with ammo the first time and don't provide ammo at all next time.")

		local Row5 = DProperties:CreateRow( "Advanced", "Uses Per Craft" )
		Row5:Setup("Int", {min = 0, max = 99999})
		Row5:SetValue(valz["Row5"])
		Row5.DataChanged = function( _, val ) valz["Row5"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row5:SetToolTip("How many times you can get the weapon before you have to go build it again.")

		local Row6 = DProperties:CreateRow( "Advanced", "Max Allowed Crafts" )
		Row6:Setup("Int", {min = 0, max = 99999})
		Row6:SetValue(valz["Row6"])
		Row6.DataChanged = function( _, val ) valz["Row6"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row6:SetToolTip("How many times you are allowed to craft the time before it is not possible anymore.")

		local Row7 = DProperties:CreateRow( "Advanced", "Weapon Cooldown Seconds" )
		Row7:Setup("Int", {min = 0, max = 9999})
		Row7:SetValue(valz["Row7"])
		Row7.DataChanged = function( _, val ) valz["Row7"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row7:SetToolTip("The amount of seconds before this Workbench will give someone a weapon again.")

		local Row8 = DProperties:CreateRow( "Mystery Box", "Add to Box? (After Max Crafts)" )
		Row8:Setup("Bool")
		Row8:SetValue(valz["Row8"])
		Row8.DataChanged = function( _, val ) valz["Row8"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row8:SetToolTip("After the item cannot be built anymore, add to the Mystery Box.")

		local Row9 = DProperties:CreateRow( "Mystery Box", "Box Chance" )
		Row9:Setup("Int", {min = 1, max = 1000})
		Row9:SetValue(valz["Row9"])
		Row9.DataChanged = function( _, val ) valz["Row9"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row9:SetToolTip("If 'Add Box' option is checked, this is the chance it will appear in the box.")

		return DProperties	
	end,
	defaultdata = {
		buildclass = "",
		wonderweapon = false,
		refillammo = false,
		craftuses = 99999,
		maxcrafts = 99999,
		cooldowntime = 0,
		addtobox = false,
		boxchance = 10
	}
})