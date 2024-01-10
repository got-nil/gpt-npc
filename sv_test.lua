local MODULE = MODULE

-- ==========================================
-- ENSURE THIS FILE IS REMOVED BEFORE RELEASE
-- ==========================================

local function timePrefix()
    return "[" .. os.time() .. "] "
end

local function playURL(ply, url)
    if IsPlayer(ply) then
        ply:Execute([[
            sound.PlayURL("]] .. url .. [[", "mono", function(station)
                if IsValid(station) then
                    station:Play()
                else
                    GNIL.log("Invalid TTS station", "error")
                end
            end)
        ]])
    end
end

concommand.Add("gpt_test2", function()

    local brain = MODULE._static.brain

    local gpt_params = GNIL.GPT.Classes.GPTParameters:New()
        :AddMessage("hello there how are you?", "user")
        :SetSystemPrompt("balls")

    local tts_params = GNIL.GPT.Classes.TTSParameters:New()
        :SetProvider(GNIL_GPT_SPEECH_PROVIDER_ELEVENLABS)

    local out = brain:Think(gpt_params, tts_params)
    if not out then
        return MODULE:log("could not start GPT task")
    end

    out:OnSuccess(function(...)
        MODULE:log({t = "SUCCESS", args = {...}})
    end):OnError(function(state, msg)
        MODULE:log({t = "ERROR", state = state, msg = msg})
    end)
end)

concommand.Add("gpt_tts", function(ply, __, args)

    if #args == 0 then
        MODULE:log("Missing required text argument.")
        return
    end

    local brain = MODULE._static.brain

    -- Set provider
    brain:GetTTSParameters():SetProvider(
        GNIL_GPT_SPEECH_PROVIDER_GOOGLECLOUD
    )

    brain:TTS(args[1])
        :OnSuccess(function(url, data)

            MODULE:log({url, data})
            playURL(ply, url)

        end)
        :OnError(function(...) GNIL.log({"GPT_TTS_ERROR", {...}}) end)

end)

concommand.Add("gpt_record", function(ply, _, args)

    if not ply then
        MODULE:log("Can't be called from server console.")
        return
    end

    local recorder, userid = false, ply:UserID()
    if MODULE._static.recorders[tostring(userid)] then
        recorder = MODULE._static.recorders[tostring(userid)]
    else
        recorder = GNIL.GPT.Classes.Recorder:New(userid)
            :SetRaw(true)
            :OnSuccess(function(out)
                if recorder:IsRaw() then playURL(ply, out) end
                ply:log(timePrefix() .. "Record Out: " .. out)
            end)
            :OnError(function(_, errorMessage) ply:log(timePrefix() .. errorMessage, "error") end)

        MODULE._static.recorders[tostring(userid)] = recorder
    end

    if recorder:IsRecording() then

        -- End of recording.
        local cancelled = args[1] == "1"
        local out, _ = recorder:StopRecording(cancelled)
        ply:log(timePrefix() .. (out && "Successfully ended" || "Failed to end") .. " voice recording." .. (cancelled && " [CANCELLED]" || ""))

    else

        -- Start of recording.
        local recorderStart = recorder:StartRecording()
        ply:log(timePrefix() .. (recorderStart && "Successfully started" || "Failed to start") .. " voice recording.")
    end
end)

concommand.Add("gpt", function(ply, _, args)

    local brain = MODULE._static.brain

    assert(isstring(args[1]), "bad arg")
    local steamid = "console"

    local params = GNIL.GPT.Classes.GPTParameters:New()
        :AddMessage(args[1], "user", steamid)
        :SetHistory(steamid, 3)

    if args[2] then
        params:AddMessage(args[2], "system")
    end

    brain:GPT(params)
        :OnSuccess(function(message, data) MODULE:log(timePrefix() .. "GPT: " .. message) end)
        :OnError(function(_, errorMessage) MODULE:log(timePrefix() .. errorMessage, "error") end)

end)

function GNIL.GPT.Test()
    MODULE._static.brain = GNIL.GPT.Classes.Brain:New()
    MODULE._static.recorders = {}
end
