local MODULE, Recorder = MODULE, GNIL.Thirdparty.middleclass("Recorder")
    :IncludeMixin(GNIL.ClassMixins.Events)
    :IncludeMixin(GNIL.ClassMixins.Promise)

ClassAccessorFunc(Recorder, {
    UserID = FuncAccessors.ReadOnly("_userid"),
    VoiceID = FuncAccessors.ReadOnly("_voice_id"),
    Task = FuncAccessors.ReadOnly("_task"),
    Recording = FuncAccessors.Boolean("_recording"),
    Raw = FuncAccessors.Boolean("_raw_recording"),
    Timeout = FuncAccessors.NumberMinMax("_timeout", 0, nil, {
        nillable = true
    })
})

--[[

    The Recorder implements the same promise interface as a Task
    meaning it should be basically interchangeable as a return
    value from the brain.

    It wraps the actual task "voice_relay" while also handling all
    the voice record state stuff.

--]]

local function sendWebsocketTask(self)

    -- When we get a response from the voice_relay, cancel the
    -- recorder if its still "recording". This should not happen,
    -- so its only there just incase something goes wrong.
    local cancelRecording = function()
        if self:IsRecording() then
            self:StopRecording(true)
        end
    end

    -- Passthrough the relay task promises to recorder parent.
    self._task = GNIL.GPT.Tasks.Create("voice_relay", self)
        :OnSuccess(function(...) cancelRecording() return self:Success(...) end)
        :OnError(function(...)

            -- Don't raise the error if we've already raised some other error.
            -- This prevents timeout cancellations from calling twice.
            if self._errored then return end
            cancelRecording()
            return self:Error(...)
        end)
    :Run()

end

local function startTimeout(self, timeout)

    -- Make sure we only have one timer per recorder.
    timer.Create("gnil_recorder_timeout_" .. self._voice_id, timeout, 1, function()

        -- If we're still recording when we've timedout then
        -- cancel it and raise a timeout error.
        if self._recording then

            self._errored = true
            self:StopRecording(true, true)
            self:Error(GNIL_GPT_ERRORS_TIMEOUT, "The recorder has timedout.")
        end
    end)
end

function Recorder:Initialize(userid)
    self._userid = userid
    self._voice_id = GNIL.GPT.Voice.GenerateID()
    self._recording = false
    self._task = false
    self._start_time = false
    self._timeout = false
    self._errored = false

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
        self._start_time = SysTime()

        -- If there is a timeout set, actually try to apply it.
        if self._timeout then
            startTimeout(self, self._timeout)
        end

        -- Send the websocket task so it doesn't reject the
        -- voice ID we're going to send eventually (recording end).
        sendWebsocketTask(self)
    end
    return started
end

-- Returns: runtime: float
function Recorder:GetRuntime()
    if not self._start_time then
        return 0.00
    end
    return SysTime() - self._start_time
end

-- Returns: stopped: bool, runtime: bool|float
function Recorder:StopRecording(cancelled, _no_error)

    assert(cancelled == nil or isbool(cancelled), "Cancelled argument must either be nil or boolean.")
    if not self._recording then
        return false
    end

    local runtime, stopped = false, GNIL.GPT.Voice.Stop(
        self._userid,
        cancelled
    )
    if stopped then
        self._recording = false

        -- Get the recording runtime, and reset start time.
        runtime = self:GetRuntime()
        self._start_time = false

        -- If the recording was cancelled, we have to manually
        -- call Error since the websocket would not reply.
        -- TODO: Delete the task_id on the API to prevent a buildup.
        if cancelled and not _no_error then self:Error(GNIL_GPT_ERRORS_CANCELLED, "The recording was cancelled") end
    end
    return stopped, runtime
end

function Recorder:ToTable()
    return {
        voice_id = self._voice_id,
        raw = self._raw_recording
    }
end

function Recorder:__tostring()
    return self._voice_id
end

return {
    Recorder = Recorder
}