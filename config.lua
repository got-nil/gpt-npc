return {
    realm = "server",
    shared = {
        "tts_url"
    },
    config = {

        default_system_prompt = "You're an NPC in a game, roleplaying as a human. Do not mention that you're an AI and remain in character.",

        relay_ip = "127.0.0.1",
        relay_port = 8765,

        tts_url = "https://gpt-gmod-fileserve-test.morgverd.direct",

        ws_debug = false,
        ws_host = "ws://127.0.0.1:8001/ws",
        ws_token = "Q9mhuLyNixEra4zkHUnfKbNujNfyQgMdn7g4bobnDVkXD5tRNPoqo5i3virPtFpAs5hhCfxjGNsDWKuHsCVVg6oSeVENiMkUKYgc4Kwfk6qyoakmJKd7dogYtPg3kFGr",
        ws_verify_cert = false

    }
}