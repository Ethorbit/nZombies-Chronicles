nzTools:CreateTool("settings", {
	displayname = "Map Settings",
	desc = "Use the Tool Interface and press Submit to save changes",
	condition = function(wep, ply)
		return true
	end,

	PrimaryAttack = function(wep, ply, tr, data)
	end,
	SecondaryAttack = function(wep, ply, tr, data)
	end,
	Reload = function(wep, ply, tr, data)
	end,
	OnEquip = function(wep, ply, data)
	end,
	OnHolster = function(wep, ply, data)
	end
}, {
	displayname = "Map Settings",
	desc = "Use the Tool Interface and press Submit to save changes",
	icon = "icon16/cog.png",
	weight = 25,
	condition = function(wep, ply)
		return true
	end,
	interface = function(frame, data)
		local data = table.Copy(nzMapping.Settings)
		local valz = {}
		valz["Row1"] = data.startwep or "Select ..."
		valz["Row2"] = data.startpoints or 500
		valz["Row3"] = data.eeurl or ""
		valz["Row4"] = data.script or false
		valz["Row5"] = data.scriptinfo or ""
		valz["Row6"] = data.gamemodeentities or false
		valz["Row7"] = data.specialroundtype or "Hellhounds"
		valz["Row8"] = data.bosstype or "Panzer"
		valz["Zombsel"] = data.zombietype or "WaW"
		valz["Row17"] = data.zombietriggerkill == nil and false or data.zombietriggerkill
		valz["Row16"] = data.maxzombiespeed == nil and 200 or data.maxzombiespeed
		valz["Row9"] = data.startingspawns == nil and 35 or data.startingspawns
		valz["Row10"] = data.spawnperround == nil and 0 or data.spawnperround
		valz["Row11"] = data.maxspawns == nil and 35 or data.maxspawns
		valz["AutoMaxDogs"] = data.automaxdogs == nil and true or data.automaxdogs
		valz["EnableDogs"] = data.enabledogs == nil and true or data.enabledogs
		valz["Row18"] = data.maxdogs == nil and 24 or data.maxdogs
		valz["DogsPerPlayer"] = data.dogsperplayer == nil and 2 or data.dogsperplayer
		valz["DogAutoRunSpeed"] = data.dogautorunspeed == nil and true or data.dogautorunspeed
		valz["DogMaxRunSpeed"] = data.dogmaxrunspeed == nil and 200 or data.dogmaxrunspeed
		valz["DogSpawnSpeedMult"] = data.dogspawnspeedmult == nil and 1.4 or data.dogspawnspeedmult
        valz["MaxSpeedRound"] = data.maxspeedround == nil and 13 or data.maxspeedround
		valz["MaxHealthRound"] = data.maxhealthround == nil and 55 or data.maxhealthround
		valz["MixDogs"] = data.mixdogs == nil and true or data.mixdogs
		valz["EnableNovaCrawlers"] = data.enablenovacrawlers == nil and true or data.enablenovacrawlers
 		valz["NovaCrawlerBatch"] = data.novacrawlerbatch == nil and 5 or data.novacrawlerbatch
		valz["Row14"] = data.spawnsperplayer == nil and 0 or data.spawnsperplayer
		valz["Row15"] = data.zombieeyecolor == nil and Color(0, 255, 255, 255) or data.zombieeyecolor
		valz["Row12"] = data.zombiecollisions == nil and true or data.zombiecollisions
		valz["RBoxWeps"] = data.RBoxWeps or {}
		valz["ACRow1"] = data.ac == nil and true or data.ac
		valz["ACRow2"] = data.acwarn == nil and true or data.acwarn
		valz["ACRow3"] = data.acsavespot == nil and true or tobool(data.acsavespot)
		valz["ACRow4"] = data.actptime == nil and 5 or data.actptime
		valz["ACRow5"] = data.acpreventboost == nil and true or tobool(data.acpreventboost)
		valz["ACRow6"] = data.acpreventcjump == nil and true or tobool(data.acpreventcjump)
		valz["ModelPack"] = data.modelpack == nil and {} or data.modelpack
		valz["BoxPreset"] = data.boxpreset == nil and nil or data.boxpreset
		valz["NadeClass"] = data.nadeclass == nil or !nzSpecialWeapons.Nades[data.nadeclass] and "nz_grenade" or data.nadeclass
		valz["KnifeClass"] = data.knifeclass == nil or !nzSpecialWeapons.Knives[data.knifeclass] and "nz_quickknife_crowbar" or data.knifeclass
		valz["BuildablesDrop"] = data.buildablesdrop == nil and true or data.buildablesdrop
		valz["BuildablesShare"] = data.buildablesshare == nil and false or data.buildablesshare
		valz["BuildablesMaxAmount"] = data.buildablesmaxamount == nil and 100 or data.buildablesmaxamount
		valz["BuildablesForceRespawn"] = data.buildablesforcerespawn == nil and true or data.buildablesforcerespawn
		valz["BuildablesDisplayWepPart"] = data.buildablesdisplayweppart == nil and false or data.buildablesdisplayweppart
		valz["MapCategory"] = data.mapcategory == nil and "Other" or data.mapcategory

		if (ispanel(sndFilePanel)) then sndFilePanel:Remove() end
		if (ispanel(NZPreviewMDLSelectPnl)) then
			NZPreviewMDLSelectPnl:Remove()
			NZPreviewMDLSelectPnl = nil
		end

		-- More compact and less messy:
		for k,v in pairs(nzSounds.struct) do
			valz["SndRow" .. k] = data[v] or {}
		end

		-- Cache all Wunderfizz perks for saving/loading allowed Wunderfizz perks:
		local wunderfizzlist = {}
		for k,v in pairs(nzPerks:GetList()) do
			if k != "wunderfizz" and k != "pap" then
				wunderfizzlist[k] = {true, v}
			end
		end

		valz["Wunderfizz"] = data.wunderfizzperklist == nil and wunderfizzlist or data.wunderfizzperklist

		-- Cache all powerups for saving/loading allowed Powerups:
		local poweruplist = {}
		for k,v in pairs(nzPowerUps:GetList()) do
			poweruplist[k] = {true, v}
		end

		valz["PowerUps"] = data.poweruplist == nil and poweruplist or data.poweruplist

		local sheet = vgui.Create( "DPropertySheet", frame )
		sheet:SetSize( 480, 420 )
		sheet:SetPos( 10, 10 )

		-- Tab of tabs for keeping customization options clean
		local customPnl = vgui.Create("DPropertySheet", sheet)
		local customPnlH, customPnlW = sheet:GetSize()
		customPnl:SetSize(customPnlH, (customPnlW - 50))

		local DProperties = vgui.Create( "DProperties", DProperySheet )
		DProperties:SetSize( 280, 220 )
		DProperties:SetPos( 0, 0 )
		sheet:AddSheet( "Map Properties", DProperties, "icon16/cog.png", false, false, "Set a list of general settings.")

		local DProperties2 = vgui.Create( "DProperties", DProperySheet )
		DProperties2:SetSize( 280, 220 )
		DProperties2:SetPos( 0, 0 )

		local Row1 = DProperties:CreateRow( "Map Settings", "Starting Gun" )
		Row1:Setup( "Combo" )
		for k,v in pairs(weapons.GetList()) do
			if !v.NZTotalBlacklist then
				if v.Category and v.Category != "" then
					Row1:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
				else
					Row1:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
				end
			end
		end
		if data.startwep then
			local wep = weapons.Get(data.startwep)
			if !wep and weapons.Get(nzConfig.BaseStartingWeapons) and #weapons.Get(nzConfig.BaseStartingWeapons) >= 1 then wep = weapons.Get(nzConfig.BaseStartingWeapons[1]) end
			if wep != nil then
				if wep.Category and wep.Category != "" then
					Row1:AddChoice(wep.PrintName and wep.PrintName != "" and wep.Category.. " - "..wep.PrintName or wep.ClassName, wep.ClassName, false)
				else
					Row1:AddChoice(wep.PrintName and wep.PrintName != "" and wep.PrintName or wep.ClassName, wep.ClassName, false)
				end
			end
		end

		Row1.DataChanged = function( _, val ) valz["Row1"] = val end

		local KnifeRow = DProperties:CreateRow( "Map Settings", "Starting Knife" )
		local DefaultKnifeIndex = 0
		KnifeRow:Setup( "Combo" )
		for k,v in pairs(weapons.GetList()) do
			if !v.NZTotalBlacklist then
				if v.Category and v.Category != "" then
					local newIndex = KnifeRow:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
				else
					local newIndex = KnifeRow:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
				end

				if (v.ClassName == "nz_quickknife_crowbar") then
					DefaultKnifeIndex = newIndex
				end
			end
		end
		if valz["KnifeClass"] then
			local wep = weapons.Get(valz["KnifeClass"])
			if !wep and weapons.Get(nzConfig.BaseStartingWeapons) and #weapons.Get(nzConfig.BaseStartingWeapons) >= 1 then wep = weapons.Get(nzConfig.BaseStartingWeapons[1]) end
			if wep != nil then
				if wep.Category and wep.Category != "" then
					KnifeRow:AddChoice(wep.PrintName and wep.PrintName != "" and wep.Category.. " - "..wep.PrintName or wep.ClassName, wep.ClassName, false)
				else
					KnifeRow:AddChoice(wep.PrintName and wep.PrintName != "" and wep.PrintName or wep.ClassName, wep.ClassName, false)
				end
			end
		end

		KnifeRow.DataChanged = function( _, val )
			if (!nzSpecialWeapons.Knives[val]) then
				chat.AddText("[Knife Class] That's not a valid knife!")
			else
				valz["KnifeClass"] = val
			end
		end

		local NadeRow = DProperties:CreateRow( "Map Settings", "Starting Grenade" )
		local DefaultNadeIndex = 0
		NadeRow:Setup( "Combo" )
		for k,v in pairs(weapons.GetList()) do
			if !v.NZTotalBlacklist then
				if v.Category and v.Category != "" then
					local newIndex = NadeRow:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
				else
					local newIndex = NadeRow:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
				end

				if (v.ClassName == "nz_grenade") then
					DefaultNadeIndex = newIndex
				end
			end
		end
		if valz["NadeClass"] then
			local wep = weapons.Get(valz["NadeClass"])
			if !wep and weapons.Get(nzConfig.BaseStartingWeapons) and #weapons.Get(nzConfig.BaseStartingWeapons) >= 1 then wep = weapons.Get(nzConfig.BaseStartingWeapons[1]) end
			if wep != nil then
				if wep.Category and wep.Category != "" then
					NadeRow:AddChoice(wep.PrintName and wep.PrintName != "" and wep.Category.. " - "..wep.PrintName or wep.ClassName, wep.ClassName, false)
				else
					NadeRow:AddChoice(wep.PrintName and wep.PrintName != "" and wep.PrintName or wep.ClassName, wep.ClassName, false)
				end
			end
		end

		NadeRow.DataChanged = function( _, val )
			if (!nzSpecialWeapons.Nades[val]) then
				chat.AddText("[Grenade Class] That's not a valid grenade!")
			else
				valz["NadeClass"] = val
			end
		end

		local Row2 = DProperties:CreateRow( "Map Settings", "Starting Points" )
		Row2:Setup( "Integer" )
		Row2:SetValue( valz["Row2"] )
		Row2.DataChanged = function( _, val ) valz["Row2"] = val end

		if nzTools.Advanced then
			sheet:AddSheet( "Zombie Settings", DProperties2, "icon16/cog.png", false, false, "Configure the properties for zombies on the map.")
			local Row4 = DProperties:CreateRow( "Map Settings", "Includes Map Script?" )
			Row4:Setup( "Boolean" )
			Row4:SetValue( valz["Row4"] )
			Row4.DataChanged = function( _, val ) valz["Row4"] = val end
			Row4:SetTooltip("Loads a .lua file with the same name as the config .txt from /lua/nzmapscripts - for advanced developers.")

			local Row6 = DProperties:CreateRow( "Map Settings", "GM Extensions" )
			Row6:Setup("Boolean")
			Row6:SetValue( valz["Row6"] )
			Row6.DataChanged = function( _, val ) valz["Row6"] = val end
			Row6:SetTooltip("Sets whether the gamemode should spawn in map entities from other gamemodes, such as ZS.")

			local MapCategoryRow = DProperties:CreateRow("Metadata", "Map Category")
			MapCategoryRow:Setup("Generic")
			MapCategoryRow:SetValue(valz["MapCategory"])
			MapCategoryRow.DataChanged = function(_, val) valz["MapCategory"] = val end
			MapCategoryRow:SetToolTip("The category to place this map in on the Map Vote.")

			local Row3 = DProperties:CreateRow( "Metadata", "Easter Egg Song URL" )
			Row3:Setup( "Generic" )
			Row3:SetValue( valz["Row3"] )
			Row3.DataChanged = function( _, val ) valz["Row3"] = val end
			Row3:SetTooltip("Add a URL to play when all Easter Eggs have been found. (It has to be a video preview or download, anything else will NOT work. See: https://github.com/Ethorbit/nZombies-Chronicles/wiki/Easter-Egg-Tool)")

			local Row5 = DProperties:CreateRow( "Metadata", "Script Description" )
			Row5:Setup( "Generic" )
			Row5:SetValue( valz["Row5"] )
			Row5.DataChanged = function( _, val ) valz["Row5"] = val end
			Row5:SetTooltip("Sets the description displayed when attempting to load the script.")

			local Row12 = DProperties2:CreateRow("General", "Collisions?")
			Row12:Setup("Boolean")
			Row12:SetValue(valz["Row12"])
			Row12:SetTooltip("Whether or not players collide with zombies. (Zombies will go through eachother no matter what)")
			Row12.DataChanged = function( _, val ) valz["Row12"] = val end

			local Row17 = DProperties2:CreateRow("General", "Trigger Killing?")
			Row17:Setup( "Boolean" )
			Row17:SetValue( valz["Row17"] )
			Row17:SetTooltip("Instantly kills any zombie that touches a trigger_hurt")
			Row17.DataChanged = function( _, val ) valz["Row17"] = val end

			local Row7 = DProperties2:CreateRow("General", "Special Round")
			Row7:Setup( "Combo" )
			local found = false
			for k,v in pairs(nzRound.SpecialData) do
				if k == valz["Row7"] then
					Row7:AddChoice(k, k, true)
					found = true
				else
					Row7:AddChoice(k, k, false)
				end
			end
			Row7:AddChoice(" None", "None", !found)
			Row7.DataChanged = function( _, val ) valz["Row7"] = val end
			Row7:SetTooltip("Sets what type of special round will appear.")

			local Row8 = DProperties2:CreateRow("General", "Boss" )
			Row8:Setup( "Combo" )
			local found = false
			for k,v in pairs(nzRound.BossData) do
				if k == valz["Row8"] then
					Row8:AddChoice(k, k, true)
					found = true
				else
					Row8:AddChoice(k, k, false)
				end
			end
			Row8:AddChoice(" None", "None", !found)
			Row8.DataChanged = function( _, val ) valz["Row8"] = val end
			Row8:SetTooltip("Sets what type of boss will appear.")

			local ZombselRow = DProperties2:CreateRow("General", "Zombies")
			ZombselRow:Setup( "Combo" )
			local found = false
			for k,v in pairs(nzRound.ZombieData) do
				if k == valz["Zombsel"] then
					ZombselRow:AddChoice(k, k, true)
					found = true
				else
					ZombselRow:AddChoice(k, k, false)
				end
			end
			ZombselRow.DataChanged = function( _, val ) valz["Zombsel"] = val end
			ZombselRow:SetTooltip("Sets the zombies that will appear in your map.")

			local Row16 = DProperties2:CreateRow("All Zombies", "Max Run Speed")
			Row16:Setup( "Integer" )
			Row16:SetValue( valz["Row16"] )
			Row16:SetTooltip("The fastest speed a zombie is allowed to run (200 is the default, which is player walk speed)")
			Row16.DataChanged = function( _, val ) valz["Row16"] = val end

			local MaxSpeedRoundRow = DProperties2:CreateRow("All Zombies", "Max Speed Round")
			MaxSpeedRoundRow:Setup("Integer")
			MaxSpeedRoundRow:SetValue(valz["MaxSpeedRound"])
			MaxSpeedRoundRow:SetToolTip("The round at which all zombies should run at their max allowed speeds")
			MaxSpeedRoundRow.DataChanged = function(_, val) valz["MaxSpeedRound"] = val end

			local MaxHealthRoundRow = DProperties2:CreateRow("All Zombies", "Max Health Round")
			MaxHealthRoundRow:Setup("Integer")
			MaxHealthRoundRow:SetValue(valz["MaxHealthRound"])
			MaxHealthRoundRow:SetToolTip("The round at which zombies will stop gaining any more health")
			MaxHealthRoundRow.DataChanged = function(_, val) valz["MaxHealthRound"] = val end

			local Row9 = DProperties2:CreateRow("All Zombies", "Starting Spawns")
			Row9:Setup( "Integer" )
			Row9:SetValue( valz["Row9"] )
			Row9:SetTooltip("Allowed zombies alive at once, can be increased per round with Spawns Per Round")
			Row9.DataChanged = function( _, val ) valz["Row9"] = val end

			local Row10 = DProperties2:CreateRow("All Zombies", "Spawns Per Round")
			Row10:Setup( "Integer" )
			Row10:SetValue( valz["Row10"] )
			Row10:SetTooltip("Amount to increase spawns by each round (Cannot increase past Max Spawns)")
			Row10.DataChanged = function( _, val ) valz["Row10"] = val end

			local Row11 = DProperties2:CreateRow("All Zombies", "Max Zombie Spawns")
			Row11:Setup( "Integer" )
			Row11:SetValue( valz["Row11"] )
			Row11:SetTooltip("The max allowed zombies alive at any given time, it Spawns Per Round can NEVER go above this.")
			Row11.DataChanged = function( _, val ) valz["Row11"] = val end

			local Row14 = DProperties2:CreateRow("All Zombies", "Spawns Per Player")
			Row14:Setup( "Integer" )
			Row14:SetValue( valz["Row14"] )
			Row14:SetTooltip("Extra zombies allowed to spawn per player (Ignores first player and Max Spawns option)")
			Row14.DataChanged = function( _, val ) valz["Row14"] = val end

			local EnableDogsRow = DProperties2:CreateRow("Dogs", "Enable?")
			EnableDogsRow:Setup("Boolean")
			EnableDogsRow:SetValue(valz["EnableDogs"])
			EnableDogsRow:SetToolTip("If Dog or Special spawners are placed, dogs will spawn.")
			EnableDogsRow.DataChanged = function(_, val) valz["EnableDogs"] = val end

			local MixDogsRow = DProperties2:CreateRow("Dogs", "Mix Dogs with Zombies?")
			MixDogsRow:Setup("Boolean")
			MixDogsRow:SetValue(valz["MixDogs"])
			MixDogsRow:SetToolTip("Mixes the dog spawns in with normal zombies at high rounds (to add challenge).")
			MixDogsRow.DataChanged = function(_,val) valz["MixDogs"] = val end

			local Row18 = DProperties2:CreateRow("Dogs", "Auto Max Dogs")
			Row18:Setup( "Boolean" )
			Row18:SetValue( valz["AutoMaxDogs"] )
			Row18:SetTooltip("Automatically chooses the dog amount based on Black Ops 1 Dog Rounds.")
			Row18.DataChanged = function( _, val ) valz["AutoMaxDogs"] = val end

			
			local MaxDogsRow = DProperties2:CreateRow("Dogs", "Max Dogs")
			MaxDogsRow:Setup( "Integer" )
			MaxDogsRow:SetValue( valz["Row18"] )
			MaxDogsRow:SetTooltip("The max amount of dogs allowed to spawn at any time.")
			MaxDogsRow.DataChanged = function( _, val ) valz["Row18"] = val end

			local ExtraDogsRow = DProperties2:CreateRow("Dogs", "Extra Dogs Per Player")
			ExtraDogsRow:Setup( "Integer" )
			ExtraDogsRow:SetValue( valz["DogsPerPlayer"] )
			ExtraDogsRow:SetTooltip("The extra amount of dogs per player (Ignores first player).")
			ExtraDogsRow.DataChanged = function( _, val ) valz["DogsPerPlayer"] = val end

			local DogAutoRunSpeedRow = DProperties2:CreateRow("Dogs", "Auto Dog Run Speed")
			DogAutoRunSpeedRow:Setup( "Boolean" )
			DogAutoRunSpeedRow:SetValue( valz["DogAutoRunSpeed"] )
			DogAutoRunSpeedRow:SetTooltip("Automatically sets the dog run speed to match what's in COD.")
			DogAutoRunSpeedRow.DataChanged = function( _, val ) valz["DogAutoRunSpeed"] = val end

			local DogRunSpeedRow = DProperties2:CreateRow("Dogs", "Max Dog Run Speed")
			DogRunSpeedRow:Setup( "Integer" )
			DogRunSpeedRow:SetValue( valz["DogMaxRunSpeed"] )
			DogRunSpeedRow:SetTooltip("")
			DogRunSpeedRow.DataChanged = function( _, val ) valz["DogMaxRunSpeed"] = val end

			local DogSpawnSpeedMultRow = DProperties2:CreateRow("Dogs", "Dog Spawn Speed Multiplier")
			DogSpawnSpeedMultRow:Setup("Float", { min = 1.0, max = 5.0 })
			DogSpawnSpeedMultRow:SetValue(valz["DogSpawnSpeedMult"])
			DogSpawnSpeedMultRow:SetToolTip("The multiplier for dog spawn speed, 1 is how it is in Black Ops.")
			DogSpawnSpeedMultRow.DataChanged = function(_,val) valz["DogSpawnSpeedMult"] = val end
            
			local NovaCrawlerEnableRow = DProperties2:CreateRow("Nova Crawlers", "Enable?")
			NovaCrawlerEnableRow:Setup("Boolean")
			NovaCrawlerEnableRow:SetValue(valz["EnableNovaCrawlers"])
			NovaCrawlerEnableRow:SetToolTip("If Nova Crawler Spawners are placed, nova crawlers will spawn.")
			NovaCrawlerEnableRow.DataChanged = function(_, val) valz["EnableNovaCrawlers"] = val end

			local NovaCrawlerBatchRow = DProperties2:CreateRow("Nova Crawlers", "Batch Amount")
			NovaCrawlerBatchRow:Setup("Integer")
			NovaCrawlerBatchRow:SetValue(valz["NovaCrawlerBatch"])
			NovaCrawlerBatchRow:SetToolTip("The amount of Nova Crawlers to spawn in a 'batch' after every 20+ zombies are killed.")
			NovaCrawlerBatchRow.DataChanged = function(_, val) valz["NovaCrawlerBatch"] = val end
		end

		local function UpdateData() -- Will remain a local function here. There is no need for the context menu to intercept
			if !weapons.Get( valz["Row1"] ) then data.startwep = nil else data.startwep = valz["Row1"] end
			if !tonumber(valz["Row2"]) then data.startpoints = 500 else data.startpoints = tonumber(valz["Row2"]) end
			if !valz["Row3"] or valz["Row3"] == "" then data.eeurl = nil else data.eeurl = valz["Row3"] end
			if !valz["Row4"] then data.script = nil else data.script = valz["Row4"] end
			if !valz["Row5"] or valz["Row5"] == "" then data.scriptinfo = nil else data.scriptinfo = valz["Row5"] end
			if !valz["Row6"] or valz["Row6"] == "0" then data.gamemodeentities = nil else data.gamemodeentities = tobool(valz["Row6"]) end
			if !valz["Row7"] then data.specialroundtype = "Hellhounds" else data.specialroundtype = valz["Row7"] end
			if !valz["Row8"] then data.bosstype = "Panzer" else data.bosstype = valz["Row8"] end
			if !valz["Zombsel"] then data.zombietype = "WaW" else data.zombietype = valz["Zombsel"] end
			if !tonumber(valz["Row9"]) then data.startingspawns = 35 else data.startingspawns = tonumber(valz["Row9"]) end
			if !tonumber(valz["Row10"]) then data.spawnperround = 0 else data.spawnperround = tonumber(valz["Row10"]) end
			if !tonumber(valz["Row11"]) then data.maxspawns = 35 else data.maxspawns = tonumber(valz["Row11"]) end
			if !tonumber(valz["Row16"]) then data.maxzombiespeed = 200 else data.maxzombiespeed = tonumber(valz["Row16"]) end
			if valz["EnableDogs"] == nil then data.enabledogs = true else data.enabledogs = tobool(valz["EnableDogs"]) end
			if valz["Row17"] == nil then data.zombietriggerkill = false else data.zombietriggerkill = tobool(valz["Row17"]) end
			if valz["DogAutoRunSpeed"] == nil then data.dogautorunspeed = true else data.dogautorunspeed = tobool(valz["DogAutoRunSpeed"]) end
			if valz["MixDogs"] == nil then data.mixdogs = true else data.mixdogs = tobool(valz["MixDogs"]) end
			if valz["AutoMaxDogs"] == nil then data.automaxdogs = true else data.automaxdogs = tobool(valz["AutoMaxDogs"]) end
			if !tonumber(valz["Row18"]) then data.maxdogs = 24 else data.maxdogs = tonumber(valz["Row18"]) end
			if !tonumber(valz["DogsPerPlayer"]) then data.dogsperplayer = 2 else data.dogsperplayer = tonumber(valz["DogsPerPlayer"]) end
			if !tonumber(valz["DogMaxRunSpeed"]) then data.dogmaxrunspeed = 200 else data.dogmaxrunspeed = tonumber(valz["DogMaxRunSpeed"]) end
			if !tonumber(valz["DogSpawnSpeedMult"]) then data.dogspawnspeedmult = 1.4 else data.dogspawnspeedmult = tonumber(valz["DogSpawnSpeedMult"]) end
            if !tonumber(valz["MaxSpeedRound"]) then data.maxspeedround = 13 else data.maxspeedround = tonumber(valz["MaxSpeedRound"]) end
			if !tonumber(valz["MaxHealthRound"]) then data.maxhealthround = 55 else data.maxhealthround = tonumber(valz["MaxHealthRound"]) end
			if valz["EnableNovaCrawlers"] == nil then data.enablenovacrawlers = true else data.enablenovacrawlers = tobool(valz["EnableNovaCrawlers"]) end
			if !tonumber(valz["NovaCrawlerBatch"]) then data.novacrawlerbatch = 5 else data.novacrawlerbatch = tonumber(valz["NovaCrawlerBatch"]) end
			--if !tonumber(valz["Row13"]) then data.zombiesperplayer = 0 else data.zombiesperplayer = tonumber(valz["Row13"]) end
			if !tonumber(valz["Row14"]) then data.spawnsperplayer = 0 else data.spawnsperplayer = tonumber(valz["Row14"]) end
			if !istable(valz["Row15"]) then data.zombieeyecolor = Color(0, 255, 255, 255) else data.zombieeyecolor = valz["Row15"] end
			if valz["Row12"] == nil then data.zombiecollisions = nil else data.zombiecollisions = tobool(valz["Row12"]) end
			if !valz["RBoxWeps"] or table.Count(valz["RBoxWeps"]) < 1 then data.rboxweps = nil else data.rboxweps = valz["RBoxWeps"] end
			--if !valz["WMPerks"] or !valz["WMPerks"][1] then data.wunderfizzperklist = nil else data.wunderfizzperklist = valz["WMPerks"] end
			if valz["Wunderfizz"] == nil then data.wunderfizzperklist = wunderfizzlist else data.wunderfizzperklist = valz["Wunderfizz"] end
			if valz["PowerUps"] == nil then data.poweruplist = poweruplist else data.poweruplist = valz["PowerUps"] end
			if valz["ACRow1"] == nil then data.ac = true else data.ac = tobool(valz["ACRow1"]) end
			if valz["ACRow2"] == nil then data.acwarn = nil else data.acwarn = tobool(valz["ACRow2"]) end
			if valz["ACRow3"] == nil then data.acsavespot = nil else data.acsavespot = tobool(valz["ACRow3"]) end
			if valz["ACRow4"] == nil then data.actptime = 5 else data.actptime = valz["ACRow4"] end
			if valz["ACRow5"] == nil then data.acpreventboost = true else data.acpreventboost = tobool(valz["ACRow5"]) end
			if valz["ACRow6"] == nil then data.acpreventcjump = true else data.acpreventcjump = tobool(valz["ACRow6"]) end
			if valz["NadeClass"] == nil or !nzSpecialWeapons.Nades[valz["NadeClass"]] then data.nadeclass = "nz_grenade" else data.nadeclass = tostring(valz["NadeClass"]) end
			if valz["KnifeClass"] == nil or !nzSpecialWeapons.Knives[valz["KnifeClass"]] then data.knifeclass = "nz_quickknife_crowbar" else data.knifeclass = tostring(valz["KnifeClass"]) end
			if valz["BuildablesDrop"] == nil then data.buildablesdrop = true else data.buildablesdrop = tobool(valz["BuildablesDrop"]) end
			if valz["BuildablesShare"] == nil then data.buildablesshare = false else data.buildablesshare = tobool(valz["BuildablesShare"]) end
			if !tonumber(valz["BuildablesMaxAmount"]) then data.buildablesmaxamount = 100 else data.buildablesmaxamount = tonumber(valz["BuildablesMaxAmount"]) end
			if valz["BuildablesForceRespawn"] == nil then data.buildablesforcerespawn = true else data.buildablesforcerespawn = tobool(valz["BuildablesForceRespawn"]) end
			if valz["BuildablesDisplayWepPart"] == nil then data.buildablesdisplayweppart = false else data.buildablesdisplayweppart = tobool(valz["BuildablesDisplayWepPart"]) end
			if valz["MapCategory"] == nil then data.mapcategory = "Other" else data.mapcategory = tostring(valz["MapCategory"]) end
			data.boxpreset = valz["BoxPreset"]

			-- if (data.boxpreset and nzMapping.rbox and nzMapping.rbox.currentPreset) then
			-- 	data.rboxweps = nzMapping.rbox.currentPreset
			-- end

			if (istable(valz["ModelPack"])) then
				data.modelpack = {}

				for _,v in pairs(valz["ModelPack"]) do
					local pnl = v["Panel"]
					if (ispanel(pnl)) then
						local val = v["Value"]
						local path = v["Path"]
						local bgroups = v["Bodygroups"]["Values"]

						if (!isnumber(val)) then val = 0 end
						if (isstring(path)) then
							data.modelpack[#data.modelpack + 1]	= {
								["Path"] = path,
								["Skin"] = val,
								["Bodygroups"] = bgroups
							}
						end
					end
				end
			end

			PrintTable(data)

			for k,v in pairs(nzSounds.struct) do
				if (valz["SndRow" .. k] == nil) then
					data[v] = {}
				else
					data[v] = valz["SndRow" .. k]
				end
			end

			nzMapping:SendMapData( data )
		end

		if (MapSDermaButton != nil) then
			MapSDermaButton:Remove()
		end

		MapSDermaButton = vgui.Create( "DButton", frame )
		MapSDermaButton:SetText( "Submit" )
		--MapSDermaButton:Dock(BOTTOM)
		MapSDermaButton:SetPos( 10, 430 )

		MapSDermaButton:SetSize( 480, 30 )
		MapSDermaButton.DoClick = UpdateData

		local function AddEyeStuff()
			local eyePanel = vgui.Create("DPanel", sheet)
			customPnl:AddSheet("Eye Color", eyePanel, "icon16/palette.png", false, false, "Set the eye glow color the zombies have.")
			eyePanel:DockPadding(5, 5, 5, 5)
			local wrapper = vgui.Create("DPanel", eyePanel)
			wrapper:SetSize(400, 600)
			wrapper:SetPos(40, 60)

			local colorChoose = vgui.Create("DColorMixer", wrapper)
			colorChoose:SetColor(valz["Row15"])
			colorChoose:SetPalette(false)
			colorChoose:SetAlphaBar(false)
			colorChoose:Dock(TOP)
			colorChoose:SetSize(150, 220)

			local presets = vgui.Create("DComboBox", wrapper)
			presets:SetSize(335, 20)
			presets:SetPos(5, 225)
			--presets:Dock(BOTTOM)
			presets:AddChoice("Richtofen")
			presets:AddChoice("Samantha")
			presets:AddChoice("Avogadro")
			presets:AddChoice("Warden")
			presets.OnSelect = function(self, index, value)
				if (value == "Richtofen") then
					colorChoose:SetColor(Color(0, 255, 255))
				elseif (value == "Samantha") then
					colorChoose:SetColor(Color(255, 145, 0))
				elseif (value == "Avogadro") then
					colorChoose:SetColor(Color(255, 255, 255))
				elseif (value == "Warden") then
					colorChoose:SetColor(Color(255, 0, 0))
				end

				colorChoose:ValueChanged(nil)
			end

			colorChoose.ValueChanged = function(col)
				valz["Row15"] = colorChoose:GetColor()
			end
		end

		local acPanel = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Anti-Cheat", acPanel, "icon16/script_gear.png", false, false, "Automatically teleport players from cheating spots.")
		local acProps = vgui.Create("DProperties", acPanel)
		local acheight, acwidth = sheet:GetSize()
		acProps:SetSize(acwidth, acwidth - 50)

		if (!nzTools.Advanced) then
			AddEyeStuff()
		end

		-- local DermaButton3 = vgui.Create( "DButton", acPanel )
		-- DermaButton3:SetText( "Submit" )
		-- DermaButton3:SetPos( 0, 185 )
		-- DermaButton3:SetSize( 260, 30 )
		-- DermaButton3.DoClick = UpdateData

		--local ACRow1 = acProps:CreateRow("Anti-Cheat Settings", "Enabled?")
		--ACRow1:Setup("Boolean")
		--ACRow1:SetValue(valz["ACRow1"])
		--ACRow1.DataChanged = function( _, val ) valz["ACRow1"] = val end

		if nzTools.Advanced then
			local ACRow2 = acProps:CreateRow("Anti-Cheat Settings", "Warn players?")
			ACRow2:Setup("Boolean")
			ACRow2:SetValue(valz["ACRow2"])
			ACRow2:SetTooltip("Shows \"Return to map!\" with a countdown on player's screens")
			ACRow2.DataChanged = function(_, val) valz["ACRow2"] = val end

			local ACRow3 = acProps:CreateRow("Anti-Cheat Settings", "Save Last Spots?")
			ACRow3:Setup("Boolean")
			ACRow3:SetValue(valz["ACRow3"])
			ACRow3:SetTooltip("Remembers the last spot a player was at before they were detected. (Uses more performance)")
			ACRow3.DataChanged = function(_, val) valz["ACRow3"] = val end

			local ACRow5 = acProps:CreateRow("Anti-Cheat Settings", "Prevent boosting?")
			ACRow5:Setup("Boolean")
			ACRow5:SetValue(valz["ACRow5"])
			ACRow5:SetTooltip("Cancels out vertical velocity when players boost up faster than jump speed")
			ACRow5.DataChanged = function(_, val) valz["ACRow5"] = val end

			--local ACRow6 = acProps:CreateRow("Anti-Cheat Settings", "No Crouch Jump?")
			--ACRow6:Setup("Boolean")
			--ACRow6:SetValue(valz["ACRow6"])
			--ACRow6:SetTooltip("Turns crouch jumps into normal jumps to make climbing on stuff harder")
			--ACRow6.DataChanged = function(_, val) valz["ACRow6"] = val end

			local ACRow4 = acProps:CreateRow("Anti-Cheat Settings", "Seconds for TP")
			ACRow4:Setup("Integer")
			ACRow4:SetValue(valz["ACRow4"])
			ACRow4:SetTooltip("Amount of seconds before a cheating player is teleported.")
			ACRow4.DataChanged = function(_, val) valz["ACRow4"] = val end

			local weplist = {}
			local numweplist = 0

			local rboxpanel = vgui.Create("DPanel", sheet)
			sheet:AddSheet( "Random Box Weapons", rboxpanel, "icon16/box.png", false, false, "Set which weapons appear in the Random Box.")
			rboxpanel.Paint = function() return end
			rboxpanel:SetPos(60, 35)

			local rbweplist = vgui.Create("DScrollPanel", rboxpanel)
			rbweplist:SetPos(0, 0)
			rbweplist:SetSize(365, 350)
			rbweplist:SetPaintBackground(true)
			rbweplist:SetBackgroundColor( Color(200, 200, 200) )

			-- warningFrame = vgui.Create("DFrame")
			-- warningFrame:SetSize(300, 200)
			-- warningFrame:Center()
			-- warningFrame:SetTitle("Box Preset Warning")
			-- warningFrame:MakePopup()

			local function InsertWeaponToList(name, class, weight, tooltip)
				weight = weight or 10
				if IsValid(weplist[class]) then return end
				weplist[class] = vgui.Create("DPanel", rbweplist)
				weplist[class]:SetSize(365, 16)
				weplist[class]:SetPos(0, numweplist*16)
				valz["RBoxWeps"][class] = weight

				local dname = vgui.Create("DLabel", weplist[class])
				dname:SetText(name)
				dname:SetTextColor(Color(50, 50, 50))
				dname:SetPos(5, 0)
				dname:SetSize(250, 16)

				local dhover = vgui.Create("DPanel", weplist[class])
				dhover.Paint = function() end
				dhover:SetText("")
				dhover:SetSize(365, 16)
				dhover:SetPos(0,0)
				if tooltip then
					dhover:SetTooltip(tooltip)
				end

				local dweight = vgui.Create("DNumberWang", weplist[class])
				dweight:SetPos(295, 1)
				dweight:SetSize(40, 14)
				dweight:SetTooltip("The chance of this weapon appearing in the box")
				dweight:SetMinMax( 1, 100 )
				dweight:SetValue(valz["RBoxWeps"][class])
				function dweight:OnValueChanged(val)
					valz["RBoxWeps"][class] = val
				end

				local ddelete = vgui.Create("DImageButton", weplist[class])
				ddelete:SetImage("icon16/delete.png")
				ddelete:SetPos(335, 0)
				ddelete:SetSize(16, 16)
				ddelete.DoClick = function()
					valz["RBoxWeps"][class] = nil
					weplist[class]:Remove()
					weplist[class] = nil
					local num = 0
					for k,v in pairs(weplist) do
						v:SetPos(0, num*16)
						num = num + 1
					end
					numweplist = numweplist - 1
				end

				numweplist = numweplist + 1
			end

			if nzMapping.Settings.rboxweps then
				for k,v in pairs(nzMapping.Settings.rboxweps) do
					local wep = weapons.Get(k)
					if wep then
						if wep.Category and wep.Category != "" then
							InsertWeaponToList(wep.PrintName != "" and wep.PrintName or k, k, v or 10, k.." ["..wep.Category.."]")
						else
							InsertWeaponToList(wep.PrintName != "" and wep.PrintName or k, k, v or 10, k.." [No Category]")
						end
					end
				end
			else
				for k,v in pairs(weapons.GetList()) do
					-- By default, add all weapons that have print names unless they are blacklisted
					if v.PrintName and v.PrintName != "" and !nzConfig.WeaponBlackList[v.ClassName] and v.PrintName != "Scripted Weapon" and !v.NZPreventBox and !v.NZTotalBlacklist then
						if v.Category and v.Category != "" then
							InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." ["..v.Category.."]")
						else
							InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." [No Category]")
						end
					end
					-- The rest are still available in the dropdown
				end
			end

			local wepentry = vgui.Create( "DComboBox", rboxpanel )
			wepentry:SetPos( 0, 355 )
			wepentry:SetSize( 146, 20 )
			wepentry:SetValue( "Weapon ..." )
			for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
				if !v.NZTotalBlacklist and !v.NZPreventBox then
					if v.Category and v.Category != "" then
						wepentry:AddChoice(v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName, v.ClassName, false)
					else
						wepentry:AddChoice(v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, false)
					end
				end
			end
			wepentry.OnSelect = function( panel, index, value )
			end

			local wepadd = vgui.Create( "DButton", rboxpanel )
			wepadd:SetText( "Add" )
			wepadd:SetPos( 150, 355 )
			wepadd:SetSize( 53, 20 )
			wepadd.DoClick = function()
				local v = weapons.Get(wepentry:GetOptionData(wepentry:GetSelectedID()))
				if v then
					if v.Category and v.Category != "" then
						InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." ["..v.Category.."]")
					else
						InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." [No Category]")
					end
				end
				wepentry:SetValue( "Weapon..." )
			end

			local wepmore = vgui.Create( "DButton", rboxpanel )
			wepmore:SetText( "More ..." )
			wepmore:SetPos( 207, 355 )
			wepmore:SetSize( 53, 20 )
			wepmore.DoClick = function()
				local morepnl = vgui.Create("DFrame")
				morepnl:SetSize(300, 170)
				morepnl:SetTitle("More weapon options ...")
				morepnl:Center()
				morepnl:SetDraggable(true)
				morepnl:ShowCloseButton(true)
				morepnl:MakePopup()

				local morecat = vgui.Create("DComboBox", morepnl)
				morecat:SetSize(150, 20)
				morecat:SetPos(10, 30)
				local cattbl = {}
				for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
					if v.Category and v.Category != "" then
						if !cattbl[v.Category] then
							morecat:AddChoice(v.Category, v.Category, false)
							cattbl[v.Category] = true
						end
					end
				end
				morecat:AddChoice(" Category ...", nil, true)

				local morecatadd = vgui.Create("DButton", morepnl)
				morecatadd:SetText( "Add all" )
				morecatadd:SetPos( 165, 30 )
				morecatadd:SetSize( 60, 20 )
				morecatadd.DoClick = function()
					local cat = morecat:GetOptionData(morecat:GetSelectedID())
					if cat and cat != "" then
						for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
							if  v.Category and v.Category == cat and !nzConfig.WeaponBlackList[v.ClassName] and !v.NZPreventBox and !v.NZTotalBlacklist then
								InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." ["..v.Category.."]")
							end
						end
					end
				end

				local morecatdel = vgui.Create("DButton", morepnl)
				morecatdel:SetText( "Remove all" )
				morecatdel:SetPos( 230, 30 )
				morecatdel:SetSize( 60, 20 )
				morecatdel.DoClick = function()
					local cat = morecat:GetOptionData(morecat:GetSelectedID())
					if cat and cat != "" then
						for k,v in pairs(weplist) do
							local wep = weapons.Get(k)
							if wep then
								if wep.Category and wep.Category == cat then
									valz["RBoxWeps"][k] = nil
									weplist[k]:Remove()
									weplist[k] = nil
									local num = 0
									for k,v in pairs(weplist) do
										v:SetPos(0, num*16)
										num = num + 1
									end
									numweplist = numweplist - 1
								end
							end
						end
					end
				end

				local moreprefix = vgui.Create("DComboBox", morepnl)
				moreprefix:SetSize(150, 20)
				moreprefix:SetPos(10, 60)
				local prefixtbl = {}
				for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
					local prefix = string.sub(v.ClassName, 0, string.find(v.ClassName, "_"))
					if prefix and !prefixtbl[prefix] then
						moreprefix:AddChoice(prefix, prefix, false)
						prefixtbl[prefix] = true
					end
				end
				moreprefix:AddChoice(" Prefix ...", nil, true)

				local moreprefixadd = vgui.Create("DButton", morepnl)
				moreprefixadd:SetText( "Add all" )
				moreprefixadd:SetPos( 165, 60 )
				moreprefixadd:SetSize( 60, 20 )
				moreprefixadd.DoClick = function()
					local prefix = moreprefix:GetOptionData(moreprefix:GetSelectedID())
					if prefix and prefix != "" then
						for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
							local wepprefix = string.sub(v.ClassName, 0, string.find(v.ClassName, "_"))
							if wepprefix and wepprefix == prefix and !nzConfig.WeaponBlackList[v.ClassName] and !v.NZPreventBox and !v.NZTotalBlacklist then
								if v.Category and v.Category != "" then
									InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." ["..v.Category.."]")
								else
									InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." [No Category]")
								end
							end
						end
					end
				end

				local moreprefixdel = vgui.Create("DButton", morepnl)
				moreprefixdel:SetText( "Remove all" )
				moreprefixdel:SetPos( 230, 60 )
				moreprefixdel:SetSize( 60, 20 )
				moreprefixdel.DoClick = function()
					local prefix = moreprefix:GetOptionData(moreprefix:GetSelectedID())
					if prefix and prefix != "" then
						for k,v in pairs(weplist) do
							local wepprefix = string.sub(k, 0, string.find(k, "_"))
							if wepprefix and wepprefix == prefix then
								valz["RBoxWeps"][k] = nil
								weplist[k]:Remove()
								weplist[k] = nil
								local num = 0
								for k,v in pairs(weplist) do
									v:SetPos(0, num*16)
									num = num + 1
								end
								numweplist = numweplist - 1
							end
						end
					end
				end

				local removeall = vgui.Create("DButton", morepnl)
				removeall:SetText( "Remove all" )
				removeall:SetPos( 10, 100 )
				removeall:SetSize( 140, 25 )
				removeall.DoClick = function()
					for k,v in pairs(weplist) do
						valz["RBoxWeps"][k] = nil
						weplist[k]:Remove()
						weplist[k] = nil
						numweplist = 0
					end
				end

				local addall = vgui.Create("DButton", morepnl)
				addall:SetText( "Add all" )
				addall:SetPos( 150, 100 )
				addall:SetSize( 140, 25 )
				addall.DoClick = function()
					for k,v in pairs(weplist) do
						valz["RBoxWeps"][k] = nil
						weplist[k]:Remove()
						weplist[k] = nil
						numweplist = 0
					end
					for k,v in SortedPairsByMemberValue(weapons.GetList(), "PrintName") do
						-- By default, add all weapons that have print names unless they are blacklisted
						if v.PrintName and v.PrintName != "" and !nzConfig.WeaponBlackList[v.ClassName] and v.PrintName != "Scripted Weapon" and !v.NZPreventBox and !v.NZTotalBlacklist then
							if v.Category and v.Category != "" then
								InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." ["..v.Category.."]")
							else
								InsertWeaponToList(v.PrintName != "" and v.PrintName or v.ClassName, v.ClassName, 10, v.ClassName.." [No Category]")
							end
						end
						-- The same reset as when no random box list exists on server
					end
				end

				local reload = vgui.Create("DButton", morepnl)
				reload:SetText( "Reload from server" )
				reload:SetPos( 10, 130 )
				reload:SetSize( 280, 25 )
				reload.DoClick = function()
					-- Remove all and insert from random box list
					for k,v in pairs(weplist) do
						valz["RBoxWeps"][k] = nil
						weplist[k]:Remove()
						weplist[k] = nil
						numweplist = 0
					end
					if nzMapping.Settings.rboxweps then
						for k,v in pairs(nzMapping.Settings.rboxweps) do
							local wep = weapons.Get(v)
							if wep then
								if wep.Category and wep.Category != "" then
									InsertWeaponToList(wep.PrintName != "" and wep.PrintName or v, v, 10, v.." ["..v.Category.."]")
								else
									InsertWeaponToList(wep.PrintName != "" and wep.PrintName or v, v, 10, v.." [No Category]")
								end
							end
						end
					end
				end
			end

			local warningPanel = nil
			local function ResetRboxStyling()
				if (ispanel(warningPanel)) then
					warningPanel:Remove()
					warningPanel = nil
				end
			end

			local function ShowPresetWarning()
				if (!ispanel(rboxpanel)) then return end
				if (ispanel(warningPanel)) then
					warningPanel:Remove()
					warningPanel = nil
				end

				warningPanel = vgui.Create("DPanel", rboxpanel)
				warningPanel:SetBackgroundColor(Color(100, 2, 2))
				warningPanel:SetPos(0, 0)
				warningPanel:SetSize(365, 160)

				local warningTxt = vgui.Create("DLabel", warningPanel)
				warningTxt:SetMultiline(true)
				warningTxt:SetText("WARNING: Any new changes will require saving:\n" .. valz["BoxPreset"] .. "\nor they'll be lost!\n\nYou can do this by clicking the folder button\non the bottom right.\n\nYou can also clear the preset there if you prefer to just\nedit this map's weapons.")
				warningTxt:SetPos(50, 10)
				warningTxt:SetSize(365, 130)

				local removeWarning = vgui.Create("DImageButton", warningPanel)
				removeWarning:SetImage("icon16/cancel.png")
				removeWarning:SetPos(365 - 20, 0)
				removeWarning:SetSize(20, 20)
				removeWarning.DoClick = function()
					warningPanel:Remove()
					warningPanel = nil
				end
			end

			local function LoadPresetWeps(theFile)
				if (nzMapping.rbox == nil) then
					nzMapping.rbox = {}
				end

				if (isstring(theFile)) then
					valz["BoxPreset"] = theFile
					nzMapping.rbox.currentPreset = nil
					nzMapping:ChangeBoxPreset(theFile)

					timer.Create("LoadingNewBoxPreset", 0.1, 0, function()
						if (nzMapping.rbox.currentPreset != nil and istable(nzMapping.rbox.currentPreset)) then
							ShowPresetWarning()

							for k,v in pairs(weplist) do
								valz["RBoxWeps"][k] = nil
								weplist[k]:Remove()
								weplist[k] = nil
								numweplist = 0
							end

							for k,v in pairs(nzMapping.rbox.currentPreset) do
								local wep = weapons.Get(k)
								if wep then
									if wep.Category and wep.Category != "" then
										InsertWeaponToList(wep.PrintName != "" and wep.PrintName or k, k, v or 10, k.." ["..wep.Category.."]")
									else
										InsertWeaponToList(wep.PrintName != "" and wep.PrintName or k, k, v or 10, k.." [No Category]")
									end
								end
							end

							timer.Destroy("LoadingNewBoxPreset")
						end
					end)
				end
			end

			LoadPresetWeps(valz["BoxPreset"])
			-- sheet.OnActiveTabChanged = function(old, new)
			-- 	if (new:GetTitle() == "Random Box Weapons") then
			-- 		LoadPresetWeps(valz["BoxPreset"])
			-- 	end
			-- end


			local openedPreset = nil
			local boxPresets = vgui.Create("DImageButton", rboxpanel)
			boxPresets:SetSize(25, 25)
			boxPresets:SetImage("icon16/folder_edit.png")
			boxPresets:SetPos(265, 351)
			boxPresets.DoClick = function()
				if (ispanel(openedPreset)) then
					openedPreset:Remove()
					openedPreset = nil
				end

				local presetMenu = vgui.Create("DPanel", sheet)
				presetMenu:SetSize(300, 280)
				presetMenu:Center()
				presetMenu:SetBackgroundColor(Color(200, 200, 200))
				local presetMenuX, presetMenuY = presetMenu:GetSize()

				local closeBtn = vgui.Create("DImageButton", presetMenu)
				closeBtn:SetSize(20, 20)
				closeBtn:SetPos(presetMenuX - 20, 0)
				closeBtn:SetImage("icon16/cancel.png")
				closeBtn.DoClick = function()
					openedPreset:Remove()
					openedPreset = nil
				end

				local topcontrols = vgui.Create("DPanel", presetMenu)
				topcontrols:SetSize(250, 250)
				topcontrols:SetPos(20, 10)

				local controlsBottom = vgui.Create("DPanel", topcontrols)
				controlsBottom:SetSize(50, 20)
				controlsBottom:Dock(BOTTOM)
				controlsBottom:SetBackgroundColor(Color(200, 200, 200))

				local filename = ""
				local saveBtn = vgui.Create("DImageButton", controlsBottom)
				saveBtn:SetImage("icon16/page_save.png")
				saveBtn:Dock(RIGHT)
				saveBtn:SetPos(20, 0)
				saveBtn:SetSize(20, 20)
				saveBtn.DoClick = function()
					nzMapping:SendBoxPreset(filename, valz["RBoxWeps"])
				end

				local saveAs = vgui.Create("DTextEntry", controlsBottom)
				saveAs:Dock(RIGHT)
				saveAs:SetSize(230, 20)
				saveAs:SetMultiline(false)
				saveAs:SetPlaceholderText("Small Maps")
				saveAs:SetUpdateOnType(true)

				local replaceStrs = {
					"<",
					">",
					":",
					"\"",
					"/",
					"\\",
					"|",
					"?",
					"*"
				}

				saveAs.OnChange = function()
					local value = saveAs:GetText()
					for _,v in pairs(replaceStrs) do
						if (string.find(value, v)) then
							saveAs:SetText(string.Replace(value, v, ""))
						end
					end

					filename = saveAs:GetText()
				end

				local presetList = vgui.Create("DListView", topcontrols)
				presetList:Dock(FILL)
				presetList:SetMultiSelect(false)
				presetList:AddColumn("Box Presets")
				presetList:SetSortable(false)

				local function LoadPresetList(presets)
					presetList:Clear()

					if (istable(presets)) then
						for _,v in pairs(presets) do
							presetList:AddLine(v)
						end
					end
				end

				presetList.Think = function()
					if (nzMapping.rbox and nzMapping.rbox.presets and #nzMapping.rbox.presets != #presetList:GetLines()) then
						LoadPresetList(nzMapping.rbox.presets)
					end
				end

				local function GetSelectedFile()
					local lineNum = presetList:GetSelectedLine()
					if (!isnumber(lineNum)) then return "" end

					local selected = presetList:GetLine(lineNum)
					if (ispanel(selected)) then
						local selectedText = selected:GetColumnText(1)
						if (isstring(selectedText)) then
							return "nz/presets/" .. string.lower(selectedText) .. ".txt"
						end
					end

					return ""
				end

				local confirmation = nil
				presetList.OnRowRightClick = function(lineID, line)
					local menu = vgui.Create("DMenu", presetList)
					menu:AddOption("Delete")
					menu.OptionSelected = function(menu, option)
						if (option:GetText() == "Delete") then
							if (ispanel(confirmation)) then
								confirmation:Remove()
								confirmation = nil
							end

							confirmation = vgui.Create("DFrame")
							confirmation:SetSize(200, 80)
							confirmation:SetDraggable(false)
							confirmation:SetTitle("Delete preset?")
							confirmation:Center()
							confirmation:MakePopup()

							local yesBtn = vgui.Create("DButton", confirmation)
							yesBtn:SetText("Yes")
							yesBtn:Dock(LEFT)
							yesBtn.DoClick = function()
								nzMapping:DeleteBoxPreset(GetSelectedFile())
								nzMapping:UpdatePresets()

								if (GetSelectedFile() == valz["BoxPreset"]) then
									valz["BoxPreset"] = nil
									nzMapping.rbox.currentPreset = nil
									chat.AddText("[nZ] Map no longer uses a preset.")
									ResetRboxStyling()
								end

								confirmation:Remove()
							end

							yesBtn:SetSize(90, 80)

							local noBtn = vgui.Create("DButton", confirmation)
							noBtn:SetText("No")
							noBtn:Dock(RIGHT)
							noBtn.DoClick = function()
								confirmation:Remove()
							end

							noBtn:SetSize(90, 80)
						end
					end
					menu:Open()
				end

				local clearPreset = vgui.Create("DButton", topcontrols)
				clearPreset:Dock(BOTTOM)
				clearPreset:SetText("Clear Preset")
				clearPreset.DoClick = function()
					valz["BoxPreset"] = nil
					nzMapping.rbox.currentPreset = nil
					chat.AddText("[nZ] Map no longer uses a preset.")
					ResetRboxStyling()
				end

				local loadPreset = vgui.Create("DButton", topcontrols)
				loadPreset:Dock(BOTTOM)
				loadPreset:SetText("Use Preset")
				loadPreset.DoClick = function()
					LoadPresetWeps(GetSelectedFile())
					ShowPresetWarning()
				end

				nzMapping:UpdatePresets()
				local refreshBtn = vgui.Create("DImageButton", presetMenu)
				refreshBtn:SetImage("icon16/page_refresh.png")
				refreshBtn:SetSize(16, 16)
				refreshBtn:SetPos(2, 2)
				refreshBtn.DoClick = function()
					nzMapping:UpdatePresets()
				end

				openedPreset = presetMenu
			end

			-- local DermaButton2 = vgui.Create( "DButton", rboxpanel )
			-- DermaButton2:SetText( "Submit" )
			-- DermaButton2:SetPos( 0, 185 )
			-- DermaButton2:SetSize( 260, 30 )
			-- DermaButton2.DoClick = UpdateData

			sheet:AddSheet("Visuals & Sounds", customPnl, "icon16/photos.png", false, false, "Customize sounds, colors, skins and more!")

			------------------Sound Chooser----------------------------
			-- So we can create the elements in a loop
			local SndMenuMain = {
				[1] = {
					["Title"] = "Round Start",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow1"]
				},
				[2] = {
					["Title"] = "Round End",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow2"]
				},
				[3] = {
					["Title"] = "Special Round Start",
					["ToolTip"] = "Eg. Dog Round",
					["Bind"] = valz["SndRow3"]
				},
				[4] = {
					["Title"] = "Special Round End",
					["ToolTip"] = "Eg. Dog Round",
					["Bind"] = valz["SndRow4"]
				},
				[5] = {
					["Title"] = "Dog Round",
					["ToolTip"] = "ONLY for dog rounds!",
					["Bind"] = valz["SndRow5"]
				},
				[6] = {
					["Title"] = "Game Over",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow6"]
				}
			}

			local SndMenuPowerUp = {
				[1] = {
					["Title"] = "Spawn",
					["ToolTip"] = "Played on the powerup itself when it spawns",
					["Bind"] = valz["SndRow7"]
				},
				[2] = {
					["Title"] = "Grab",
					["ToolTip"] = "When players get the powerup",
					["Bind"] = valz["SndRow8"]
				},
				[3] = {
					["Title"] = "Insta Kill",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow9"]
				},
				[4] = {
					["Title"] = "Fire Sale",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow10"]
				},
				[5] = {
					["Title"] = "Death Machine",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow11"]
				},
				[6] = {
					["Title"] = "Carpenter",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow12"]
				},
				[7] = {
					["Title"] = "Nuke",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow13"]
				},
				[8] = {
					["Title"] = "Double Points",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow14"]
				},
				[9] = {
					["Title"] = "Max Ammo",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow15"]
				},
				[10] = {
					["Title"] = "Zombie Blood",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow16"]
				}
			}

			local SndMenuBox = {
				[1] = {
					["Title"] = "Shake",
					["ToolTip"] = "When the teddy appears and the box starts hovering",
					["Bind"] = valz["SndRow17"]
				},
				[2] = {
					["Title"] = "Poof",
					["ToolTip"] = "When the box moves to another destination",
					["Bind"] = valz["SndRow18"]
				},
				[3] = {
					["Title"] = "Laugh",
					["ToolTip"] = "When the teddy appears",
					["Bind"] = valz["SndRow19"]
				},
				[4] = {
					["Title"] = "Bye Bye",
					["ToolTip"] = "Plays along with Shake",
					["Bind"] = valz["SndRow20"]
				},
				[5] = {
					["Title"] = "Jingle",
					["ToolTip"] = "When weapons are shuffling",
					["Bind"] = valz["SndRow21"]
				},
				[6] = {
					["Title"] = "Open",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow22"]
				},
				[7] = {
					["Title"] = "Close",
					["ToolTip"] = "",
					["Bind"] = valz["SndRow23"]
				}
			}

			local sndPanel = vgui.Create("DPanel", customPnl)
			local sndheight, sndwidth = sheet:GetSize()
			sndPanel:SetSize(sndheight, (sndwidth - 50))
			customPnl:AddSheet("Custom Sounds", sndPanel, "icon16/sound_add.png", false, false, "Customize the sounds that play for certain events.")

			AddEyeStuff()

			local wrapper = vgui.Create("DPanel", sndPanel)
			wrapper:SetSize(500, 363)
			wrapper:SetPos(0, 0)

			-- A modifiable list of all sounds bound to currently selected event:
			local curSndList = vgui.Create("DListView", wrapper)
			curSndList:Dock(RIGHT)
			curSndList:SetSize(330, 200)
			curSndList:SetMultiSelect(false)
			curSndList:SetSortable(false)

			local curSndTbl = nil -- All sounds for currently selected Event Item
			local function DeleteNewItem(text, line)
				table.RemoveByValue(curSndTbl, text)
				curSndList:RemoveLine(line)
			end

			local soundsPlayed = {}
			curSndList.OnRowRightClick = function(lineID, line)
				local file = curSndList:GetLine(line):GetColumnText(1)
				local fileSubMenu = DermaMenu()
				local function StopPlayedSounds()
					for k,v in pairs(soundsPlayed) do
						LocalPlayer():StopSound(v)
					end
				end

				fileSubMenu:AddOption("Play", function()
					StopPlayedSounds()
					table.insert(soundsPlayed, file)
					curSound = CreateSound(LocalPlayer(), file)
					curSound:Play()
				end)

				fileSubMenu:AddOption("Stop", function()
					StopPlayedSounds()
				end)

				fileSubMenu:AddSpacer()
				fileSubMenu:AddSpacer()
				fileSubMenu:AddSpacer()
				fileSubMenu:AddOption("Remove", function()
					DeleteNewItem(file, line)
				end)

				fileSubMenu:Open()
			end

			local newCol = curSndList:AddColumn("Assigned Sounds")
			newCol:SetToolTip("A random sound from the list will play")
			local theList = nil
			local function NewSelectedItem(list, tbl)
				curSndTbl = tbl
				theList = list
				curSndList:Clear()
				for k,v in pairs(tbl) do
					local newline = curSndList:AddLine(v)
					newline:SetToolTip(v)
				end
			end

			local function AddNewItem(text)
				table.insert(curSndTbl, text)
				local newline = curSndList:AddLine(text)
				newline:SetTooltip(text)
			end

			local selectedData = {}
			if (ispanel(sndFilePanel)) then sndFilePanel:Remove() end
			sndFilePanel = nil -- We want to keep this reference so only 1 file menu exists at a time
			sndFileMenu = nil -- Keep this so we don't restructure and reset the file menu EVERY TIME

			local function ChooseSound() -- Menu to make selecting mounted sounds effortless
				local eventItem = theList:GetLine(theList:GetSelectedLine())
				if (!list || !eventItem) then return end

				sndFilePanel = vgui.Create("DFrame", frame)
				sndFilePanel:SetSize(500, 475)
				--sndFilePanel:Dock(FILL)
				sndFilePanel:SetTitle(eventItem:GetColumnText(1) .. " Sound")
				sndFilePanel:SetDeleteOnClose(true)
				sndFilePanel.OnClose = function()
					-- Pretend to close it so users can continue where they left off when adding another sound
					sndFileMenu:SetParent(frame)
					sndFileMenu:Hide()

					sndFilePanel = nil
				end

				if (!ispanel(sndFileMenu)) then
					fileMenu = vgui.Create("DFileBrowser", sndFilePanel)
					fileMenu:Dock(FILL)
					fileMenu:SetPath("GAME")
					fileMenu:SetFileTypes("*.wav *.mp3 *.ogg")
					fileMenu:SetBaseFolder("sound")
					fileMenu:SetOpen(true)
					sndFileMenu = fileMenu
				else
					sndFileMenu:SetParent(sndFilePanel)
					sndFileMenu:Show()
				end

				local soundsPlayed = {}
				function fileMenu:OnRightClick(filePath, selectedPnl)
					lastPath = fileMenu:GetCurrentFolder()

					if (SERVER) then return end
					filePath = string.Replace(filePath, "sound/", "")
					local fileSubMenu = DermaMenu()

					local function StopPlayedSounds()
						for k,v in pairs(soundsPlayed) do
							LocalPlayer():StopSound(v)
						end
					end

					fileSubMenu:AddOption("Play", function()
						StopPlayedSounds()
						table.insert(soundsPlayed, filePath)
						curSound = CreateSound(LocalPlayer(), filePath)
						curSound:Play()
					end)

					fileSubMenu:AddOption("Stop", function()
						StopPlayedSounds()
					end)

					fileSubMenu:AddSpacer()
					fileSubMenu:AddSpacer()
					fileSubMenu:AddSpacer()
					fileSubMenu:AddOption("Add", function()
						AddNewItem(filePath)
					end)

					fileSubMenu:Open()
				end
			end

			local catList = vgui.Create("DCategoryList", wrapper)
			catList:Dock(FILL)
			catList:Center()

			local addBtn = vgui.Create("DButton", curSndList)
			addBtn:SetText("Add Sound")
			addBtn:Dock(BOTTOM)
			addBtn.DoClick = function()
				ChooseSound()
			end

			-- Menu categories with Event Lists inside
			local mainCat = catList:Add("Main")
			local powerupCat = catList:Add("Powerups")
			powerupCat:SetExpanded(false)
			local boxCat = catList:Add("Mystery Box")
			boxCat:SetExpanded(false)
			local mainSnds = vgui.Create("DListView", mainCat)
			local powerUpSnds = vgui.Create("DListView", powerupCat)
			local boxSnds = vgui.Create("DListView", boxCat)

			mainSnds:SetSortable(false)
			powerUpSnds:SetSortable(false)
			boxSnds:SetSortable(false)

			local function AddDList(listView)
				listView:Dock(LEFT)
				listView:AddColumn("Event")
			end

			AddDList(mainSnds)
			AddDList(powerUpSnds)
			AddDList(boxSnds)
			mainCat:SetContents(mainSnds)
			powerupCat:SetContents(powerUpSnds)
			boxCat:SetContents(boxSnds)

			local function AddContents(tbl, listView)
				for k,v in ipairs(tbl) do
					local newItem = listView:AddLine(v["Title"])
					if (v["ToolTip"] != "") then newItem:SetTooltip(v["ToolTip"]) end

					listView.OnRowSelected = function(panel, rowIndex, row) -- We need to update the editable list for the item we have selected
						local tblSnds = tbl[rowIndex]["Bind"] -- The table of sounds that is saved along with the config
						NewSelectedItem(listView, tblSnds)
					end

					listView:SetMultiSelect(false)
				end
			end
			AddContents(SndMenuMain, mainSnds)
			AddContents(SndMenuPowerUp, powerUpSnds)
			AddContents(SndMenuBox, boxSnds)

			mainSnds:SelectFirstItem() -- Since Main category is always expanded, let's make sure the first item is selected

			local function AddCollapseCB(this) -- New category expanded, collapse all others & deselect their items
				this.OnToggle = function()
					if (this:GetExpanded()) then
						for k,v in pairs({mainCat, powerupCat, boxCat}) do
							if (v != this) then
								-- These categories are expanded, we cannot have more than 1 expanded so let's collapse these
								if (v:GetExpanded()) then
									v:Toggle()
								end
							else
								-- This category is expanded, let's select the first Event Item
								local listView = v:GetChild(1)
								if (ispanel(listView)) then
									listView:SelectFirstItem()
								end
							end
						end
					end
				end
			end
			AddCollapseCB(mainCat)
			AddCollapseCB(powerupCat)
			AddCollapseCB(boxCat)
			------------------------------------------------------------------------
			------------------------------------------------------------------------
			--local perklist = {}

			local perkandpoweruppanel = vgui.Create("DPropertySheet", sheet)
			local perkandpoweruppanelH, perkandpoweruppanelW = sheet:GetSize()
			perkandpoweruppanel:SetSize(perkandpoweruppanelH, (perkandpoweruppanelW - 50))
			sheet:AddSheet("Perks & Powerups", perkandpoweruppanel, "icon16/application_view_tile.png", false, false, "Modify the perk and powerup selection.")

			local perkpanel = vgui.Create("DPanel", perkandpoweruppanel)
			perkandpoweruppanel:AddSheet( "Wunderfizz Perks", perkpanel, "icon16/drink.png", false, false, "Set which perks appears in Der Wunderfizz.")
			perkpanel.Paint = function() return end

			local poweruppanel = vgui.Create("DPanel", perkandpoweruppanel)
			perkandpoweruppanel:AddSheet( "Powerups", poweruppanel, "icon16/flag_yellow.png", false, false, "Set which powerups can be dropped from zombies.")
			poweruppanel.Paint = function() return end

			---------------- Buildables ---------------------------------------------------------------
			local buildablepanel = vgui.Create("DProperties", sheet)
			sheet:AddSheet("Buildables", buildablepanel, "icon16/table.png", false, false, "Configure how the buildables behave.")

			local buildablesDisplayWepPart = buildablepanel:CreateRow("Buildables", "Display Part Weapon Name?")
			buildablesDisplayWepPart:Setup("Boolean")
			buildablesDisplayWepPart:SetValue(valz["BuildablesDisplayWepPart"])
			buildablesDisplayWepPart.DataChanged = function( _, val ) valz["BuildablesDisplayWepPart"] = val end
			buildablesDisplayWepPart:SetTooltip("Displays 'pick up <weapon name> part' or just 'pick up part'")

			local buildableDropRow = buildablepanel:CreateRow("Buildables", "Allow dropping?")
			buildableDropRow:Setup("Boolean")
			buildableDropRow:SetValue(valz["BuildablesDrop"])
			buildableDropRow.DataChanged = function( _, val ) valz["BuildablesDrop"] = val end
			buildableDropRow:SetTooltip("Allow buildables to be dropped by players, if off they will just respawn instead.")

			local buildableRespawnRow = buildablepanel:CreateRow("Buildables", "Force Respawn?")
			buildableRespawnRow:Setup("Boolean")
			buildableRespawnRow:SetValue(valz["BuildablesForceRespawn"])
			buildableRespawnRow.DataChanged = function( _, val ) valz["BuildablesForceRespawn"] = val end
			buildableRespawnRow:SetTooltip("Allow buildables to force reset after a while of being picked up or dropped.")

			local buildableShareRow = buildablepanel:CreateRow("Buildables", "Share Across Players?")
			buildableShareRow:Setup("Boolean")
			buildableShareRow:SetValue(valz["BuildablesShare"])
			buildableShareRow.DataChanged = function( _, val ) valz["BuildablesShare"] = val end
			buildableShareRow:SetTooltip("Make everyone share parts from the same inventory. (Disables swapping and some of the dropping functionality!)")

			local buildableMaxAmountRow = buildablepanel:CreateRow("Buildables", "Max Parts at a Time")
			buildableMaxAmountRow:Setup("Integer")
			buildableMaxAmountRow:SetValue(valz["BuildablesMaxAmount"])
			buildableMaxAmountRow.DataChanged = function( _, val ) valz["BuildablesMaxAmount"] = val end
			buildableMaxAmountRow:SetTooltip("How many parts a player can have at any given time?")
			--------------------------------------------------------------------------------------------------

			local perklistpnl = vgui.Create("DScrollPanel", perkpanel)
			perklistpnl:SetPos(0, 0)
			perklistpnl:SetSize(465, 450)
			perklistpnl:SetPaintBackground(true)
			perklistpnl:SetBackgroundColor( Color(200, 200, 200) )

			local perkchecklist = vgui.Create( "DIconLayout", perklistpnl )
			perkchecklist:SetSize( 465, 450 )
			perkchecklist:SetPos( 35, 10 )
			perkchecklist:SetSpaceY( 5 )
			perkchecklist:SetSpaceX( 5 )

			for k,v in pairs(wunderfizzlist) do
				if (!valz["Wunderfizz"] || !valz["Wunderfizz"][k]) then return end

				local perkitem = perkchecklist:Add( "DPanel" )
				perkitem:SetSize( 130, 20 )

				local check = perkitem:Add("DCheckBox")
				check:SetPos(2,2)

				if (nzMapping.Settings.wunderfizzperklist and istable(nzMapping.Settings.wunderfizzperklist[k]) and isbool(nzMapping.Settings.wunderfizzperklist[k][1])) then
					check:SetValue(nzMapping.Settings.wunderfizzperklist[k][1])
				else
					check:SetValue(true)
				end

				--if has then perklist[k] = true else perklist[k] = nil end
				check.OnChange = function(self, val)
					--if val then perklist[k] = true else perklist[k] = nil end
					valz["Wunderfizz"][k][1] = val
					--nzMapping:SendMapData( {wunderfizzperks = perklist} )
				end

				local name = perkitem:Add("DLabel")
				name:SetTextColor(Color(50,50,50))
				name:SetSize(105, 20)
				name:SetPos(20,1)
				name:SetText(v[2])
			end

			local poweruplistpnl = vgui.Create("DScrollPanel", poweruppanel)
			poweruplistpnl:SetPos(0, 0)
			poweruplistpnl:SetSize(465, 450)
			poweruplistpnl:SetPaintBackground(true)
			poweruplistpnl:SetBackgroundColor( Color(200, 200, 200) )

			local powerupchecklist = vgui.Create( "DIconLayout", poweruplistpnl )
			powerupchecklist:SetSize( 465, 450 )
			powerupchecklist:SetPos( 35, 10 )
			powerupchecklist:SetSpaceY( 5 )
			powerupchecklist:SetSpaceX( 5 )

			for k,v in pairs(poweruplist) do
				if (!valz["PowerUps"] || !valz["PowerUps"][k]) then return end

				local powerupitem = powerupchecklist:Add( "DPanel" )
				powerupitem:SetSize( 130, 20 )

				local check = powerupitem:Add("DCheckBox")
				check:SetPos(2,2)

				if (nzMapping.Settings.poweruplist and istable(nzMapping.Settings.poweruplist[k]) and isbool(nzMapping.Settings.poweruplist[k][1])) then
					check:SetValue(nzMapping.Settings.poweruplist[k][1])
				else
					check:SetValue(true)
				end

				--if has then perklist[k] = true else perklist[k] = nil end
				check.OnChange = function(self, val)
					valz["PowerUps"][k][1] = val
				end

				local name = powerupitem:Add("DLabel")
				name:SetTextColor(Color(50,50,50))
				name:SetSize(105, 20)
				name:SetPos(20,1)
				name:SetText(v[2])
			end

			local mdlPanel = vgui.Create("DPanel", sheet)
			sheet:AddSheet("Playermodels", mdlPanel, "icon16/group.png", false, false, "The playermodels randomly applied to players")

			local wrapper = vgui.Create("DPanel", mdlPanel)
			wrapper:SetSize(500, 390)

			local modelListWrapper = vgui.Create("DPanel", wrapper)
			modelListWrapper:SetSize(170, 390)
			modelListWrapper:Dock(RIGHT)
			modelListWrapper.PaintOver = function() -- Make this panel have a border like the rest
				surface.SetDrawColor(0, 0, 0)
				modelListWrapper:DrawOutlinedRect()
			end

			-- Title "Added Models" WITH tool tip (DLabels on their own cannot have tooltips)
			local infoandtext = vgui.Create("DPanel", modelListWrapper)
			infoandtext:SetTooltip("NZ will shuffle this list and then apply models in whatever order it ends up as to players, it will only repeat when all have been applied.")
			infoandtext:SetSize(300, 20)
			local title = vgui.Create("DLabel", infoandtext)
			title:SetText("Added Models")
			title:SetTextColor(Color(0, 0, 0))
			title:SetSize(100, 20)
			title:SetPos(30, 0)

			-- Model list
			local mdlStuff = vgui.Create("DPanel", wrapper)
			mdlStuff:Dock(LEFT)
			mdlStuff:SetSize(330, 300)
			mdlStuff:DockPadding(5, 5, 5, 5)

			local presets = vgui.Create("DComboBox", mdlStuff)
			presets:Dock(BOTTOM)
			presets:SetSize(350, 20)
			presets:AddChoice("Ultimis")
			presets:AddChoice("Primis")
			presets:AddChoice("Space")
			presets:AddChoice("Mob")
			presets:AddChoice("Marines")
			presets:AddChoice("Rebels")
			presets:AddChoice("Combine")
			presets:SetSortItems(false)

			--valz["ModelPack"] = nzMapping.Settings.modelpack

			local prop = vgui.Create("DProperties", modelListWrapper)
			prop:SetPos(2, 22)
			prop:SetSize(128, 363)

			local function RemoveOption(parent) -- Deletes option from DProperties but also from our custom Settings table
				local option = parent:GetChild(1)

				for _,v in pairs(valz["ModelPack"]) do
					local pnl = v["Panel"]
					if (table.HasValue(parent:GetChild(1):GetChildren(), pnl)) then
						table.RemoveByValue(valz["ModelPack"], v)
						parent:Remove()
					end
				end
			end

			local function OptionExists(alias)
				local returnVal = false

				for _, v in pairs(valz["ModelPack"]) do
					if (v["Alias"] == alias) then
						returnVal = true
					end
				end

				return returnVal
			end

			local function GetBodyGroupData(model) -- Helper function for getting all body groups for properties
				local ent = ents.CreateClientProp()
				ent:SetModel(model)
				ent:Spawn()

				local bgroups = {}
				if (IsValid(ent)) then
					bgroups = ent:GetBodyGroups()
					ent:Remove()
				end

				return bgroups
			end

			local function AddOption(path, expand)
				local settings = valz["ModelPack"]

				local alias = player_manager.TranslateToPlayerModelName(path)
				local backupAlias = path -- Fallback alias if the model has no alias set:
				backupAlias = string.gsub(backupAlias, ".*/", "")
				backupAlias = string.Replace(backupAlias, ".mdl", "")
				if (alias == "kleiner") then alias = backupAlias end
				local updatedAlias = ""

				if (OptionExists(alias)) then -- Path was added already, add a duplicate instead

					local dupeNumber = 1
					while (OptionExists(alias .. " " .. dupeNumber)) do
						dupeNumber = dupeNumber + 1
					end

					updatedAlias = alias .. " " .. dupeNumber
				else
					updatedAlias = alias
				end

				settings[#settings + 1] = {
					["Panel"] = prop:CreateRow(updatedAlias, "Skin"),
					["Path"] = path,
					["Alias"] = updatedAlias
				}

				local setting = settings[#settings]
				setting["Bodygroups"] = {
					["Values"] = {},
					["Panels"] = {}
				}

				local bodygroups = GetBodyGroupData(path)
				for _,v in pairs(bodygroups) do
					local newbgroup = prop:CreateRow(updatedAlias, v.name)
					newbgroup:Setup("Int", {min = 0, max = 20})
					newbgroup:SetTooltip("Bodygroup: " .. v.name)

					local panels = setting["Bodygroups"]["Panels"]
					panels[#panels + 1] = {
						["Panel"] = newbgroup,
						["GroupName"] = v.name
					}

					newbgroup.DataChanged = function(_, val)
						if (!isnumber(val)) then val = 0 end
						val = math.Round(val)

						for _,v in pairs(panels) do
							if (v["Panel"] == newbgroup) then
								local name = v.GroupName
								setting["Bodygroups"]["Values"][name] = val
							end
						end
					end
				end

				local newOption = settings[#settings]["Panel"]
				newOption.DataChanged = function(_, val)
					val = math.Round(val)
					if (!isnumber(val)) then val = 0 end
					setting["Value"] = val
				end

				if (ispanel(newOption)) then
					newOption:Setup("Int", {min = 0, max = 20})

					local parent = newOption:GetParent():GetParent() -- The control's container
					if (!expand) then -- Start as collapsed
						local expandBtn = parent:GetChild(0):GetChild(1)
						if (ispanel(expandBtn)) then
							if (expandBtn:GetExpanded()) then
								expandBtn:SetExpanded(false)
								expandBtn:DoClick()
							end
						end
					end

					-- Inserts a custom remove button (Since there's no OnRightClick function for DProperty to place a menu at)
					if (ispanel(newOption:GetParent())) then -- The control
						if (ispanel(parent)) then
							parent:SetTooltip(path)

							local removeBtn = vgui.Create("DImageButton", newOption:GetParent():GetParent())
							removeBtn:SetImage("icon16/delete.png")
							removeBtn:SetSize(13, 13)
							removeBtn:SetPos(103, 5)
							removeBtn.DoClick = function()
								RemoveOption(parent)
							end
						end
					end
				end

				return settings[#settings]
			end

			local function SetValues(values)
				prop:Clear()
				valz["ModelPack"] = {}

				local function SetDefaultGroups(setting)
					for _,v in pairs(setting["Bodygroups"]["Panels"]) do
						v["Panel"]:DataChanged(0)
					end
				end

				for _,v in pairs(values) do
					local setting = nil
					local newoption = nil

					if (istable(v)) then
						setting = AddOption(v["Path"])
						newoption = setting["Panel"]
						newoption:SetValue(v["Skin"])
						newoption:DataChanged(v["Skin"])
					else
						setting = AddOption(v)
						newoption = setting["Panel"]
					end

					for _,b in pairs(setting["Bodygroups"]["Panels"]) do
						local gName = b.GroupName
						if (istable(v) and istable(v["Bodygroups"])) then
							for a,c in pairs(v["Bodygroups"]) do
								if (gName == a) then
									b.Panel:SetValue(c)
									b.Panel:DataChanged(c)
								end
							end
						end
					end
				end
			end

			local mdlBrowser = vgui.Create("DFileBrowser", mdlStuff)
			mdlBrowser:SetSize(350, 350)
			mdlBrowser:SetFileTypes("*.mdl")
			mdlBrowser:SetBaseFolder("models")
			mdlBrowser:SetCurrentFolder("models/player")
			mdlBrowser:SetModels(true)
			mdlBrowser:SetOpen(true)
			mdlBrowser:Dock(TOP)
			mdlBrowser.OnSelect = function (selectedPanel, filePath)
				presets:SetValue("")
				AddOption(filePath)
			end

			mdlBrowser.OnRightClick = function (selectedPanel, filePath)
				local selectMenu = vgui.Create("DMenu", mdlBrowser)
				selectMenu:AddOption("Inspect", function()
					if (ispanel(NZPreviewMDLSelectPnl)) then
						NZPreviewMDLSelectPnl:Remove()
						NZPreviewMDLSelectPnl = nil
					end

					NZPreviewMDLSelectPnl = vgui.Create("DFrame", frame)
					NZPreviewMDLSelectPnl:SetSize(400, 400)
					NZPreviewMDLSelectPnl:Center()
					NZPreviewMDLSelectPnl:SetTitle("Model Preview")

					local mdlSplit = vgui.Create("DHorizontalDivider", NZPreviewMDLSelectPnl)
					mdlSplit:SetPos(0, 28)
					mdlSplit:SetSize(400, 400)

					local mdlPreview = vgui.Create("DAdjustableModelPanel", NZPreviewMDLSelectPnl)
					mdlPreview:SetModel(filePath)
					mdlPreview:Dock(LEFT)
					mdlPreview:SetSize(200, 400)
					-- Fix angle & position
					mdlPreview:GetEntity():SetPos(Vector(0, 0, -40))
					mdlPreview:GetEntity():SetAngles(mdlPreview:GetEntity():GetAngles() + Angle(0, 35, 0))
					mdlPreview:SetCamPos(mdlPreview:GetCamPos() - Vector(50, 50, 0))
					function mdlPreview:PaintOver()
						surface.SetDrawColor(0, 0, 0)
						self:DrawOutlinedRect()
					end

					-- Workaround for model not showing until panel is clicked:
					mdlPreview:OnMousePressed(MOUSE_FIRST)
					timer.Simple(0, function()
						mdlPreview:OnMouseReleased(MOUSE_FIRST)

						local posX, posY = mdlPreview:LocalToScreen(110, 80)
						input.SetCursorPos(posX, posY)
					end)

					function mdlPreview:LayoutEntity( ent )
						return -- Disable it from spinning
					end

					local prop = vgui.Create("DProperties", NZPreviewMDLSelectPnl)
					prop:SetPos(0, 28)
					prop:SetSize(300, 400)

					mdlSplit:SetLeft(mdlPreview)
					mdlSplit:SetRight(prop)
					mdlSplit:SetDividerWidth(1)
					mdlSplit:SetLeftWidth(200)

					local skin = prop:CreateRow(filePath, "Skin")
					skin:Setup("Int", {min = 0, max = 20})

					local savedSkin = 0
					skin.DataChanged = function(_, val)
						if (!isnumber(val)) then val = 0 end
						val = math.Round(val)
						mdlPreview:GetEntity():SetSkin(val)
						savedSkin = val
					end

					-- Create bodygroup properties
					local bodygroups = GetBodyGroupData(filePath)
					local savedBodyGroups = {}
					for _,v in pairs(bodygroups) do
						local newbgroup = prop:CreateRow(filePath, v.name)
						newbgroup:Setup("Int", {min = 0, max = 20})
						newbgroup:SetTooltip("Bodygroup: " .. v.name)
						savedBodyGroups[newbgroup] = {
							["Name"] = v.name,
							["Value"] = 0,
							["ID"] = v.id
						}

						newbgroup.DataChanged = function(panel, val)
							if (!isnumber(val)) then val = 0 end
							val = math.Round(val)

							-- Save this for when the Add Model button is pressed
							savedBodyGroups[panel]["Value"] = val

							-- Set this bodygroup to the preview model
							local id = savedBodyGroups[panel]["ID"]
							if (isnumber(id)) then
								mdlPreview:GetEntity():SetBodygroup(id, val)
							end
						end
					end

					-- Add new model to the list with all the skin & bodygroup changes
					local addModel = vgui.Create("DButton", NZPreviewMDLSelectPnl)
					addModel:SetText("Add Model")
					addModel:Dock(BOTTOM)
					addModel.DoClick = function()
						local setting = AddOption(filePath, true)
						setting["Panel"]:SetValue(savedSkin)
						setting["Panel"]:DataChanged(savedSkin)

						for _,v in pairs(bodygroups) do
							for _,b in pairs(savedBodyGroups) do
								if (b["Name"] == v.name) then
									for _,c in pairs(setting["Bodygroups"]["Panels"]) do
										if (c.GroupName == b["Name"]) then
											c.Panel:SetValue(b["Value"])
											c.Panel:DataChanged(b["Value"])
										end
									end
								end
							end
						end
					end
				end)
				selectMenu:Open()
			end

			presets.OnSelect = function(index, value, data) -- Model Presets
				if (data == "Ultimis") then
					SetValues({
						"models/player/dempsey_bo3.mdl",
						"models/player/nikolai_bo3.mdl",
						"models/player/richtofen_bo3.mdl",
						"models/player/takeo_bo3.mdl"
					})
				elseif (data == "Primis") then
					SetValues({
						"models/thataveragejoe/blackops3/primis/dempsey.mdl",
						"models/thataveragejoe/blackops3/primis/nikolai.mdl",
						"models/thataveragejoe/blackops3/primis/richtofen.mdl",
						"models/thataveragejoe/blackops3/primis/takeo.mdl"
					})
				elseif (data == "Space") then
					SetValues({
						"models/player/hidden/pes_characters/dempsey.mdl",
						"models/player/hidden/pes_characters/nikolai.mdl",
						"models/player/hidden/pes_characters/richtofen.mdl",
						"models/player/hidden/pes_characters/takeo.mdl"
					})
				elseif (data == "Mob") then
					SetValues({
						"models/motd/p_arlington.mdl",
						"models/motd/p_deluca.mdl",
						"models/motd/p_handsome.mdl",
						"models/motd/p_oleary.mdl"
					})
				elseif (data == "Marines") then
					SetValues({
						"models/player/marine_1pm.mdl",
						{
							["Path"] = "models/player/marine_1pm.mdl",
							["Skin"] = 1,
							["Bodygroups"] = {
								["Gear"] = 1
							}
						},
						{
							["Path"] = "models/player/marine_1pm.mdl",
							["Skin"] = 2,
							["Bodygroups"] = {
								["Gear"] = 2
							}
						},
						{
							["Path"] = "models/player/marine_1pm.mdl",
							["Skin"] = 3,
							["Bodygroups"] = {
								["Gear"] = 8
							}
						}
					})
				elseif (data == "Rebels") then
					SetValues({
						"models/player/group03/male_01.mdl",
						"models/player/group03/male_02.mdl",
						"models/player/group03/male_04.mdl",
						"models/player/group03/male_05.mdl",
						"models/player/group03/male_06.mdl",
						"models/player/group03/male_07.mdl",
						"models/player/group03/male_08.mdl",
						"models/player/group03/male_09.mdl",
						"models/player/group03/female_01.mdl",
						"models/player/group03/female_04.mdl"
					})
				elseif (data == "Combine") then
					SetValues({
						"models/player/combine_soldier.mdl",
						"models/player/combine_soldier_prisonguard.mdl",
						"models/player/combine_super_soldier.mdl",
						"models/player/police.mdl"
					})
				end
			end

			-- Set to default tab if no modelpack was saved in the past
			if (istable(valz["ModelPack"]) and !table.IsEmpty(valz["ModelPack"])) then
				SetValues(valz["ModelPack"])
			else
				presets:OnSelect(1, "Ultimis", "Ultimis")
				presets:SetValue("Ultimis")
			end
		else
			sheet:AddSheet("Visuals & Sounds", customPnl, "icon16/photos.png", false, false, "Customize sounds, colors, skins and more!")
			local text = vgui.Create("DLabel", DProperties)
			text:SetText("Enable Advanced Mode for more options.")
			text:SetFont("Trebuchet18")
			text:SetTextColor( Color(50, 50, 50) )
			text:SizeToContents()
			text:SetPos(0, 140)
			text:CenterHorizontal()
		end

		return sheet
	end,
	-- defaultdata = {}
})
