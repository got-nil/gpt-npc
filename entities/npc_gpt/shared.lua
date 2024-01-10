local MODULE = MODULE

ENT.GPTNPC = true -- Identifier
ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PrintName = "AI Chatbot"
ENT.Author = "morgverd"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.State = 0
ENT.StateHandlers = ENT.StateHandlers or {}

ENT.IconMaterialPaths = {

    ["Alert"]       = "gpt-npc/images/alert.png",
    ["Brain"]       = "gpt-npc/images/brain.png",
    ["Female"]      = "gpt-npc/images/female.png",
    ["Male"]        = "gpt-npc/images/male.png",
    ["Recording"]   = "gpt-npc/images/recording.png"

}

ENT.Config = {
    RecorderTimeout = 20,
    NearbySearchRadius = 200,
    CancelRadiusSqr = 500 ^ 2
}

-------------------------------------------------------------------------

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "NetState")
    self:NetworkVar("Int", 1, "Age")
    self:NetworkVar("String", 0, "DisplayName")
    self:NetworkVar("Entity", 0, "ListeningTarget")

    -- On client make sure we're calling the normal SetState
    -- so the ExitState and EnterState is actually called.
    if CLIENT then
        self:NetworkVarNotify("NetState", function(self, _, __, new)
            if not IsValid(self) then
                return
            end
            self:SetState(new)
        end)
    end
end

-------------------------------------------------------------------------

function ENT:GetState()
    if CLIENT and self.State == 0 then
        return self:GetNetState()
    end
    return self.State
end

function ENT:SetState(state, ...)

    -- Exit the current state.
    self:RunStateHandler("ExitState", state)

    -- Set the new state.
    self.State = state
    if SERVER then
        self:SetNetState(state)
    end

    -- Call EnterState for state setup.
    self:RunStateHandler("EnterState", ...)
end

-------------------------------------------------------------------------

function ENT:GetStateHandler()
    return self.StateHandlers[self:GetState()]
end

function ENT:RunStateHandler(name, ...)
    local handler = self:GetStateHandler()
    if handler == nil then
        return false
    end
    local fn = handler[name]
    if isfunction(fn) then
        fn(self, ...)
        return true
    end
    return false
end

-------------------------------------------------------------------------

function ENT:ChatMessage(chatMessage)

    if CLIENT then
        local ply = LocalPlayer()
        if not IsValid(ply) then
            return
        end
        ply:PrintMessage(HUD_PRINTTALK, chatMessage)
    else

        -- As the server, find all players near to the NPC and
        -- use the net lib ChatMessage to send the messages.
        for _, v in ipairs(self:FindNearbyPlayers()) do
            v:ChatMessage(chatMessage)
        end
    end
end

-- This is called when something goes wrong in the NPC.
function ENT:HandleError(errorMessage)

    self:ChatMessage("Encountered unexpected error: " .. errorMessage)

    -- Lock the NPC in a busy state for 5 seconds so the
    -- user has a little bit of time to acknowledge the error.
    if SERVER then
        self:SetState(GNIL_GPT_NPC_STATE_BUSY)
        timer.Simple(5, function()
            if not IsValid(self) then
                return
            end
            self:SetState(GNIL_GPT_NPC_STATE_IDLE)
        end)
    end
end

-------------------------------------------------------------------------

for _, realm in pairs(SERVER && {"sv", "cl"} || {"cl"}) do
    MODULE:Include("entities/npc_gpt/states/" .. realm .. "_states.lua")
end
MODULE:IncludeDirectory("entities/npc_gpt/client")
