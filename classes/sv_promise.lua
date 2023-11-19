
local Promise = GNIL.ClassMixins.Promise
local CancellablePromise = GNIL.Thirdparty.middleclass("CancellablePromise")
    :IncludeMixin(GNIL.ClassMixins.Events)
    :IncludeMixin(Promise)

function CancellablePromise:IsCancelled()
    return self._cancelled == true
end

function CancellablePromise:Cancel()
    self._cancelled = true
end

---------------------------------------------------------
-- Wrap the original resolvers, ignoring the call
-- if we've already been cancelled. This is not a normal
-- CancellablePromise convention so its kept as a seperate class.

function CancellablePromise:OnSuccess(...)
    if self._cancelled then return end
    return Promise.OnSuccess(self, ...)
end

function CancellablePromise:OnError(...)
    if self._cancelled then return end
    return Promise.OnError(self, ...)
end

return {
    CancellablePromise = CancellablePromise
}