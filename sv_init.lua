local MODULE = MODULE

-- Use a local module config file with a validation structure.
MODULE.config = true
MODULE.config_structure = {
    ws_host = {nil, TYPE_STRING, true},
    ws_token = {nil, TYPE_STRING, true},
    ws_verify_cert = {true, TYPE_BOOL, false},
    tts_url = {false, TYPE_STRING, true},
    relay_ip = {nil, TYPE_STRING, true},
    relay_port = {nil, TYPE_NUMBER, true},
    default_system_prompt = {nil, TYPE_STRING, false}
}

--[[

    This module requires GWSockets dll and a connected GPT-API
    websocket server to process audio recording buffers since
    gmod does not have the capability to receive that raw data
    safely.

--]]

MODULE.OnInit = function()

    -- Require the gwsockets and eightbit modules.
    local modules = {
        ["gwsockets"] = "GWSockets",
        ["eightbit"] = "eightbit"
    }
    for k, v in pairs(modules) do
        local success, errorMessage = GNIL.Utils.RequireDLL(k, v)
        if not success then
            MODULE:log("Failed to load " .. k .. " with error: " .. errorMessage, "error")
            return false
        end
    end

    -- Make sure its the GPT build of eightbit.
    if not eightbit.IsRecording then
        MODULE:log("The module requires a modified build of eightbit.", "error")
        return false
    end
end

MODULE.OnLoad = function()

    -- Load all classes in directory.
    GNIL.GPT.Classes = GNIL.Loader.DirectoryMap(MODULE:ResolvePath("classes"))
    MODULE:log("Finished loading classes.", "debug")

    -- Add client files.
    MODULE.ClientLoad()
end

MODULE.OnLoadFinished = function()

    -- Load all base tasks and attempt first websocket connection.
    -- (the websocket will automatically attempt reconnections afterwards)
    -- (Don't log on successful connection since its already logged on the class)
    GNIL.GPT.Tasks.LoadAll()
    GNIL.GPT.Test()

    GNIL.GPT.Websocket:Open(function(state)
        if not state then
            MODULE:log("Websocket failed to connect, retrying.", "warning")
        end
    end)

    -- API connection state for NPC unavailable state.
    GNIL.GPT.Websocket:AddSignalListener("connected", function()
		SetGlobal2Bool("GPT.API.Active", true)
	end)
	GNIL.GPT.Websocket:AddSignalListener("disconnected", function()
		SetGlobal2Bool("GPT.API.Active", false)
	end)
end

MODULE.OnUnload = function()
    GNIL.GPT.Tasks.RemoveAll("GPT Module is being unloaded.", true)
end