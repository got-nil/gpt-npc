
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

    -- Load the enums before anything else.
    MODULE:Include("sh_enums.lua")

    -- Load client files & Load the NPC entities.
    MODULE:IncludeDirectory("thirdparty")
    MODULE:LoadDirectories("entities")
end