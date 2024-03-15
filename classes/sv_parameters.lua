
---@class GPT.Parameters.TTS: middleclass
local TTSParameters = GNIL.Thirdparty.middleclass("TTSParameters")
ClassAccessorFunc(TTSParameters, {
    Provider = FuncAccessors.Enum("_provider", GNIL_GPT_SPEECH_PROVIDER_COUNT),
    Voice = {"_voice_id", FORCE_STRING},
    Gender = {
        var = "_gender",
        force = FORCE_STRING,
        nillable = true,
        validate = function(v)

            -- Controversial, I know.
            local acceptedGenders = {
                ["male"] = true,
                ["female"] = true
            }
            return v == nil or acceptedGenders[v] == true
        end
    }
})

function TTSParameters:Initialize(gender, voice_id, provider)
    if gender then self:SetGender(gender) end
    if voice_id then self:SetVoice(voice_id) end
    if provider then self:SetProvider(provider) end
end

---Convert TTSParameters to table.
---@return {provider: number, voice_id: string, gender?: string}
function TTSParameters:ToTable()
    return {
        provider = self._provider,
        voice_id = self._voice_id,
        gender = self._gender
    }
end

--------------------------------------------------------

---@class GPT.Parameters.GPT: middleclass
local GPTParameters = GNIL.Thirdparty.middleclass("GPTParameters")
ClassAccessorFunc(GPTParameters, {
    SystemPrompt = {
        var = "system_prompt",
        force = FORCE_STRING,
        nillable = true
    },
    Functions = FuncAccessors.ReadOnly("_functions"),
    Messages = FuncAccessors.ReadOnly("_messages")
})

function GPTParameters:Initialize(system_prompt)
    if system_prompt then
        assert(isstring(system_prompt), "Provided system prompt must be a string or nil")
        self.system_prompt = system_prompt
    end

    self._functions = {}
    self._messages = {} -- Newly written
    self._history_messages = {} -- Historic messages
    self._history_target = false
end

---Set the target history key for message.
---Only used if the task is passed through a brain.
---@param steamid Player|string
---@param count? number
---@return self
function GPTParameters:SetHistory(steamid, count)

    -- If a player is provided, convert it to a steam64id.
    if IsPlayer(steamid) then
        steamid = steamid:SteamID64()
    end

    assert(steamid, "Provided ply must be a valid Player")
    assert(count == nil or isnumber(count), "Provided count must be a number or nil")
    self._history_target = {steamid, count}
    return self
end

---Add GPT function.
---@param name string|{name: string, description: string, parameters: table}
---@param description? string
---@param parameters? table
---@param index? number
---@return self
function GPTParameters:AddFunction(name, description, parameters, index)

    -- Allow a table to be used as arguments instead.
    if istable(name) and description == nil and parameters == nil then
        name = name.name
        description = name.description
        parameters = name.parameters
    end

    assert(isstring(name), "Provided name must be a string")
    assert(isstring(description), "Provided description must be a string")
    assert(istable(parameters), "Provided parameters must be a table")
    assert(index == nil or isnumber(index), "Provided index must either null or a number")

    table.insert(self._functions, index or -1, {
        name = name,
        description = description,
        parameters = parameters
    })
    return self
end

---Add message to be provided as history to GPT.
---@param content string
---@param role? string
---@param steamid? string
---@return self
function GPTParameters:AddMessage(content, role, steamid)

    -- Default to user if there isn't a role provided.
    if not role then role = "user" end
    if role != "user" then steamid = nil end
    local validRoles = {
        ["user"] = true,
        ["assistant"] = true,
        ["system"] = true
    }

    assert(isstring(content), "Provided content must a string")
    assert(validRoles[role], "Provided user role must be valid")
    assert(steamid == nil or isstring(steamid), "Provided steamid must be nil or a string")

    table.insert(self._messages, {
        role = role,
        content = content,
        user = steamid
    })
    return self
end

---Convert GPTParameters to table.
---@return {messages: GPT.History.Message[], system_prompt: boolean|string, functions: table?}
function GPTParameters:ToTable()

    -- Old messages then new ones.
    local messages = Either(self._history_messages != nil, table.Copy(self._history_messages), {})
    for _, v in ipairs(self._messages) do
        table.insert(messages, {
            role = v.role,
            content = v.content
        })
    end

    return {
        messages = messages,
        system_prompt = Either(self.system_prompt, self.system_prompt, false),
        functions = Either(#self._functions > 0, self._functions, nil)
    }
end

return {
    TTSParameters = TTSParameters,
    GPTParameters = GPTParameters
}