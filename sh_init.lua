
MODULE.name = "GPT NPCs"
MODULE.author = {"morgverd", "virtualraptor"}
MODULE.description = "Voice Interactable NPC base using GPT."

MODULE:RequireModule("net")
MODULE:RequireExtension("net")

GNIL.GPT = GNIL.GPT or {
    Classes = {},
    Interaction = {},
    Recording = {},
    Mute = {},
    Input = {},
    Output = {},
    Subtitles = {}
}

-- Called by both server and client.
MODULE.SharedLoad = function()

	-- Load all classes in directory.
	GNIL.GPT.Classes = GNIL.Loader.DirectoryMap(MODULE:ResolvePath("classes"))
	MODULE:log("Finished loading classes.", "debug")

    -- Load client files.
    MODULE:Include("client/cl_scalescreen.lua")
    MODULE:IncludeDirectory("client", {"cl_scalescreen.lua"})
    MODULE:IncludeDirectory("thirdparty")

    -- Load the NPC entities.
    MODULE:LoadDirectories("entities")
end

-- GPT error enums.
GNIL_GPT_ERRORS_CANCELLED = 1
GNIL_GPT_ERRORS_RESPONSE = 2
GNIL_GPT_ERRORS_INVALID = 3
GNIL_GPT_ERRORS_COUNT = 3
