local MODULE, Recorder = MODULE, GNIL.Thirdparty.middleclass("Recorder")
    :IncludeMixin(GNIL.ClassMixins.Events)
    :IncludeMixin(GNIL.ClassMixins.Promise)

ClassAccessorFunc(Recorder, {
    UserID = FuncAccessors.ReadOnly("_userid"),
    VoiceID = FuncAccessors.ReadOnly("_voice_id"),
    Task = FuncAccessors.ReadOnly("_task"),
    Recording = FuncAccessors.Boolean("_recording"),
    Raw = FuncAccessors.Boolean("_raw_recording")
})

--[[

    The Recorder implements the same promise interface as a Task
    meaning it should be basically interchangeable as a return
    value from the brain.

    It wraps the actual task "voice_relay" while also handling all
    the voice record state stuff.

--]]

local function sendWebsocketTask(self)

    -- Passthrough the relay task promises to recorder parent.
    self._task = GNIL.GPT.Tasks.Create("voice_relay", self)
        :OnSuccess(function(...) return self:Success(...) end)
        :OnError(function(...) return self:Error(...) end)
    :Run()

end

function Recorder:Initialize(userid)
    self._userid = userid
    self._voice_id = math.random(100000000, 999999999)
    self._recording = false
    self._task = false

    -- Recordings can optionally skip transcription, returning
    -- just the raw voice recording URL as an mp3 file.
    self._raw_recording = false
end

function Recorder:StartRecording()

    if self._recording then
        MODULE:log("Can't start recording as we've already started! (" .. self:__tostring() .. ")", "warning")
        return false
    end
    if not GNIL.GPT.Websocket:IsConnected() then
        MODULE:log("Could not start recording as the websocket is disconnected. (" .. self:__tostring() .. ")", "warning")
        return false
    end

    local started = GNIL.GPT.Voice.Start(
        self._userid,
        self._voice_id
    )
    if started then
        self._recording = true

        -- Send the websocket task so it doesn't reject the
        -- voice ID we're going to send eventually (recording end).
        sendWebsocketTask(self)
    end
    return started
end

function Recorder:StopRecording(cancelled)

    assert(cancelled == nil or isbool(cancelled), "Cancelled argument must either be nil or boolean.")
    if not self._recording then
        return false
    end

    local stopped = GNIL.GPT.Voice.Stop(
        self._userid,
        cancelled
    )
    if stopped then
        self._recording = false

        -- If the recording was cancelled, we have to manually
        -- call Error since the websocket would not reply.
        -- TODO: Delete the task_id on the API to prevent a buildup.
        if cancelled then self:Error(GNIL_GPT_ERRORS_CANCELLED, "The recording was cancelled") end
    end
    return stopped
end

function Recorder:ToTable()
    return {
        voice_id = tostring(self._voice_id),
        raw = self._raw_recording
    }
end

function Recorder:__tostring()
    return tostring(self._voice_id)
end

return {
    Recorder = Recorder
}