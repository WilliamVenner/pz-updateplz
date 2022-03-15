local getTimestamp = getTimestamp
local querySteamWorkshopItemDetails = querySteamWorkshopItemDetails
local getSteamWorkshopItemIDs = getSteamWorkshopItemIDs
local getOnlinePlayers = getOnlinePlayers
local getCore = getCore

if not getCore():isDedicated() then
	print("[UpdatePLZ] Refusing to load (this is not a dedicated server)")
	return
end

local serverStarted = getTimestamp()
local workshopOutdated = false

local function isServerEmpty()
	return getOnlinePlayers():size() == 0
end

local function rebootServer()
	print("[UpdatePLZ] Saving...")
	saveGame()

	print("[UpdatePLZ] Quitting...")
	getCore():quit()
end

local pollWorkshop do
	local fakeTable = {}
	function pollWorkshop()
		print("[UpdatePLZ] Checking for outdated Workshop items...")
		querySteamWorkshopItemDetails(getSteamWorkshopItemIDs(), function(_, status, info)
			if status ~= "Completed" then return end
			for i = 0, info:size() - 1 do
				local details = info:get(i)
				local updated = details:getTimeUpdated()
				if updated >= serverStarted then
					workshopOutdated = true
					print("[UpdatePLZ] Detected outdated Workshop item - restarting server when empty")
					return
				end
			end
		end, fakeTable)
	end
end

local function pollReboot()
	if not workshopOutdated then return end

	print("[UpdatePLZ] Restarting the server (server empty and outdated Workshop items were detected)")

	rebootServer()
end

do
	local nextPoll
	Events.OnTickEvenPaused.Add(function()
		if not isServerEmpty() then return end

		if workshopOutdated then
			return pollReboot()
		end

		local timestamp = getTimestamp()
		if not nextPoll or getTimestamp() > nextPoll then
			nextPoll = timestamp + 60
			return pollWorkshop()
		end
	end)
end

Events.OnDisconnect.Add(pollReboot)
Events.OnDisconnect.Add(pollWorkshop)

print("[UpdatePLZ] Loaded!")