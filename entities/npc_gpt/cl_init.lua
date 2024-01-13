
function ENT:Initialize()
    self._word_drivers = {}
end

function ENT:OnRemove()

    -- Stop all associated word drivers and stop playing any voices.
    for _, v in pairs(self._word_drivers) do
        v:Stop(true)
    end
    if self.Voice != nil and IsValid(self.Voice) then
        self.Voice:Stop()
    end

end
