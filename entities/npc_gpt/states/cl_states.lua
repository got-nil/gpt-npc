local MODULE = MODULE

local function TestIconStub(icon)
    return {
        Icon = icon
    }
end

-- TEST STATES.

ENT.StateHandlers = {

    [GNIL_GPT_NPC_STATE_IDLE] = {

        TestIconStub = false

    },
    [GNIL_GPT_NPC_STATE_LISTENING]  = TestIconStub("Recording"),
    [GNIL_GPT_NPC_STATE_THINKING]   = TestIconStub("Brain"),
    [GNIL_GPT_NPC_STATE_SPEAKING]   = TestIconStub("Female"),
    [GNIL_GPT_NPC_STATE_BUSY]       = TestIconStub("Alert")

}