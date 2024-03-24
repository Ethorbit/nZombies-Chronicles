nzTools:CreateTool("testzombie", {
	displayname = "Spawn Test Zombie",
	desc = "LMB: Create a test zombie, RMB: Remove test zombie",
	condition = function(wep, ply)
		return true
	end,

	PrimaryAttack = function(wep, ply, tr, data)
		data = data or {speed = 51, health = 100, type = "nz_zombie_walker"}
		PrintTable(data)
		local z = ents.Create(data.type)
		z:SetPos(tr.HitPos)
		z:SetHealth(100)
		z:SetMaxHealth(100)

		local oldinit = z.StatsInitialize
		z.StatsInitialize = function(self)
			oldinit(z)
			self:SetRunSpeed(data.speed)
		end
		z:Spawn()
		z:SetRunSpeed(data.speed)
		z:SetHealth(data.health)
		z:SetMaxHealth(data.health)

		undo.Create( "Test Zombie" )
			undo.SetPlayer( ply )
			undo.AddEntity( z )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end,

	SecondaryAttack = function(wep, ply, tr, data)
		if IsValid(tr.Entity) and string.find(tr.Entity:GetClass(), "nz_zombie") then
			tr.Entity:Remove()
		end
	end,
	Reload = function(wep, ply, tr, data)
		if IsValid(tr.Entity) and string.find(tr.Entity:GetClass(), "nz_zombie") then
			if tr.Entity:GetStop() then tr.Entity:SetStop(false) else tr.Entity:Stop() end
		end
	end,
	OnEquip = function(wep, ply, data)

	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Spawn Test Zombie",
	desc = "LMB: Create a test zombie, RMB: Remove test zombie",
	icon = "icon16/user_green.png",
	weight = 400,
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	interface = function(frame, data)

		local pnl = vgui.Create("DPanel", frame)
		pnl:Dock(FILL)

		local txt = vgui.Create("DLabel", pnl)
		txt:SetText("Zombie Speed")
		txt:SizeToContents()
		txt:SetTextColor(Color(0,0,0))
		txt:SetPos(220, 20)

		local slider = vgui.Create("DNumberScratch", pnl)
		slider:SetSize(100, 20)
		slider:SetPos(230, 40)
		slider:SetMin(0)

		local max = 500
		-- local custMax = nzMapping.Settings.maxzombiespeed
		-- if (isnumber(custMax) and custMax > 0) then
		-- 	max = custMax
		-- end
		slider:SetMax(max) 
		slider:SetValue(data.speed)

		local num = vgui.Create("DNumberWang", pnl)
		num:SetValue(data.speed)
		num:SetMinMax(0, max)
		num:SetPos(190, 40)

		local txt3 = vgui.Create("DLabel", pnl)
		txt3:SetText("Zombie Health")
		txt3:SizeToContents()
		txt3:SetTextColor(Color(0,0,0))
		txt3:SetPos(220, 90)

		local slider2 = vgui.Create("DNumberScratch", pnl)
		slider2:SetSize(100, 20)
		slider2:SetPos(230, 110)
		slider2:SetMin(0)
		slider2:SetMax(50000)
		slider2:SetValue(data.health)

		local num2 = vgui.Create("DNumberWang", pnl)
		num2:SetMinMax(75, 50000)
		num2:SetPos(190, 110)
		num2:SetValue(data.health)

		local txt2 = vgui.Create("DLabel", pnl)
		txt2:SetText("Zombie Type")
		txt2:SizeToContents()
		txt2:SetTextColor(Color(0,0,0))
		txt2:SetPos(220, 150)

		local drop = vgui.Create("DComboBox", pnl)
		drop:SetPos(150, 170)
		drop:SetSize(200, 20)

		for k,v in pairs(nzConfig.ValidEnemies) do
			drop:AddChoice(k, k, data.type == k and true or false)
		end
		for k,v in pairs(nzRound.BossData) do
			drop:AddChoice(v, v, data.type == v and true or false)
		end

		local function UpdateData() -- No need for context menu to intercept, can remain local
            -- Timers will help fix lag caused by sending too much data too fast /Ethorbit
            if timer.Exists("SendingZombieSpawnToolData") then 
                timer.Adjust("SendingZombieSpawnToolData", 0.1, 1, function() nzTools:SendData( data, "testzombie" ) end)
            else
                timer.Create("SendingZombieSpawnToolData", 0.1, 1, function() nzTools:SendData( data, "testzombie" ) end)
            end
		end

		slider.OnValueChanged = function(self, val)
			data.speed = val
			num:SetValue(val)
			UpdateData()
		end

		slider2.OnValueChanged = function(self, val)
			data.health = val
			num2:SetValue(val)
			UpdateData()
		end

		num.OnValueChanged = function(self, val)
			data.speed = val
			slider:SetValue(val)
			UpdateData()
		end

		num2.OnValueChanged = function(self, val)
			data.health = val
			slider2:SetValue(val)
			UpdateData()
		end

		drop.OnSelect = function(self, index, val, id)
			data.type = id
			UpdateData()
		end

		return pnl
	end,
	defaultdata = {
		speed = 51,
		health = 100,
		type = "nz_zombie_walker",
	}
})
