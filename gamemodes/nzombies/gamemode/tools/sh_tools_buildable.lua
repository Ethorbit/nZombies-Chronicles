nzTools:CreateTool("Part", {
	displayname = "Part Placer",
	desc = "LMB: Apply Part data, RMB: Turn back into Map Prop, Double-Reload: Delete all with the same Build Class",
	condition = function(wep, ply)
		return true
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		local ent = tr.Entity
		if !IsValid(ent) then return end
		if ent:IsDoor() or ent:IsBuyableProp() or ent:IsButton() then
			if !data.buildclass or !weapons.Get(data.buildclass) then
				ply:ChatPrint("Please set a valid weapon from the dropdown first.")
			else
				nzParts:Add(ent:GetPos(), ent:GetAngles(), ent:GetModel(), data.buildclass)
				ent:Remove() -- We replaced it with an nz_workbench_prop now, it can go away
			end	
		elseif (ent:IsValidPart()) then
			ent:SetBuildClass(data.buildclass)
		else
			ply:ChatPrint("That is not a valid Part prop")
		end
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		local ent = tr.Entity
		if !IsValid(ent) then return end

		if ent:GetClass() == "nz_workbench_prop" then
			local mapprop = ents.Create("prop_buys")
			mapprop:SetPos(ent:GetPos())
			mapprop:SetModel(ent:GetModel())
			mapprop:SetAngles(ent:GetAngles())
			mapprop:Spawn()
			mapprop:Activate()
			mapprop:PhysicsInit( SOLID_VPHYSICS )
			mapprop:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

			nzParts:RemoveByEntity(ent)
		end
	end,
	Reload = function(wep, ply, tr, data)
		local ent = tr.Entity 
		if (IsValid(ent) and ent:GetClass() == "nz_workbench_prop") then
			if (ent.LastPartReload and CurTime() - ent.LastPartReload < 1.5) then
				nzParts:RemoveByModel(ent:GetModel())
				ent.LastPartReload = nil
			end

			ent.LastPartReload = CurTime()
		end
	end,
	OnEquip = function(wep, ply, data)

	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Part Placer",
	desc = "LMB: Apply Part data, RMB: Remove Data, Reload: Delete entire group",
	icon = "icon16/wrench.png",
	weight = 3,
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	interface = function(frame, data, context)
		local valz = {}
		valz["Row1"] = data.shared
		valz["Row3"] = data.buildclass
		valz["Row4"] = data.drop

		local DProperties = vgui.Create( "DProperties", frame )
		DProperties:SetSize( 480, 450 )
		DProperties:SetPos( 10, 10 )
		DProperties:Dock(FILL)
		
		function DProperties.CompileData()
			data.shared = valz["Row1"] 
			data.buildclass = valz["Row3"] 
			data.drop = valz["Row4"] 

			return data
		end
		
		function DProperties.UpdateData(data) -- This function will be overwritten if opened via context menu
			nzTools:SendData(data, "Part")
		end
		
		local Row3 = DProperties:CreateRow( "Part Settings", "Weapon this part is for")
		Row3:Setup( "Combo" )
		Row3:SetToolTip("The weapon this part will craft into in a Workbench.")

		-- Add all the entity classnames
		for k,v in pairs(weapons.GetList()) do
			if !v.NZTotalBlacklist then
				if v.Category and v.Category != "" then
					Row3:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
				else
					Row3:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
				end
			end
		end

		Row3:SetValue(valz["Row3"])
		Row3.DataChanged = function( _, val ) valz["Row3"] = val DProperties.UpdateData(DProperties.CompileData()) end
		return DProperties
	end,
	defaultdata = {
		buildclass = "",
		icon = "Default",
	}
})

