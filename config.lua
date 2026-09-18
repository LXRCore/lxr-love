--[[
    ██╗     ██╗  ██╗██████╗       ██╗      ██████╗ ██╗   ██╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██║     ██╔═══██╗██║   ██║██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██║     ██║   ██║██║   ██║█████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝██║     ██║   ██║╚██╗ ██╔╝██╔══╝
    ███████╗██╔╝ ██╗██║  ██║      ███████╗╚██████╔╝ ╚████╔╝ ███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚══════╝ ╚═════╝   ╚═══╝  ╚══════╝

    LXR Core - Love

    Paired interactions between two players, every one of them by consent:
    one asks, the other sees a card and says yes or no, and only then do
    both peds play. Hugs, a kiss on the cheek, a dance, a slap, and a
    proposal with a ring from the satchel. The server keeps the asking,
    the answering, the cooldowns and the pairing.

    ┌──────────────────────────────────────────────────────────────────────┐
    │ DISCLAIMER                                                           │
    │ This resource ships casual interactions only. An adult animation set │
    │ exists as a switch (Config.Adult.enabled) that is OFF by default and  │
    │ EMPTY by default: nothing of that kind is included here. A server    │
    │ operator who turns it on and fills it does so knowingly, is solely   │
    │ responsible for it, for their players' age verification, and for the │
    │ rules of the platforms and jurisdictions they run under. Consent     │
    │ cards cannot be bypassed by configuration.                           │
    └──────────────────────────────────────────────────────────────────────┘

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (interact options; a loop only while paired)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INTERACTIONS ══════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- Every interaction needs the other player's yes unless `consent = false` (the slap).
-- Animations: { dict, anim } for the one who asked (a) and the one who answered (b);
-- `offset` places b relative to a; `seconds` is how long it plays; `item` is taken
-- from the asker's satchel when the other says yes (the proposal's ring).
-- The animation names below are NOT VERIFIED against the game: a dictionary that
-- does not load is reported to both players and the interaction simply ends —
-- it never errors. Replace them with names from your own build.
Config.Interactions = {
    hug      = { consent = true,  seconds = 4,  offset = { x = 0.0, y = 0.55, z = 0.0, heading = 180.0 },
                 a = { dict = 'script_mp@emotes@greet@hug@a@male@unarmed@full', anim = 'full' }, b = { dict = 'script_mp@emotes@greet@hug@a@male@unarmed@full', anim = 'full' } },
    kiss     = { consent = true,  seconds = 3,  offset = { x = 0.0, y = 0.45, z = 0.0, heading = 180.0 },
                 a = { dict = 'script_mp@emotes@greet@kiss_cheek@a@male@unarmed@full', anim = 'full' }, b = { dict = 'script_mp@emotes@greet@kiss_cheek@a@male@unarmed@full', anim = 'full' } },
    dance    = { consent = true,  seconds = 20, offset = { x = 0.0, y = 0.8, z = 0.0, heading = 180.0 },
                 a = { dict = 'script_mp@emotes@dance@confident@b@male@unarmed@full', anim = 'full' }, b = { dict = 'script_mp@emotes@dance@confident@b@male@unarmed@full', anim = 'full' } },
    propose  = { consent = true,  seconds = 8,  offset = { x = 0.0, y = 0.9, z = 0.0, heading = 180.0 }, item = { 'ring_gold', 'ring_silver', 'ring_wedding' }, marks = true,
                 a = { dict = 'script_mp@emotes@react@kneel@a@male@unarmed@full', anim = 'full' }, b = nil },
    slap     = { consent = false, seconds = 2,  offset = nil,
                 a = { dict = 'script_mp@emotes@react@slap@a@male@unarmed@full', anim = 'full' }, b = { dict = 'script_mp@emotes@react@flinch@a@male@unarmed@full', anim = 'full' } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ADULT SET — OFF AND EMPTY BY DEFAULT ══════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- Read the disclaimer above. Entries use the same shape as Config.Interactions and
-- always require consent; `consent = false` is ignored here.
Config.Adult = { enabled = false, interactions = {} }

Config.Rules = {
    askTimeoutMs = 15000,        -- the card waits this long for an answer
    cooldownMs = 8000,           -- per player between interactions
    distance = 2.5,
    partnerMetadata = 'partner', -- the proposal writes the other's citizenid here (core metadata) when `marks`
}
Config.Security = { rateLimit = { windowMs = 2000, burst = 5 } }
Config.Debug = { printBanner = true, log = true }
