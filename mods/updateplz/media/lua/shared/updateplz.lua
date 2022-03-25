local getTimestamp = getTimestamp
local isServer = getCore():isDedicated()

UpdatePLZ = UpdatePLZ or {}

local chat do
	if isServer then
		chat = print
	else
		require "client/Chat/ISChat.lua"

		local chatMsg = {
			getTextWithPrefix = function(self)
				return self.msg
			end,

			getText = function(self)
				return self.msg
			end,

			isServerAlert = function() return true end,
			isShowAuthor = function() return false end,
			getAuthor = function() return "SERVER" end
		}
		
		chatMsg.__index = chatMsg

		function chat(...)
			local msg = table.concat({...}, "\t")
			ISChat.addLineInChat(setmetatable({ msg = msg }, chatMsg), 0)
		end
	end
end

function UpdatePLZ.minutes(secs)
	if secs < 60 then
		if secs == 1 then
			return secs .. " second"
		else
			return secs .. " seconds"
		end
	else
		if secs / 60 == 1 then
			return "1 minute"
		else
			return (string.gsub(string.gsub(string.format("%.2f", secs / 60), "(%.%d-)0*$", "%1"), "%.$", "")) .. " minutes"
		end
	end
end

local restartingAt
local nextChatPrint
local function countdown()
	local time = getTimestamp()
	local delta = restartingAt - time
	if not nextChatPrint or nextChatPrint - time <= 0 then
		nextChatPrint = time + math.min(delta / 2, 60 * 15)

		if math.floor(delta / 60) <= 0 then
			chat("WARNING: Server is restarting to update Workshop mods!")
			Events.OnTickEvenPaused.Remove(countdown)
		else
			chat("WARNING: Server is restarting in " .. UpdatePLZ.minutes(delta) .. " to update Workshop mods")
		end
	end
end

function UpdatePLZ.startRestartCountdown(__restartingAt)
	nextChatPrint = nil
	restartingAt = __restartingAt
	if restartingAt then
		Events.OnTickEvenPaused.Add(countdown)
	else
		Events.OnTickEvenPaused.Remove(countdown)
	end
end

if not isServer then
	Events.OnInitGlobalModData.Add(function()
		Events.OnReceiveGlobalModData.Add(function(key, modData)
			if key == "UpdatePLZ" then
				UpdatePLZ.startRestartCountdown(modData and modData.restartingAt or nil)
			end
		end)

		ModData.request("UpdatePLZ")
	end)
end