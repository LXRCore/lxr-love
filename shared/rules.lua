--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-LOVE — Shared rules: the interaction book
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRLove = LXRLove or {}
local L = LXRLove

---Every enabled interaction, id → def, with adult entries forced to consent.
function L.Book()
    local out = {}
    for id, def in pairs(Config.Interactions) do out[id] = def end
    if Config.Adult and Config.Adult.enabled then
        for id, def in pairs(Config.Adult.interactions or {}) do
            local copy = {} for k, v in pairs(def) do copy[k] = v end
            copy.consent = true copy.adult = true
            out[id] = copy
        end
    end
    return out
end

function L.Get(id) return L.Book()[id] end

---Sorted ids for prompts and tests.
function L.Ids()
    local out = {}
    for id in pairs(L.Book()) do out[#out + 1] = id end
    table.sort(out)
    return out
end

---Does an interaction need the other's yes? (adult always does)
function L.NeedsConsent(id)
    local def = L.Get(id)
    return def ~= nil and (def.consent ~= false or def.adult == true)
end

---Which of the interaction's items the asker holds; count(name) → n. nil when none needed.
function L.ItemHeld(def, count)
    if not def.item then return nil, true end
    for _, n in ipairs(def.item) do if (count(n) or 0) > 0 then return n, true end end
    return nil, false
end

---Problems in the config (empty = healthy).
function L.Validate()
    local p = {}
    for id, def in pairs(L.Book()) do
        if not def.a or not def.a.dict or not def.a.anim then p[#p + 1] = id .. ': the asker needs { dict, anim }' end
        if def.b and (not def.b.dict or not def.b.anim) then p[#p + 1] = id .. ': the answerer needs { dict, anim }' end
        if not def.seconds or def.seconds <= 0 then p[#p + 1] = id .. ': seconds' end
        if def.item and #def.item == 0 then p[#p + 1] = id .. ': empty item list' end
    end
    return p
end
