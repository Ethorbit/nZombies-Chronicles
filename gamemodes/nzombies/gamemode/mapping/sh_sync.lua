if SERVER then
	util.AddNetworkString( "nzMapping.SyncSettings" )

	local function receiveMapData(len, ply)
		-- Vulnerability fixed by Ethorbit
		if ply:IsNZAdmin() then
			local tbl = net.ReadTable()
			PrintTable(tbl)
			nzMapping:LoadMapSettings(tbl)
			-- nzMapping.Settings = tbl
		end
	end
	net.Receive( "nzMapping.SyncSettings", receiveMapData )

	function nzMapping:SendMapData(ply)
		if !self.GamemodeExtensions then self.GamemodeExtensions = {} end
		net.Start("nzMapping.SyncSettings")
			net.WriteTable(self.Settings)
		return IsValid(ply) and net.Send(ply) or net.Broadcast()
	end

	util.AddNetworkString("nzMapping.UpdatePresets")
	local function UpdatePresets(len, ply)
		if ply:IsNZAdmin() then
			local presets = file.Find("nz/presets/*", "DATA")
			local presetTbl = {}

			for _,v in pairs(presets) do
				if (isstring(v)) then
					table.insert(presetTbl, string.upper(string.sub(v, 1, #v - 4)))
				end
			end

			if (istable(presetTbl)) then
				net.Start("nzMapping.UpdatedBoxPresets")
				net.WriteTable(presetTbl)
				net.Send(ply)
			end
		end
	end

	util.AddNetworkString("nzMapping.WritePreset")
	net.Receive("nzMapping.WritePreset", function(len, ply)
		if ply:IsNZAdmin() then
			local filename = net.ReadString()
			local data = net.ReadTable()
			if (isstring(filename) and istable(data)) then
				file.CreateDir("nz/presets")

				local fileData = util.TableToJSON(data)
				timer.Simple(0.2, function()
					file.Write("nz/presets/" .. filename .. ".txt", fileData)
					if (file.Exists("nz/presets/" .. filename .. ".txt", "DATA")) then
						ply:ChatPrint("[nZ] Successfully saved nz/presets/" .. string.lower(filename) .. ".txt" .. "!")
						UpdatePresets(len, ply)
					else
						ply:ChatPrint("[nZ] Failed to save preset! Maybe the filename is invalid?")
					end
				end)
			else
				ply:ChatPrint("[nZ] Couldn't save preset! The data type(s) are invalid.")
			end
		end
	end)

	util.AddNetworkString("nzMapping.DeletePreset")
	net.Receive("nzMapping.DeletePreset", function(len, ply)
		if ply:IsNZAdmin() then
			local theFile = net.ReadString()
			if (isstring(theFile)) then
				file.Delete(theFile)

				if (!file.Exists(theFile, "DATA")) then
					ply:ChatPrint("[nZ] Successfully deleted " .. theFile .. "!")
					UpdatePresets(len, ply)
				else
					ply:ChatPrint("[nZ] Failed to delete the preset. Try again..")
				end
			end
		end
	end)

	util.AddNetworkString("nzMapping.UpdatedBoxPresets")
	net.Receive("nzMapping.UpdatePresets", UpdatePresets)

	util.AddNetworkString("nzMapping.GetPreset")
	util.AddNetworkString("nzMapping.ChangePreset")
	net.Receive("nzMapping.GetPreset", function(len, ply)
		if ply:IsNZAdmin() then
			local reqFile = net.ReadString()
			if (isstring(reqFile)) then
				local fileRead = file.Read(reqFile, "DATA")
				if (isstring(fileRead)) then
					local resTbl = util.JSONToTable(fileRead)
					timer.Simple(0.1, function()
						if (istable(resTbl)) then
							net.Start("nzMapping.ChangePreset")
							net.WriteTable(resTbl)
							net.Send(ply)

							ply:ChatPrint("[nZ] Using Mystery Box preset: " .. reqFile)
						else
							ply:ChatPrint("[nZ] Error loading the preset, try again..")
						end
					end)
				end
			end
		end
	end)
end

if CLIENT then
	local function cleanUpMap()
		game.CleanUpMap()
	end

	net.Receive("nzCleanUp", cleanUpMap )

	local function receiveMapData()
		if ispanel(nzQMenu.Data.MainFrame) then -- New config was loaded, refresh config menu
			nzQMenu.Data.MainFrame:Remove()
		end

		local oldeeurl = nzMapping.Settings.eeurl or ""
		nzMapping.Settings = net.ReadTable()

		if !EEAudioChannel or (oldeeurl != nzMapping.Settings.eeurl and nzMapping.Settings.eeurl) then
			EasterEggData.ParseSong()
		end

		-- Precache all random box weapons in the list
		if nzMapping.Settings.rboxweps then
			local model = ClientsideModel("models/hoff/props/teddy_bear/teddy_bear.mdl")
			for k,v in pairs(nzMapping.Settings.rboxweps) do
				local wep = weapons.Get(k)
				if wep and (wep.WM or wep.WorldModel) then
					util.PrecacheModel(wep.WM or wep.WorldModel)
					model:SetModel(wep.WM or wep.WorldModel)
				end
			end
			model:Remove()
		end
	end
	net.Receive( "nzMapping.SyncSettings", receiveMapData )

	function nzMapping:SendMapData( data )
		if data then
			net.Start("nzMapping.SyncSettings")
				net.WriteTable(data)
			net.SendToServer()
		end
	end

	function nzMapping:SendBoxPreset(filename, data)
		if (isstring(filename) and istable(data)) then
			net.Start("nzMapping.WritePreset")
			net.WriteString(filename)
			net.WriteTable(data)
			net.SendToServer()
		else
			chat.AddText("[nZ] Failed to send random box weapons to the server! Try again.")
		end
	end

	function nzMapping:DeleteBoxPreset(theFile)
		net.Start("nzMapping.DeletePreset")
		net.WriteString(theFile)
		net.SendToServer()
	end

	function nzMapping:UpdatePresets()
		net.Start("nzMapping.UpdatePresets")
		net.SendToServer()
	end

	net.Receive("nzMapping.UpdatedBoxPresets", function()
		local data = net.ReadTable()

		if (istable(data)) then
			if (!istable(nzMapping.rbox)) then
				nzMapping.rbox = {}
			end

			nzMapping.rbox.presets = data
		end
	end)

	function nzMapping:ChangeBoxPreset(presetFile)
		net.Start("nzMapping.GetPreset")
		net.WriteString(presetFile)
		net.SendToServer()
	end

	net.Receive("nzMapping.ChangePreset", function()
		local dataTbl = net.ReadTable()
		nzMapping.rbox.currentPreset = dataTbl
	end)
end
