local MODULE = MODULE

local function TestIconStub(icon)
    return {
        Icon = icon
    }
end

-- TEST STATES.

surface.CreateFont("MassiveText", {
    font = "Roboto-Bold",
    size = 1200
})

ENT.StateHandlers = {

    [GNIL_GPT_NPC_STATE_IDLE]       = {

        Icon = "speaker"
    
    },

    [GNIL_GPT_NPC_STATE_LISTENING]  = TestIconStub("microphone"),
    [GNIL_GPT_NPC_STATE_THINKING]   = TestIconStub("brain"),
    [GNIL_GPT_NPC_STATE_SPEAKING]   = TestIconStub("speaker"),
    [GNIL_GPT_NPC_STATE_BUSY]       = TestIconStub("alert")

}