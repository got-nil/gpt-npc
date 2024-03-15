
---@class GPT.Promise: EventsMixin
local Promise = GNIL.Thirdparty.middleclass("Promise"):IncludeMixin(GNIL.ClassMixins.Events)

---Succeed promise with some resulting data.
---@param ... any
---@return boolean
function Promise:Success(...)
    if self._cancelled then return false end
    self:EmitSignal("resolve", ...)
    return true
end

---Reject promise with some error data.
---@param ... any
---@return boolean
function Promise:Error(...)
    if self._cancelled then return false end
    self:EmitSignal("reject", ...)
    return true
end

---Add signal listener for promise success.
---@param callback fun(...: any): nil
---@return self
function Promise:OnSuccess(callback)
    if self._cancelled then return self end
    self:AddSignalListener("resolve", callback)
    return self
end

---Add signal listener for promise rejection.
---@param callback fun(...: any): nil
---@return self
function Promise:OnError(callback)
    if self._cancelled then return self end
    self:AddSignalListener("reject", callback)
    return self
end

---Check if a promise has been cancelled.
---@return boolean
function Promise:IsCancelled()
    return self._cancelled == true
end

---Cancel promise, blocking its Success and Error methods from emitting signals.
function Promise:Cancel()
    self._cancelled = true
end

return {
    Promise = Promise
}