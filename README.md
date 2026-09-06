# Unfinished GPT NPC for GMod

> [!WARNING]
> This addon was never finished and is being released as an archive. It isn't plug-and-play and is missing the server-side service it originally depended on.

This was an experiment for creating voice-interactive GPT NPCs in Garry's Mod.

The idea was fairly simple:

1. Capture player voice data using a modified version of [gm_8bit](https://github.com/Meachamp/gm_8bit).
2. Send the audio to an external service.
3. Transcribe it using Whisper.
4. Pass the transcription to GPT.
5. Send the response back into GMod for the NPC to use.

The GMod side got far enough to prove out the idea, but the backend quickly grew into a larger private gateway that ended up being used by several other projects. Because of that, I never went back and separated the GPT NPC-specific parts into something that could be released alongside this addon.

Hopefully I'll eventually get around to releasing a complete version, but for now this repository is mainly here as an archive of the original experiment.
