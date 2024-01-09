
MODULE.name = "GPT NPCs"
MODULE.author = "morgverd"
MODULE.description = {
    "Voice Interactable NPC base using GPT.",
    [[
        Special thanks to Virtualraptor who helped massively in
        general lua advice, creating the initial NPC prototypes
        and giving me random API design inspiration (used in this module).
    ]]
}

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