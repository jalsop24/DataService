-- Update Handlers
-- McThor2
-- January 14, 2021

--[[

UpdateHandlers.Gift = function(data, updateId, updateData)
	
end

--]]



local UpdateHandlers = {}


UpdateHandlers.Ban = function(data, updateId, updateData)
	
	data:Set("Ban", true)
	
	if data.Player then
		data.Player:Kick("Banned.")
	end
end

UpdateHandlers.Gems = function(data, updateId, updateData)
	
	local amount = updateData.Amount
	
	data:Update("Gems", function(old)
		return old + amount
	end)
	
end


return UpdateHandlers