local MODULE = MODULE

--[[

    This file should probably be removed before any real "release"
    but I thought there might aswell be some proper debugging convar
    instead of having to change the code every time.

--]]

CreateConVar("gnil_gpt_ws_debuglogs", 0, FCVAR_UNLOGGED, "Should the GPT Websocket debug logs be enabled?", 0, 1)

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
            "https://cdn.morgverd.com/shx/files/UXLqaHnzdhqCvzO9vqnNwChKa.mp3",
            {
                ["length"] = 10.00,
                ["driver"] = "googlecloud",
                ["message"] = {
                    ["text"] = "Hello there how are you today? This is another test sentence for raptor to use when making the NPC audio sync. I wish you good luck, love you!",
                    ["timepoints"] = {
                        ["len"] = 28,
                        ["data"] = {
                            {"Hello",0.014999999664724},
                            {"there,",0.39129164814949},
                            {"how",0.958624958992},
                            {"are",1.1796666383743},
                            {"you",1.2346665859222},
                            {"today?",1.3801665306091},
                            {"This",2.1905000209808},
                            {"is",2.4639165401459},
                            {"another",2.5985832214355},
                            {"test",2.9031248092651},
                            {"sentence",3.2552914619446},
                            {"for",3.772958278656},
                            {"raptor",3.8754999637604},
                            {"to",4.3497915267944},
                            {"use",4.4897918701172},
                            {"when",4.8457913398743},
                            {"making",4.9959578514099},
                            {"the",5.3564162254333},
                            {"NPC",5.47962474823},
                            {"audio",6.1775407791138},
                            {"sync.",6.5948333740234},
                            {"I",7.7251658439636},
                            {"wish",7.8451662063599},
                            {"you",8.1041240692139},
                            {"good",8.2291240692139},
                            {"luck,",8.451623916626},
                            {"love",9.0252494812012},
                            {"you!",9.2918329238892},
                        }
                    }
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
    ws:AddEventListener("write", function(_, data)
        if not data then return end

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


function GNIL.GPT.SetupDebug()

    local Websocket = GNIL.GPT.Websocket
    if not Websocket then
        MODULE:log("Could not get reference to Websocket when attempting to setup debuggers.", "error")
        return
    end

    local convar = GetConVar("gnil_gpt_ws_debuglogs")
    local function shouldDebugLog()
        return convar:GetBool()
    end

    Websocket:AddSignalListener("write", function(_, data)
        if not shouldDebugLog() then return end
        MODULE:log({"WEBSOCKET_WRITE_TASK", data}, "debug")
    end)

    Websocket:AddSignalListener("receive_task", function(task, data)
        if not shouldDebugLog() then return end
        MODULE:log({"WEBSOCKET_RECEIVE_TASK", data}, "debug")
    end)

    if MODULE:Config():Get("ws_debug", false) then
        MODULE:log("Enabling websocket faker.", "debug")
        websocketFaker(GNIL.GPT.Websocket)
    end
end