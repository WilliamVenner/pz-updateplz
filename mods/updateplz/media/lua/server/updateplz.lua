local getTimestamp = getTimestamp
local querySteamWorkshopItemDetails = querySteamWorkshopItemDetails
local getSteamWorkshopItemIDs = getSteamWorkshopItemIDs
local getOnlinePlayers = getOnlinePlayers
local getCore = getCore

if not getCore():isDedicated() then
	print("[UpdatePLZ] Refusing to load (this is not a dedicated server)")
	return
end

UpdatePLZ = UpdatePLZ or {}

local serverStarted = getTimestamp()
local pendingReboot = false

function UpdatePLZ.setRestartDelaySeconds(delay)
	print("[UpdatePLZ] Restart delay set to " .. delay .. " seconds")
	UpdatePLZ.restartDelay = delay
end

local function isServerEmpty()
	return getOnlinePlayers():size() == 0
end

local rebootServer do
	local rebootingNow = false
	function rebootServer()
		if rebootingNow then return end
		rebootingNow = true

		print("[UpdatePLZ] Saving...")
		saveGame()

		print("[UpdatePLZ] Quitting...")
		getCore():quit()
	end
end

local restartingAt
local scheduleServerRestart do
	ModData.remove("UpdatePLZ")

	Events.OnInitGlobalModData.Add(function()
		if restartingAt then
			ModData.add("UpdatePLZ", { restartingAt = timestamp })
			ModData.transmit("UpdatePLZ")
		else
			ModData.remove("UpdatePLZ")
		end
	end)

	function scheduleServerRestart(timestamp)
		restartingAt = timestamp
		ModData.add("UpdatePLZ", { restartingAt = timestamp })
		ModData.transmit("UpdatePLZ")
		UpdatePLZ.startRestartCountdown(timestamp)
	end
end

local function rebootWhenEmpty()
	if pendingReboot and isServerEmpty() then
		rebootServer()
		Events.OnTickEvenPaused.Remove(rebootWhenEmpty)
	end
end

local function workshopOutdated()
	if pendingReboot then return end
	pendingReboot = true

	if isServerEmpty() then
		print("[UpdatePLZ] Restarting the server (server empty and outdated Workshop items were detected)")
		rebootServer()
		return
	end

	if UpdatePLZ.restartDelay then
		print("[UpdatePLZ] Detected outdated Workshop item - restarting server in " .. UpdatePLZ.minutes(UpdatePLZ.restartDelay))
		scheduleServerRestart(getTimestamp() + UpdatePLZ.restartDelay)
	else
		print("[UpdatePLZ] Restarting the server when it becomes empty... (outdated Workshop items were detected)")
		Events.OnTickEvenPaused.Add(rebootWhenEmpty)
	end
end

local pollWorkshop do
	local fakeTable = {}
	function pollWorkshop()
		if pendingReboot then return end
		
		print("[UpdatePLZ] Checking for outdated Workshop items...")

		querySteamWorkshopItemDetails(getSteamWorkshopItemIDs(), function(_, status, info)
			if status ~= "Completed" then return end
			for i = 0, info:size() - 1 do
				local details = info:get(i)
				local updated = details:getTimeUpdated()
				if updated >= serverStarted then
					workshopOutdated()
					return
				end
			end
		end, fakeTable)
	end
end
Events.OnDisconnect.Add(pollWorkshop)

local nextPoll
Events.OnTickEvenPaused.Add(function()
	if restartingAt then
		if isServerEmpty() then
			print("[UpdatePLZ] Restarting the server now! (Outdated Workshop items were detected and server is empty)")
			rebootServer()
		elseif restartingAt - getTimestamp() <= 0 then
			print("[UpdatePLZ] Restarting the server now! (Outdated Workshop items were detected)")
			rebootServer()
		end
		return
	end

	if pendingReboot then return end

	-- Don't bother checking for outdated Workshop items if there's no restart delay and the server has players on it
	if not UpdatePLZ.restartDelay and not isServerEmpty() then return end

	local timestamp = getTimestamp()
	if not nextPoll or getTimestamp() >= nextPoll then
		nextPoll = timestamp + 60
		return pollWorkshop()
	end
end)