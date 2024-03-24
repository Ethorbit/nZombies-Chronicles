if not ConVarExists("nz_eastereggsongs") then CreateClientConVar("nz_eastereggsongs", "1") end

cvars.AddChangeCallback("nz_eastereggsongs", function( convar_name, value_old, value_new )
	local old, new = tobool(value_old), tobool(value_new)
	if old != new then
		if new then
			EasterEggData.ParseSong(play)
		else
			EasterEggData.StopSong()
			EasterEggData.AudioChannel = nil
			EasterEggData.PreloadedSong = nil
		end
	end
end)

EasterEggData = EasterEggData or {}
EasterEggData.AudioChannel = EasterEggData.AudioChannel or nil
EasterEggData.PreloadedSong = EasterEggData.PreloadedSong or nil

net.Receive("EasterEggSong", function()
	EasterEggData.PlaySong()
end)

net.Receive("EasterEggSongPreload", function()
	timer.Simple(1, function()
		EasterEggData.ParseSong()
	end)
end)

net.Receive("EasterEggSongStop", function()
	EasterEggData.StopSong()
end)

local function play_song(url, flags) -- Added by Ethorbit to make it easier and more reliable to PlayURL, with error handling and proper playback
	local isPreloading = string.find(flags, "noplay")
	if isPreloading then
		if EasterEggData.PreloadedSong == url then return end -- We already did this..
		EasterEggData.PreloadedSong = url
	end

	if !isPreloading and IsValid(EasterEggData.AudioChannel) then
		print("Playing easter egg song!")
		EasterEggData.AudioChannel:Play()
	return end

	sound.PlayURL(url, flags, function(channel, errorID, errorName)
		if channel then
			EasterEggData.AudioChannel = channel
		end

		if !isPreloading then
			print("Easter egg song was not preloaded, will play through streaming.")
			print(url)

			if errorID then
				chat.AddText("[nZombies] An error occurred when trying to play the Easter Egg. - ", errorID, errorName)
			return end

			if IsValid(channel) then
				channel:Play()
			end
		else
			if !errorID then
				print("Successfully preloaded easter egg song")
			else
				EasterEggData.PreloadedSong = nil
				print("Failed to preload song - ", errorID, errorName)
			end
		end
	end)
end

function EasterEggData.ParseSong(play)
	if !GetConVar("nz_eastereggsongs"):GetBool() then
		print("Prevented loading the Easter Egg song because you have nz_eastereggsongs set to 0.")
	return end

	if !nzMapping.Settings.eeurl then return end
	local url = nzMapping.Settings.eeurl
	--local url = string.lower(nzMapping.Settings.eeurl) -- This is not only unnecessary but also breaks Google Drive URLs..
	if url == nil or url == "" then return end

	local soundcloud = string.find(url, "soundcloud.com/")

	if (soundcloud) then -- TODO: fix client_id issue. Soundcloud deprecated it in July 2021 and as of writing this they are not yet accepting new API applications.. /Ethorbit
		http.Fetch( "http://api.soundcloud.com/resolve?url="..url.."&client_id=d8e0407577f7fc8475978904ef89b1f7",
			function( body, len, headers, code )
				if body then
					local _, streamstart = string.find(body, '"stream_url":"')
					if !streamstart then print("This Soundcloud song does not have allow streaming.") return end
					local streamend = string.find(body, '","', streamstart + 1)
					local stream = string.sub(body, streamstart + 1, streamend - 1)
					if stream then
						if play then
							EasterEggData.PlaySong(stream.."?client_id=d8e0407577f7fc8475978904ef89b1f7")
						else
							EasterEggData.PreloadSong(stream.."?client_id=d8e0407577f7fc8475978904ef89b1f7")
						end
					else
						print("This Soundcloud song does not have allow streaming.")
					end
				return end
			end,
			function( error )
				Error( "Failed to fetch song! Error: " .. error )
			end )
	else
		if play then
			EasterEggData.PlaySong(url)
		else
			EasterEggData.PreloadSong(url)
		end
	end
end

function EasterEggData.PlaySong(url) -- Modified by Ethorbit, moved most functionality into the local helper function 'play_song' above
	--EasterEggData.StopSong()

	if !GetConVar("nz_eastereggsongs"):GetBool() then
		print("Prevented playing the Easter Egg song because you have nz_eastereggsongs set to 0.")
		return
	end

	if !url then
		EasterEggData.ParseSong(true)
	return end

	play_song(url, "")
end

function EasterEggData.StopSong()
	if IsValid(EasterEggData.AudioChannel) then
		local url = EasterEggData.PreloadedSong
		EasterEggData.AudioChannel:Stop()

		if url and !IsValid(EasterEggData.AudioChannel) then -- Because Garry's Mod is retarded and Stop()ing removes the channel entirely /Ethorbit
			EasterEggData.PreloadedSong = nil
			EasterEggData.PreloadSong(url)
		end
	end
end

function EasterEggData.PreloadSong(song) -- Modified by Ethorbit  ^^^^^^^
	play_song(song, "noplay noblock")
end
