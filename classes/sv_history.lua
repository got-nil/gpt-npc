
---@alias GPT.History.Message {role: string, content: string}

--[[

    History container, used by both server and client.
    Basically just a table but in a class that emits signals.

    Signals:
        newmessage (key: string, {role: string, content: string}) - New message for key being added.
        historyclear (key: string) - All history for provided key being cleared.
        historyclearall - All history being cleared.

--]]
---@class GPT.History: EventsMixin
---@field _messages table<string, GPT.History.Message[]>
local History = GNIL.Thirdparty.middleclass("History"):IncludeMixin(GNIL.ClassMixins.Events)

function History:Initialize()
    self._messages = {}
end

---Add a new message to history.
---@param key string History key. This is usually the players SteamID64.
---@param message_data GPT.History.Message
---@return boolean
function History:AddMessage(key, message_data)

    assert(isstring(key), "Provided history key must be a string.")
    assert(istable(message_data) and isstring(message_data.role) and isstring(message_data.content), "Provided message data must be a table with role and content strings.")

    -- Make sure the new message is formatted to
    -- remove any other data that may be added
    -- to the message_data. Also emit newmessage signal.
    local new_message = {
        role = message_data.role,
        content = message_data.content
    }

    self:EmitSignal("newmessage", key, new_message)
    if self._messages[key] == nil then self._messages[key] = {} end
    table.insert(self._messages[key], new_message)
    return true
end

---Clear all existing history for a given key.
---@param key string History key, usually a SteamID64.
---@return self
function History:Clear(key)
    assert(isstring(key), "Provided key must be a string, use ClearAll if you dont want a specific key.")
    self:EmitSignal("historyclear", key)
    self._messages[key] = nil
    return self
end

---Clear all existing history.
---@return self
function History:ClearAll()
    self:EmitSignal("historyclearall")
    self._messages = {}
    return self
end

---Get all existing history for a given key.
---@param key string History key, usually a SteamID64.
---@param limit? number Max amount of history.
---@return GPT.History.Message[]
function History:GetHistory(key, limit)

    assert(isstring(key), "Provided history key must be a string.")
    assert(limit == nil or isnumber(limit), "Provided limit must be nil or a number.")

    local messages = self._messages[key]
    if messages == nil then
        return {}
    end

    limit = Either(limit == nil, 3, math.abs(limit))
    return table.Slice(messages, math.max(1, #messages - limit), #messages)
end

return {
    History = History
}