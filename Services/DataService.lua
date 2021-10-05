-- Data Service2
-- McThor2
-- November 23, 2020

--[[
	
	Server:
		
	


	Client:
		
	

--]]

-- ================================= --


local MAIN_DATA_KEY = "PlayerData"
local PLAYER_DATA_PREFIX = "Data-"

local CHANGE_EVENT_NAME = "Changed"

local KICK_MESSAGE = "Profile was released, please rejoin. If this keeps occuring please contact a game dev (e.g. McThor2)"


-- ================================= --

local ProfileService, ProfileStore, DefaultData, ProfileWrapper, UpdateHandlers  -- DataObject

local DataService = {Client = {}}

local Players = game:GetService("Players")

local dataCache = {}

local initFlags = {}


local function notReleasedHandler()--place_id, game_job_id)
	return "ForceLoad"
end

local function onPlayerAdded(player)
	
	DataService:GetData(player)
	
end

local function onPlayerRemove(player)
	
	DataService:ReleaseData(player)
	
	if initFlags[player] then
		initFlags[player]:Destroy()
	end
	
end

local function clearCache(player)
	
	local cache = dataCache[player.Name]

	if cache then
		local data, connections = cache.Data, cache.Connections
		
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end
	
		data:Destroy()
		dataCache[player.Name] = nil
	end
	
end

local function handleLockedUpdate(profile, data, updateId, updateData)
	local updateType = updateData.Type

	if UpdateHandlers[updateType] then
		UpdateHandlers[updateType](data, updateId, updateData)
		profile.GlobalUpdates:ClearLockedUpdate(updateId)
	else
		warn("No update handler for:", updateType)
	end

	
end

function DataService:InitialiseCache(player)
	
	print("load call", player)

	local profile = ProfileStore:LoadProfileAsync(PLAYER_DATA_PREFIX..player.UserId, notReleasedHandler)

	repeat
		if profile then
			profile:Reconcile()
		else
			warn("no profile", player)
		end
		wait(0.1)
	until profile


	print("load finished", player, profile)


	local data = ProfileWrapper.new(profile, player)

	if player:IsDescendantOf(Players) then

		local releaseConnection = profile:ListenToRelease(function()
			if player then
				player:Kick(KICK_MESSAGE)
				clearCache(player)
			end	
		end)

		local activeUpdatesConnection = profile.GlobalUpdates:ListenToNewActiveUpdate(function(updateId) --, updateData)
			profile.GlobalUpdates:LockActiveUpdate(updateId)
		end)

		local lockedUpdatesConnection = profile.GlobalUpdates:ListenToNewLockedUpdate(function(updateId, updateData)
			handleLockedUpdate(profile, data, updateId, updateData)
		end)

		local changeConnection = data.Changed:Connect(function(key, value)
			self:FireClient(CHANGE_EVENT_NAME, player, key, value)
		end)

		local cache = {
			Data = data, 
			Connections = {	
				changeConnection, 
				releaseConnection, 
				activeUpdatesConnection, 
				lockedUpdatesConnection
			} 
		}

		dataCache[player.Name] = cache


		-- Add global updates handling here

		local lockedUpdates = profile.GlobalUpdates:GetLockedUpdates()

		for _, update in ipairs(lockedUpdates) do
			local updateId = update[1]
			local updateData = update[2]

			if profile:IsActive() then
				handleLockedUpdate(profile, data, updateId, updateData)
			end
		end

		local activeUpdates = profile.GlobalUpdates:GetActiveUpdates()

		for _, update in ipairs(activeUpdates) do
			local updateId = update[1]

			if profile:IsActive() then
				profile.GlobalUpdates:LockActiveUpdate(updateId)
			end
		end
		
		return cache
		
	else

		profile:Release()

	end
end

function DataService.Client:GetData(player)
	return self.Server:GetData(player)
end

function DataService.Client:Get(player, key)
	local data = self.Server:GetData(player)
	
	if data then

		return data:Get(key)

	end
end

function DataService:GetData(player)

	local cache = dataCache[player.Name]
	
	if not cache then
		
		-- add init flag table to make sure this is only called once per session for each player
		
		if not initFlags[player] then
			
			--print("init data")
			
			local event = Instance.new("BindableEvent")
			initFlags[player] = event
			
			cache = self:InitialiseCache(player)
			
			--print("done init")
			
			event:Fire()
			
		else
			
			--print("Wait for data")
			
			initFlags[player].Event:Wait()
			
			--print("data ready")
			
			cache = dataCache[player.Name]
			
		end
		
	end

	return cache.Data
	
end

function DataService:ReleaseData(player)
	
	local cache = dataCache[player.Name]
	
	if cache then
		local data = cache.Data
		local profile = data:GetProfile()
		
		profile:Release()
		
	end
end


function DataService:SendUpdate(userId, updateData)
	
	ProfileStore:GlobalUpdateProfileAsync(
		PLAYER_DATA_PREFIX .. userId,
		function(global_updates)
			global_updates:AddActiveUpdate(updateData)
		end
	)
	
end

function DataService:Start()
	
	DefaultData = require(script.DefaultData)
	UpdateHandlers = require(script.UpdateHandlers)
	
	ProfileStore = ProfileService.GetProfileStore(MAIN_DATA_KEY, DefaultData.Data)
	
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemove)
	
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
end


function DataService:Init()
	
	ProfileService = self.Modules.ProfileService
	ProfileWrapper = self.Modules.ProfileWrapper
	
	
	-- DataObject = self.Shared.DataObject
	
	self:RegisterClientEvent(CHANGE_EVENT_NAME)
	
end


return DataService