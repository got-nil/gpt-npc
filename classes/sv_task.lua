
---@class GPT.Task: GPT.Promise
local Task = GNIL.Thirdparty.middleclass("Task", GNIL.Net.Classes.Promise)

ClassAccessorFunc(Task, {
    ID = FuncAccessors.ReadOnly("_id"),
    Name = FuncAccessors.ReadOnly("_name"),
    Arguments = FuncAccessors.ReadOnly("_arguments"),
    Base = FuncAccessors.ReadOnly("_base")
})

function Task:Initialize(id, name, ...)
    self._id = id
    self._name = name
    self._arguments = {...}
    self._base = GNIL.GPT.Tasks.GetBase(name)

    assert(self._base != nil, "Provided task base '" .. name .. "' does not exist.")
end

---Validate task arguments against base.
---@return boolean SuccessState
function Task:ValidateArguments()

    -- If there is no validator function, accept anything.
    if not self._base.validate then
        return true
    end

    -- Call the base validator with the arguments
    -- from initial Task Initialization.
    local out = self._base.validate(
        unpack(self._arguments)
    )
    if not isbool(out) then
        return false
    end
    return out
end

-- TODO: Validate the arguments again here.
function Task:Run(ent) return GNIL.GPT.Tasks.Send(self) end
function Task:Remove() GNIL.GPT.Tasks.Remove(self) return self end

return {
    Task = Task
}