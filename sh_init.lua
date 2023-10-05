
MODULE.name = "GPT NPCs"
MODULE.author = {"morgverd", "virtualraptor"}
MODULE.description = "Voice Interactable NPC base using GPT."

MODULE:RequireModule("net")
MODULE:RequireExtension("net")

GNIL.GPT = GNIL.GPT or {}

-- Called by both server and client.
MODULE.ClientLoad = function()
    
    MODULE:Include("client/cl_scalescreen.lua")
    MODULE:IncludeDirectory("client", {"cl_scalescreen.lua"})
    MODULE:IncludeDirectory("thirdparty")

    -- Finally, add the actual NPC entities.
    MODULE:LoadDirectories("entities")
end

-- GPT error enums.

GNIL_GPT_ERRORS_CANCELLED = 1
GNIL_GPT_ERRORS_RESPONSE = 2
GNIL_GPT_ERRORS_COUNT = 2
