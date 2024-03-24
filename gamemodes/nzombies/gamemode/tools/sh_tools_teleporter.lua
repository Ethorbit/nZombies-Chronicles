nzTools:CreateTool("teleporter", {
	displayname = "Teleporter",
	desc = "LMB: Place Teleporter, RMB: Remove Teleporter",
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		local ent = tr.Entity
		local isTeleporter = IsValid(ent) and ent:GetClass() == "nz_teleporter"

		if !isTeleporter then
			data.pos = tr.HitPos
			data.angles = Angle(0,(tr.HitPos - ply:GetPos()):Angle()[2],0)
			data.ply = ply
		else
			data.pos = ent:GetPos()
			data.angles = ent:GetAngles()
			data.ply = nil
		end

		nzMapping:Teleporter(data)

		if isTeleporter then
			ent:Remove()
		end
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		if IsValid(tr.Entity) and tr.Entity:GetClass() == "nz_teleporter" then
			tr.Entity:Remove()
		end
	end,
	Reload = function(wep, ply, tr, data)
	end,
	OnEquip = function(wep, ply, data)


	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Teleporter",
	desc = "LMB: Place Teleporter, RMB: Remove Teleporter",
	icon = "icon16/connect.png",
	weight = 7,
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	interface = function(frame, data)
		local valz = {}
		valz["Row1"] = tostring(data.flag)
		valz["Row2"] = tostring(data.destination)
		valz["Door"] = tostring(data.door)
		valz["RequiresDoor"] = tobool(data.requiresdoor)
		valz["Row3"] = data.price
		valz["Row4"] = data.mdl
		valz["Row5"] = data.gif
		valz["TeleporterTime"] = data.teleportertime
		valz["Row6"] = data.cooldown
		valz["Row7"] = tobool(data.tpback)
		valz["Row8"] = data.tpbackdelay
		valz["MdlCollisions"] = tobool(data.mdlcollisions)
		valz["Visible"] = tobool(data.visible)
		valz["Useable"] = tobool(data.useable)
		valz["ActivatesTrap"] = tobool(data.activatestrap)
		valz["Trap"] = tostring(data.trap)
		
		local DProperties = vgui.Create( "DProperties", frame )
		DProperties:SetSize( 480, 450 )
		DProperties:SetPos( 10, 10 )
		
		function DProperties.CompileData()
			data.flag = valz["Row1"]
			data.destination = valz["Row2"]
			data.door = valz["Door"]
			data.requiresdoor = tobool(valz["RequiresDoor"])
			data.price = valz["Row3"]
			data.mdl = valz["Row4"]
			data.mdlcollisions = tobool(valz["MdlCollisions"])
			data.visible = tobool(valz["Visible"])
			data.useable = tobool(valz["Useable"])
			data.gif = valz["Row5"]
			data.teleportertime = tonumber(valz["TeleporterTime"])
			data.cooldown = valz["Row6"]
			data.tpback = tobool(valz["Row7"])
			data.tpbackdelay = tonumber(valz["Row8"])
			data.activatestrap = tobool(valz["ActivatesTrap"])
			data.trap = tostring(valz["Trap"])
				
			return data
		end
		
		function DProperties.UpdateData(data) -- This function will be overwritten if opened via context menu
			nzTools:SendData(data, "teleporter")
		end

		local Row1 = DProperties:CreateRow( "Teleporter", "Flag" )
		Row1:Setup("Generic")
		Row1:SetValue( valz["Row1"] )
		Row1.DataChanged = function( _, val ) valz["Row1"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row1:SetToolTip("The ID of this teleporter, other Teleporters will set their Destination to this.")

		local Row2 = DProperties:CreateRow( "Teleporter", "Destination" )
		Row2:Setup("Generic")
		Row2:SetValue( valz["Row2"] )
		Row2.DataChanged = function( _, val ) valz["Row2"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row2:SetToolTip("The destination Teleporter flag the player who uses this will be sent to.")

		local MdlCollisionsRow = DProperties:CreateRow("Model", "Collisions?")
		MdlCollisionsRow:Setup("Boolean")
		MdlCollisionsRow:SetValue(valz["MdlCollisions"])
		MdlCollisionsRow.DataChanged = function(_, val) valz["MdlCollisions"] = val DProperties.UpdateData(DProperties.CompileData()) end
		MdlCollisionsRow:SetToolTip("Whether or not this can collide with other entities.")

		local VisibleRow = DProperties:CreateRow( "Model", "Visible?" )
		VisibleRow:Setup( "Boolean" )
		VisibleRow:SetValue( valz["Visible"] )
		VisibleRow.DataChanged = function( _, val ) valz["Visible"] = val DProperties.UpdateData(DProperties.CompileData()) end
		VisibleRow:SetToolTip("Whether or not the Teleporter will show in-game")

		local RequiresDoorRow = DProperties:CreateRow( "Door", "Requires Door?" )
		RequiresDoorRow:Setup("Boolean")
		RequiresDoorRow:SetValue(valz["RequiresDoor"])
		RequiresDoorRow.DataChanged = function( _, val ) valz["RequiresDoor"] = val DProperties.UpdateData(DProperties.CompileData()) end
		RequiresDoorRow:SetToolTip("Whether or not a door is meant to be linked to this Teleporter.")

		local DoorFlagRow = DProperties:CreateRow( "Door", "Door" )
		DoorFlagRow:Setup("Generic")
		DoorFlagRow:SetValue(valz["Door"])
		DoorFlagRow.DataChanged = function( _, val ) valz["Door"] = val DProperties.UpdateData(DProperties.CompileData()) end
		DoorFlagRow:SetToolTip("If set to a real door flag, this Teleporter won't be useable until that door is opened.")

		local Row3 = DProperties:CreateRow( "Teleporter", "Price" )
		Row3:Setup("Integer")
		Row3:SetValue(valz["Row3"])
		Row3.DataChanged = function( _, val ) valz["Row3"] = val DProperties.UpdateData(DProperties.CompileData()) end

		local Row5 = DProperties:CreateRow( "Teleporter", "Overlay" )
		Row5:Setup("Combo")
		Row5:AddChoice("Der Riese", 1)
        Row5:AddChoice("Cold War", 2)
        Row5:AddChoice("Black Ops 3", 3)
        Row5:AddChoice("Shadows of Evil", 4)
		Row5:AddChoice("Origins (Black Ops 3)", 5)
		Row5.DataChanged = function( _, val ) valz["Row5"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row5:SetToolTip("The game-specific teleportation overlay players will see as they are being sent to the Destination.")
		Row5:SetSelected(valz["Row5"])

		local TeleporterTimeRow = DProperties:CreateRow("Teleporter", "Teleporter Time")
		TeleporterTimeRow:Setup("Integer")
		TeleporterTimeRow:SetValue(valz["TeleporterTime"])
		TeleporterTimeRow.DataChanged = function(_, val) valz["TeleporterTime"] = val DProperties.UpdateData(DProperties.CompileData()) end
		TeleporterTimeRow:SetToolTip("Time after activation before the players transition to their destination.")

		local Row6 = DProperties:CreateRow( "Teleporter", "Cooldown" )
		Row6:Setup( "Integer" )
		Row6:SetValue( valz["Row6"] )
		Row6.DataChanged = function( _, val ) valz["Row6"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row6:SetToolTip("Time after usage before this and any Teleporters linked to us can be used again.")

		local Row7 = DProperties:CreateRow( "Teleporter", "Teleport back?" )
		Row7:Setup( "Boolean" )
		Row7:SetValue( valz["Row7"] )
		Row7.DataChanged = function( _, val ) valz["Row7"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row7:SetToolTip("Whether or not the player who teleported for us will be automatically sent back.")

		local Row8 = DProperties:CreateRow( "Teleporter", "Time to Teleport Back" )
		Row8:Setup( "Integer" )
		Row8:SetValue( valz["Row8"] )
		Row8.DataChanged = function( _, val ) valz["Row8"] = val DProperties.UpdateData(DProperties.CompileData()) end
		Row8:SetToolTip("Time before the player is sent back (If Teleport Back is turned on)")

		local UseableRow = DProperties:CreateRow( "Teleporter", "Useable?" )
		UseableRow:Setup( "Boolean" )
		UseableRow:SetValue( valz["Useable"] )
		UseableRow.DataChanged = function( _, val ) valz["Useable"] = val DProperties.UpdateData(DProperties.CompileData()) end
		UseableRow:SetToolTip("Whether or not this Teleporter can be used directly")

		local ActivatesTrapRow = DProperties:CreateRow( "Trap", "Activates Trap?" )
		ActivatesTrapRow:Setup( "Boolean" )
		ActivatesTrapRow:SetValue( valz["ActivatesTrap"] )
		ActivatesTrapRow.DataChanged = function( _, val ) valz["ActivatesTrap"] = val DProperties.UpdateData(DProperties.CompileData()) end
		ActivatesTrapRow:SetToolTip("Whether or not this Teleporter activates a Trap while players wait to start teleporting")

		local TrapRow = DProperties:CreateRow( "Trap", "Trap" )
		TrapRow:Setup( "String" )
		TrapRow:SetValue( valz["Trap"] )
		TrapRow.DataChanged = function( _, val ) valz["Trap"] = val DProperties.UpdateData(DProperties.CompileData()) end
		TrapRow:SetToolTip("The Trap flag that will activate")

		return DProperties
	end,
	defaultdata = {
		flag = "0",
		destination = "1",
		door = "0",
		requiresdoor = false,
		price = 1500,
		gif = 1,
		teleportertime = 2.5,
		cooldown = 30,
		tpback = false,
		tpbackdelay = 20,
		mdl = 0,
		mdlcollisions = true,
		visible = true,
		useable = true,
		activatestrap = false,
		trap = "0"
	}
})