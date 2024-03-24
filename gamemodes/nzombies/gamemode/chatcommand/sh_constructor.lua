-- Chat Commands module

-- Recoded by Ethorbit because the
-- previous implementation was retarded and
-- required all commands to be defined serverside
-- to function properly.

-- Now, commands will be executed in the realm they were defined in.
-- Shared realm commands are also possible now.

-- All existing chat commands can be retreived regardless of the realm.

-- WARNING!:
-- Chat commands entered are hidden on the CLIENTSIDE only (due to serverside blocking the clientside's command listener)
-- This means if your command requires sensitive info (like passwords) cheaters will be able to
-- see that info typed by other players (even if the command is defined on the server only)
-- If you really need to do this, I recommend creating a serverside chat command manually


nzChatCommand = nzChatCommand or AddNZModule("chatcommand")

nzChatCommand.maxAllowedCommands   = 5000 -- Increase if this is an issue.
nzChatCommand.maxLength 		   = 120
nzChatCommand.maxUsageLength 	   = 250

nzChatCommand.addedCommands = nzChatCommand.addedCommands or 0
nzChatCommand.commands = nzChatCommand.commands or {}
nzChatCommand.prefixes = nzChatCommand.prefixes or {} -- added by Ethorbit to both continue the optimization and allow more than just "/"

--[[ nzChatCommand.Add
	text [string]: The text you put in chat to trigger this command
	func [function]: The function to run when the command is issued. It runs the function with the player as the first argument, then all arguments in the chat seperated by space
	allowAll [boolean]: If set to true, will allow even non-admins to run this command
--]]
function nzChatCommand.Add(text, func, allowAll, usageHelp)
	if !text then return end

	if (nzChatCommand.addedCommands + 1 >= nzChatCommand.maxAllowedCommands) then
		ServerLog("[nZombies Command Error] The maximum amount of commands has been hit! (" .. nzChatCommand.maxAllowedCommands .. ") Increase nzChatCommand.maxAllowedCommands if this is too low for you.")
	return end

	text = string.sub(text, 1, nzChatCommand.maxLength)

	if usageHelp then
		usageHelp = string.sub(usageHelp, 1, nzChatCommand.maxUsageLength)
	end

	nzChatCommand.prefixes[text[1]] = true -- We're assuming the first character is a command prefix (/), it's no big deal if this is incorrect.

	local new_value = {["text"] = text, ["func"] = func, ["allowAll"] = allowAll and true or false, ["usageHelp"] = usageHelp or ""}
	nzChatCommand.commands[text] = new_value -- This is much better than table.insert..
	nzChatCommand.addedCommands = nzChatCommand.addedCommands + 1

	local networkTbl = table.Copy(new_value)
	networkTbl.func = nil -- They wouldn't be able to call that correctly lol

	net.Start("nzUpdateChatCommand")
	net.WriteString(text)
	net.WriteTable(networkTbl)

	if SERVER then
		net.Broadcast()
	else
		net.SendToServer()
	end
end

-- Remove a command.
-- This is not really recommended as commands were designed
-- to be static, but do this if you must.
function nzChatCommand.Remove(text)
	nzChatCommand.commands[text] = nil
	nzChatCommand.addedCommands = nzChatCommand.addedCommands - 1

	net.Start("nzUpdateChatCommand")
	net.WriteString(text)

	if SERVER then
		net.Broadcast()
	else
		net.SendToServer()
	end
end

-- Get all commands, does not matter what realm it's ran in, output is synchronized.
function nzChatCommand.GetAll()
	local current_realm_commands = nzChatCommand.commands
	local other_realm_commands = CLIENT and nzChatCommand.serverCommands or nzChatCommand.clientCommands and nzChatCommand.clientCommands[ply]
	local commands = {}
	local current_added = {}

	for _,current in pairs(current_realm_commands) do
		if current.text then
			current_added[current.text] = true
			commands[current.text] = current
		end
	end

	for _,other in pairs(other_realm_commands) do
		if other.text and !current_added[other.text] then
			commands[other.text] = other
		end
	end

	return commands
end

-- Check if a command exists, does not matter what realm it's ran in, output is synchronized.
function nzChatCommand.Exists(text)
	local exists_in_current_realm = nzChatCommand.commands[text]
	if exists_in_current_realm then
		return true
	end

	local exists_in_other_realm = CLIENT and nzChatCommand.serverCommands[text] or nzChatCommand.clientCommands and nzChatCommand.clientCommands[ply] and nzChatCommand.clientCommands[ply][text]
	return exists_in_other_realm
end

function nzChatCommand.splitCommand(command)
	local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
	local result = {}
	for str in string.gmatch(command, "%S+") do
		local squoted = str:match(spat)
		local equoted = str:match(epat)
		local escaped = str:match([=[(\*)['"]$]=])
		if squoted and not quoted and not equoted then
			buf, quoted = str, squoted
		elseif buf and equoted == quoted and #escaped % 2 == 0 then
			str, buf, quoted = buf .. ' ' .. str, nil, nil
		elseif buf then
			buf = buf .. ' ' .. str
		end
		if not buf then table.insert(result, (str:gsub(spat,""):gsub(epat,""))) end
	end
	if buf then return nil end
	return result
end

local function commandListener(ply, text)
	if nzChatCommand.prefixes[text[1]] then -- This will allow more than just '/'
		text = string.lower(text)

		local args = nzChatCommand.splitCommand(text)
		local commandName = args[1]
		local commandWasDenied = false

		for k,v in pairs(nzChatCommand.commands) do
			if (string.sub(text, 1, string.len(v.text)) == v.text) then
				if CLIENT and ply != LocalPlayer() then return true end

				if (!v.allowAll and !ply:IsNZAdmin()) then
					ply:ChatPrint("NZ This command can only be used by administrators.")
					commandWasDenied = true
				else
					if v.func then
						-- Check if quotionmark usage was valid
						if args then
							-- Remove first arguement (command name) and then call function with the reamianing args
							table.remove(args, 1)
							v.func(ply, args)
							print("NZ " .. tostring(ply) .. " used command " .. v.text .. " with arguments:\n" .. table.ToString(args))

							if CLIENT then return true end
						else
							ply:ChatPrint("NZ Invalid command usage (check for missing quotes).")

							if CLIENT then return true end
						end
					end
				end
			end
		end

		if !commandWasDenied then
			if CLIENT and ply != LocalPlayer() then return true end

			if CLIENT and !nzChatCommand.Exists(commandName) then
				ply:ChatPrint("NZ No valid command exists with this name, try '/help' for a list of commands.")
			end
		end

		if CLIENT then return true end
	end
end

if SERVER then
	hook.Add("PlayerSay", "nzChatCommandListenerServer", commandListener)
else
	hook.Add("OnPlayerChat", "nzChatCommandListenerClient", commandListener)
end


-- Console command nz_chatcommand in case another addon blocks the hooks (works just like chat, "nz_chatcommand [chat commands]")
local function nz_chatcommand(ply, cmd, args, argstr)
	if !argstr then return end
	argstr = string.Trim(argstr, " ") -- Trim spaces
	if string.sub(argstr, 1, 1) == "\"" and string.sub(argstr, #argstr, #argstr) == "\"" then
		argstr = string.sub(argstr, 2, #argstr-1) -- Trim quotation marks but only if they are around the WHOLE string
		-- As to avoid trimming in commmands like /revive "Some Name with Spaces"
	end
	net.Start("nzChatCommand")
		net.WriteString(argstr)
	net.SendToServer()
	commandListener(LocalPlayer(), argstr)
end

if SERVER then
	util.AddNetworkString("nzUpdateChatCommand")
	util.AddNetworkString("INeedTheServerNZChatCommands")
	util.AddNetworkString("HereIsTheServerNZChatCommands")

	-- Since we cannot trust a client to truthfully provide us client commands
	-- we will store a separate client command table per player and make
	-- sure to only use it for harmless comparisons
	nzChatCommand.clientCommands = nzChatCommand.clientCommands or {}
	nzChatCommand.networkMaxLengthAllowed = 3000 + ((nzChatCommand.maxLength + nzChatCommand.maxUsageLength) * 8)
	local excluded_plys = {}
	net.Receive("nzUpdateChatCommand", function(len, ply)
		if excluded_plys[ply] then return end

		if len >= nzChatCommand.networkMaxLengthAllowed then -- Piss off, spammer
			ply:Kick("Spamming NZ Command Creation")
		return end

		local key = net.ReadString()
		local val = net.ReadTable()

		if !nzChatCommand.clientCommands[ply] then
			nzChatCommand.clientCommands[ply] = {}
		end

		-- Stop it..
		if table.Count(nzChatCommand.clientCommands[ply]) >= nzChatCommand.maxAllowedCommands then
			excluded_plys[ply] = true
		return end

		nzChatCommand.clientCommands[ply][key] = val
	end)

	-- Receiving server-defined commands (for printing to /help and things)
	net.Receive("INeedTheServerNZChatCommands", function(len, ply)
		if ply.NextAllowedNZChatCommandUpdate and CurTime() < ply.NextAllowedNZChatCommandUpdate then return end
		ply.NextAllowedNZChatCommandUpdate = CurTime() + 3

		local netTbl = table.Copy(nzChatCommand.commands)
		for _,cmdTbl in pairs(netTbl) do
			cmdTbl.func = nil
		end

		net.Start("HereIsTheServerNZChatCommands")
		net.WriteTable(netTbl)
		net.Send(ply)
	end)

	-- Receiving net messages from console command nz_chatcommand instead (in case another addon blocks the hook)
	util.AddNetworkString("nzChatCommand")
	net.Receive("nzChatCommand", function(len, ply)
		if !IsValid(ply) then return end
		if ply.NextAllowedChatCommand and CurTime() < ply.NextAllowedChatCommand then return end -- No one should be executing commands this fast /Ethorbit
		ply.NextAllowedChatCommand = CurTime() + 0.5
		local command = net.ReadString()
		print("Got command", command)
		commandListener(ply, command)
	end)
end

if CLIENT then
	nzChatCommand.serverCommands = nzChatCommand.serverCommands or {}

	hook.Add("InitPostEntity", "NZ_RetrieveAllServerChatCommands", function()
		net.Start("INeedTheServerNZChatCommands")
		net.SendToServer()
	end)

	net.Receive("HereIsTheServerNZChatCommands", function()
		local tbl = net.ReadTable()
		nzChatCommand.serverCommands = tbl
	end)

	net.Receive("nzUpdateChatCommand", function()
		local key = net.ReadString()
		local tbl = net.ReadTable()

		if !table.IsEmpty(tbl) then
			nzChatCommand.serverCommands[key] = tbl
		else
			nzChatCommand.serverCommands[key] = nil
		end
	end)

	-- Even comes with autocomplete :D
	local function nz_chatcommand_autocomplete(cmd, argstr)
		argstr = string.Trim( argstr )
		argstr = string.lower( argstr )

		local tbl = {}

		for _, cmd in pairs(nzChatCommand.GetAll()) do
			local cmdText = cmd.text
			if string.find(cmdText, argstr) then
				if cmd.allowAll or (!cmd.allowAll and LocalPlayer():IsNZAdmin()) then
					local text = "nz_chatcommand ".. cmdText
					if !table.HasValue(tbl, text) then
						table.insert(tbl, text)
					end
				end
			end
		end

		return tbl
	end
	concommand.Add("nz_chatcommand", nz_chatcommand, nz_chatcommand_autocomplete, "Executes a chatcommand without the use of chat, in case chatcommands don't work.")
end
