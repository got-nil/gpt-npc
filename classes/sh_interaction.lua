
-- the actual interaction passed between server and client.
-- the server sends updates about each interaction to subscribed clients.

--[[

creating interaction:
    initialized with the users message as text.

    this allows the input to be either from a recorder handled externally,
    or just from text input via chat/UI.

    an interaction is essentially a task executor.
    the end task can be set to either:
        GNIL_GPT_INTERACTION_TASK_GPT
        GNIL_GPT_INTERACTION_TASK_TTS (default)

    as each task progresses, these updates are sent to the client.

]]

local Interaction = GNIL.Thirdparty.middleclass("Interaction"):IncludeMixin(GNIL.ClassMixins.Events)
