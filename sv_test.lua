local MODULE = MODULE

-- Websocket faker.
local function websocketFaker(ws)

    local TTS_providers = {
        [GNIL_GPT_SPEECH_PROVIDER_ELEVENLABS] = {
            "https://cdn.morgverd.com/static/tests/gpt_npc/elevenlabs.mp3",
            {
                ["length"] = 0.83591836734694,
                ["driver"] = "elevenlabs",
                ["message"] = {
                    ["text"] = "Hello, this is an example elevencloud TTS output."
                }
            }
        },
        [GNIL_GPT_SPEECH_PROVIDER_GOOGLECLOUD] = {

            -- GOOGLE CLOUD TTS IS FUCKED RIGHT NOW FOR MY ACCOUNT.
            -- I HAVE LITERALLY NO IDEA WHY. FOR NOW, HERES ELEVENLABS INSTEAD.
            -- I'LL FIX THIS EVENTUALLY WHEN I CAN BE BOTHERED TO FUCK WITH THE
            -- GOOGLE CLOUD CONSOLE ENOUGH TO FIX THE BILLING ACCOUNT.

            "https://cdn.morgverd.com/static/tests/gpt_npc/elevenlabs.mp3",
            {
                ["length"] = 0.83591836734694,
                ["driver"] = "elevenlabs",
                ["message"] = {
                    ["text"] = "Hello, this is an example googlecloud TTS output.",
                    ["words"] = {"Hello,", "this", "is", "an", "example", "googlecloud", "TTS", "output."},
                    ["timepoints"] = {} -- TODO: Get the formatted data for this.
                }
            }
        }
    }

    local fakeTaskResponses = {
        ["voice_relay"] = {
            "This is the voice transcription message!",
            "transcription"
        },
        ["gpt"] = {
            "Hello there! How can I assist you today?",
            {
                ["object"] = "chat.completion",
                ["id"] = "chatcmpl-823LECcr4wrT49das0szx6V5inyEm",
                ["choices"] = {
                    [1] = {
                        ["finish_reason"] = "stop",
                        ["message"] = {
                            ["content"] = "Hello there! How can I assist you today?",
                            ["role"] = "assistant",
                        },
                        ["index"] = 0
                    }
                },
                ["model"] = "gpt-3.5-turbo-0613",
                ["created"] = 1695500192,
                ["usage"] = {
                    ["completion_tokens"] = 10,
                    ["total_tokens"] = 49,
                    ["prompt_tokens"] = 39
                }
            },
        },
        ["tts"] = function(data)
            local out = TTS_providers[tonumber(data.provider)]
            return {
                out[1],
                out[2]
            }
        end
    }

    -- Override the IsConnected function to act like
    -- the websocket is always connected.
    ws.IsConnected = function(self) return true end
    ws.Open = function(self, callback)
        if callback then callback(true) end
        return ws
    end

    -- Intercept messages being sent. Stop them from actually being queued (since the socket
    -- doesn't actually exist here) and instead directly resolve the task promise with fake data.
    ws:AddEventListener("write", function(message)

        local data = util.JSONToTable(message)
        if not data then MODULE:log("WS Faker could not decode write data.", "error") return end

        local fake = fakeTaskResponses[data.name]
        if not fake then MODULE:log("WS Faker invalid task name '" .. data.name .. "'", "error") return end
        if isfunction(fake) then fake = fake(data.data) end

        -- Actually finish the task on the next frame.
        timer.Simple(0, function()

            -- Call task response directly with message output.
            local task = GNIL.GPT.Tasks.GetTask(data.id)
            if not task then MODULE:log("WS Faker missing task ID!", "error") return end

            -- Call task success with the fake data, and stop message from being sent.
            task:Remove():Success(unpack(fake))
        end)

        return false
    end)

    return ws
end


-- =========================================
-- ENSURE THIS FILE IS REMOVED BEFORE GITHUB
-- =========================================

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
        local out = recorder:StopRecording(cancelled)
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

    if MODULE:Config():Get("ws_debug", false) then
        MODULE:log("Enabling websocket faker.", "debug")
        websocketFaker(GNIL.GPT.Websocket)
    end
end