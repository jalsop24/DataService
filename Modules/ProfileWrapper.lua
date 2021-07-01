-- Profile Wrapper
-- McThor2
-- November 23, 2020

--[[
	

--]]



local ProfileWrapper = {}

ProfileWrapper.__index = ProfileWrapper

local function copyTable(tab)
	assert(type(tab) == "table", "First argument must be a table")
	local tCopy = table.create(#tab)
	for k,v in pairs(tab) do
		if (type(v) == "table") then
			tCopy[k] = copyTable(v)
		else
			tCopy[k] = v
		end
	end
	return tCopy
end

function ProfileWrapper.new(profile, player)
	
	local new = {}
	
	new._profile = profile
	new._event = Instance.new("BindableEvent")
	new.Player = player
	new.Changed = new._event.Event
	
	setmetatable(new, ProfileWrapper)
	
	return new
	
end

function ProfileWrapper:GetProfile()
	return self._profile
end

function ProfileWrapper:Get(key)
	assert(key ~= "_profile", "Key cannot be _profile", debug.traceback())
	assert(key ~= "_event", "Key cannot be _event", debug.traceback())
	assert(key ~= "Changed", "Key cannot be Changed", debug.traceback())
	if key == nil then
		local newTab = copyTable(self._profile.Data)
		
		return newTab
	else
		return self._profile.Data[key]
	end
	
end

function ProfileWrapper:Set(key, value)
	assert(key ~= "_profile", "Key cannot be _profile", debug.traceback())
	assert(key ~= "_event", "Key cannot be _event", debug.traceback())
	assert(key ~= "Changed", "Key cannot be Changed", debug.traceback())
	if self._profile:IsActive() then
		self._profile.Data[key] = value
		self._event:Fire(key, value)
	end
end

function ProfileWrapper:Update(key, func)
	self:Set(key, func(self._profile.Data[key]))
end

function ProfileWrapper:Destroy()
	self._event:Destroy()
	self = nil
end

return ProfileWrapper