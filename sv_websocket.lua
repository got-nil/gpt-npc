
local MODULE, GPTWebsocket = MODULE, GNIL.Thirdparty.middleclass("GPTWebsocket", GNIL.Classes.Websocket)

--[[

    receive_task:
        Signal sent when a task data response is being received
        by the socket. The response could still be error state here.

--]]

function GPTWebsocket:Initialize()

    -- Initialize base websocket connection.
    local conf = MODULE:Config()
    GNIL.Classes.Websocket.Initialize(
        self,
        conf:Get("ws_host"),
        conf:Get("ws_verify_cert", true)
    )

    -- Set auth header.
    self:SetHeader("Authorization", conf:Get("ws_token"))
end

function GPTWebsocket:OnMessage(message)

    local data = util.JSONToTable(message)
    if not data then
        MODULE:log("Websocket recieved an invalid message!", "debug")
        return
    end

    -- Get the message state and verify that the task identifier
    -- is present (isn't for generic errors or invalid data).
    local state = {
        id = data["id"],
        err = data["error"] == true,
        msg = data["msg"] && data["msg"] || "No error message was provided.",
        data = data["data"]
    }
    if state.id == nil then
        if state.err then MODULE:log("Websocket recieved generic error: " .. state.msg, "warning")
        else MODULE:log("Websocket sent a message without any task identifier.", "warning") end
        return
    end

    -- Get sent task object from identifier.
    local task = GNIL.GPT.Tasks.GetTask(state.id)
    if task == nil then
        MODULE:log("Websocket sent a task response for invalid task identifier '" .. state.id .. "'", "warning")
        return
    end

    -- Signal & Cancel the task now there has been a response.
    self:EmitSignal("receive_task", task, state)
    task:Remove()

    -- If its an error response, just call the error event directly
    -- instead of calling the response (since its a direct error).
    if state.err then
        task:Error(GNIL_GPT_ERRORS_RESPONSE, state.msg)
        return
    end

    -- Get task response and finally call success handler (or error).
    local success, out = task._base.response(task, state.data)
    if success then
        task:Success(unpack(out))
    else
        task:Error(GNIL_GPT_ERRORS_INVALID, out)
    end

    return
end

function GPTWebsocket:OnConnected()
    MODULE:log("Websocket connected successfully.", "debug")

    -- When the websocket is connected, try to load TTS voice data.
    -- TODO: Maybe don't always request the voices if there are alot.
    GNIL.GPT.Tasks.Create("tts_voices")
        :OnSuccess(function(data)

            MODULE:log("Cached " .. tostring(data.size) .. " TTS voices from websocket.", "debug")
            GNIL.GPT["_voices"] = data.voices

        end)
        :OnError(function()

            -- TODO: Re-queue task on failure?
            MODULE:log("Could not cache TTS voices.", "warning")

        end)
    :Run()

end

-- Cancel all pending sent tasks since a websocket disconnect
-- probably also means that the API state has reset.
function GPTWebsocket:OnDisconnected()
    MODULE:log("Websocket disconnected!", "debug")
    GNIL.GPT.Tasks.RemoveAll("Websocket has disconnected.", true)
end

GNIL.GPT.Websocket = GNIL.GPT.Websocket or GPTWebsocket:New()