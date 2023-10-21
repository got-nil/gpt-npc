
local MODULE, Brain = MODULE, GNIL.Thirdparty.middleclass("Brain"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(Brain, {
	Gender = FuncAccessors.ReadOnly("_gender"),
	TTSParameters = FuncAccessors.ReadOnly("_tts_params"),
	History = FuncAccessors.ReadOnly("_history")
})

function Brain:Initialize(gender)
	self._history = GNIL.GPT.Classes.History:New()
	self._gender = gender
	self._tts_params = GNIL.GPT.Classes.TTSParameters:New(gender)
end

-- GPT -> TTS.
function Brain:Think(gpt_params, tts_params)

	assert(istable(gpt_params), "Provided gpt_params should be GPTParameters class instance.")
	assert(tts_params == nil or istable(tts_params), "Provided tts_params should be TTSParameters class instance or nil.")

	-- Start GPT task.
	local gpt = self:GPT(gpt_params)
	if not gpt then return false end
	local promise = GNIL.Thirdparty.middleclass("Promise"):IncludeMixin(GNIL.ClassMixins.Promise)

	-- Attach GPT task callbacks, either rejecting promise
	-- or starting TTS task to generate the mp3 URL.
	gpt:OnError(function(...)
		return promise:Error(...)
	end):OnSuccess(function(responseMessage)

		-- There should always be a valid response message in a
		-- success, but make sure again just incase.
		if not responseMessage then
			return promise:Error(GNIL_GPT_ERRORS_RESPONSE, "GPT did not return a valid response message")
		end

		-- Start TTS task.
		if not tts_params then tts_params = self._tts_params end
		local tts = self:TTS(responseMessage, tts_params)

		-- If the TTS taks fails, reject the promise.
		if not tts then
			return promise:Error("Could not start TTS task")
		end

		-- Attach TTS task callbacks, sending promise response.
		tts:OnError(function(...)
			return promise:Error(...)
		end):OnSuccess(function(...)
			return promise:Success({
				gpt = responseMessage,
				tts = {...}
			})
		end)
	end)

	return promise
end

function Brain:ClearHistory(steamid)
	if IsPlayer(steamid) then
		steamid = steamid:SteamID64()
	end
	assert(isstring(steamid), "Provided steamid must be a valid string")
	return self._history:Clear(steamid)
end

function Brain:GPT(gpt_params)

	local task = GNIL.GPT.Tasks.Create("gpt", gpt_params)
	if not task or not task:ValidateArguments() then return false end
	local original_messages = table.Copy(gpt_params:GetMessages())

	if istable(gpt_params._history_target) then

		local steamid, count = unpack(gpt_params._history_target)
		local history = self._history:GetHistory(steamid, count)

		-- If there is actually a message history with the
		-- provided steamid add some of the messages to the task.
		if history != nil then
			gpt_params._history_messages = history
		end
	end

	-- Add GPT assistant response to message history if the think
	-- parameters have a history target (user steamid to add to queue).
	task:OnSuccess(function(message)

		-- Only add messages if there was a successful response.
		-- Add original messages (pre-history insertion) to the brains
		-- history queue. This only applies to messages with an associated
		-- steamid64.
		for _, v in ipairs(original_messages) do
			if v.user == nil then continue end
			self._history:AddMessage(v.user, v)
		end

		-- If there is a history target, add the assistants response.
		if istable(gpt_params._history_target) then

			local steamid = gpt_params._history_target[1]
			self._history:AddMessage(steamid, {
				role = "assistant",
				content = message
			})
		end

	end):Run()

	return task
end

function Brain:TTS(text, tts_params)

	if not tts_params then
		tts_params = self._tts_params
	end

	local task = GNIL.GPT.Tasks.Create("tts", text, tts_params)
	if not task or not task:ValidateArguments() then return false end

	task:Run()
	return task
end

return {
	Brain = Brain
}