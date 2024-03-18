local MODULE = MODULE
GNIL.GPT.Tasks = GNIL.GPT.Tasks or {
    ["_bases"] = {},
    ["_r"] = {}
}

---@alias GPT.Task.Base {name: string, response: function, request?: function, validate?: function}

---Send task request to websocket.
---@param task GPT.Task
---@param _queue_disconnected? boolean Should we queue the task if the websocket is disconnected?
---@return boolean SuccessState
function GNIL.GPT.Tasks.Send(task, _queue_disconnected)

    -- If the websocket is not connected, the task cannot
    -- be sent (unless _queue_disconnected is true)
    if not _queue_disconnected and not GNIL.GPT.Websocket:IsConnected() then
        return false
    end

    -- Allow the task base request to be optional for what are
    -- essentially websocket GET requests (eg: for voices).
    local success, data = true, nil
    if task._base.request then

        -- Get task request data from the base. The task base
        -- should always return a success state for outputs.
        success, data = task._base.request(
            task,
            unpack(task:GetArguments())
        )
        assert(isbool(success), "Task base '" .. task:GetBase().name .. "' returned an invalid success value")
        if not success then return false end
    end

    -- Send the request operation.
    GNIL.GPT.Tasks["_r"][task._id] = task
    GNIL.GPT.Websocket:Write({
        id = task._id,
        name = task._name,
        data = data
    })

    return success
end

---Remove a task from sent registry. This is for when a
---task has been replied to or cancelled.
---@param task GPT.Task
function GNIL.GPT.Tasks.Remove(task)
    GNIL.GPT.Tasks["_r"][task._id] = nil
end

---Remove all pending sent tasks, sending an Error with the
---given reason for each. Called when websocket disconnects.
---@param reason? string
---@param _should_log? boolean Should we log this cancellation?
---@return number RemovedTasksCount
function GNIL.GPT.Tasks.RemoveAll(reason, _should_log)

    -- Call the promise error on each sent task.
    local reason, i = Either(isstring(reason), reason, "All tasks were cancelled without reason."), 0
    for _, v in pairs(GNIL.GPT.Tasks["_r"]) do
        v:Error(GNIL_GPT_ERRORS_CANCELLED, reason)
        i = i + 1
    end
    if i > 0 then
        GNIL.GPT.Tasks["_r"] = {}
    end
    if _should_log then
        MODULE:log("Cancelled " .. tostring(i) .. " tasks with reason: " .. reason, "debug")
    end
    return i
end

---Load all base tasks.
function GNIL.GPT.Tasks.LoadAll()
    local files, _ = MODULE:Find("tasks/*.lua")
    if not files then
        MODULE:log("Could not find GPT task bases!", "error")
        return
    end
    for _, v in ipairs(files) do

        -- Include the task to get table.
        local task_out = MODULE:Include("tasks/" .. v)
        if not istable(task_out) then
            MODULE:log("Invalid task return value for '" .. v .. "'.", "warning")
            continue
        end

        -- Validate the task table structure.
        local success, task_out = GNIL.Validation.Structure(task_out, {
            name = {nil, TYPE_STRING, true},
            response = {nil, TYPE_FUNCTION, true},
            request = {nil, TYPE_FUNCTION},
            validate = {nil, TYPE_FUNCTION}
        })
        if not success then
            MODULE:log("Invalid task return structure for '" .. v .. "' with reason: " .. task_out .. ".", "warning")
            continue
        end

        MODULE:log("Loaded base task '" .. task_out.name .. "' from '" .. v .. "'.", "debug")
        GNIL.GPT.Tasks["_bases"][task_out.name] = task_out
    end
end

---Get a task base by name.
---@param name string
---@return GPT.Task.Base?
function GNIL.GPT.Tasks.GetBase(name) return GNIL.GPT.Tasks["_bases"][name] end

---Get a task by ID.
---@param task_id string
---@return GPT.Task
function GNIL.GPT.Tasks.GetTask(task_id) return GNIL.GPT.Tasks["_r"][task_id] end

---Create a task with a unique ID.
---@param name any
---@param ... any Task constructor arguments.
---@return GPT.Task?
function GNIL.GPT.Tasks.Create(name, ...)

    -- Keep generating until a taskid is found that doesn't yet exist.
    -- (since technically there is a small chance of duplicates)
    local task_id = nil
    while true do
        task_id = GNIL.Utils.Random(12)
        if GNIL.GPT.Tasks["_r"][task_id] == nil then
            break
        end
    end

    -- Ensure that the task base also exists.
    if GNIL.GPT.Tasks.GetBase(name) == nil then
        return nil
    end
    return GNIL.GPT.Classes.Task:New(task_id, name, ...)
end