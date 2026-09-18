--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-LOVE — Server: the asking, the answer, the pairing
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local L = LXRLove
local RES = GetCurrentResourceName()
local asks, cooldown, buckets = {}, {}, {}   -- asks[target] = { from, id, at, item }

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function nameOf(P) local c = P.PlayerData.charinfo or {} return ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', '') end
local function near(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    return pa ~= 0 and pb ~= 0 and #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= Config.Rules.distance
end
local function free(src)
    local st = Player(src).state
    return not st.dead and not st.cuffed and not st.tied and not st.loving
end
local function cool(src) return GetGameTimer() - (cooldown[src] or 0) < Config.Rules.cooldownMs end

local function play(a, b, id, def, item)
    cooldown[a], cooldown[b] = GetGameTimer(), GetGameTimer()
    Player(a).state:set('loving', b, true) Player(b).state:set('loving', a, true)
    TriggerClientEvent('lxr-love:client:play', a, id, 'a', b)
    TriggerClientEvent('lxr-love:client:play', b, id, 'b', a)
    SetTimeout(def.seconds * 1000 + 500, function() Player(a).state:set('loving', false, true) Player(b).state:set('loving', false, true) end)
    if def.marks and Config.Rules.partnerMetadata then
        local PA, PB = player(a), player(b)
        if PA and PB then PA.Functions.SetMetaData(Config.Rules.partnerMetadata, PB.PlayerData.citizenid) PB.Functions.SetMetaData(Config.Rules.partnerMetadata, PA.PlayerData.citizenid) end
    end
    LXRCore.Emit('lxr:love:played', nil, a, b, id, item)
    if Config.Debug.log then LXRCore.Log.info('love', ('%s: %d ↔ %d%s'):format(id, a, b, item and (' (' .. item .. ')') or ''), { source = a }) end
end

LXR.RPC.Register('lxr-love:ask', function(src, id, target)
    if limited(src) then return false, 'rate' end
    local def = L.Get(id)
    local T = tonumber(target)
    local PA, PB = player(src), T and player(T)
    if not def or not PA or not PB or T == src then return false, 'invalid' end
    if not near(src, T) then return false, 'too_far' end
    if not free(src) or not free(T) then return false, 'busy' end
    if cool(src) then return false, 'cooldown' end
    local item, held = L.ItemHeld(def, function(n) return LXRCore.Inventory.GetItemCount(src, n) end)
    if not held then return false, 'no_item' end
    if not L.NeedsConsent(id) then
        play(src, T, id, def, nil)
        return true, 'done'
    end
    if asks[T] then return false, 'asked' end
    asks[T] = { from = src, id = id, at = GetGameTimer(), item = item }
    TriggerClientEvent('lxr-love:client:ask', T, { id = id, from = src, name = nameOf(PA), timeout = Config.Rules.askTimeoutMs })
    SetTimeout(Config.Rules.askTimeoutMs, function()
        local a = asks[T]
        if a and a.from == src and GetGameTimer() - a.at >= Config.Rules.askTimeoutMs - 50 then asks[T] = nil TriggerClientEvent('lxr-love:client:ask', T, nil) LXRCore.Notify(src, Lang:t('info.no_answer'), 'info') end
    end)
    return true, 'asked'
end)

LXR.RPC.Register('lxr-love:answer', function(src, yes)
    if limited(src) then return false, 'rate' end
    local a = asks[src]
    if not a then return false, 'invalid' end
    asks[src] = nil
    local from = a.from
    if not yes then LXRCore.Notify(from, Lang:t('info.declined'), 'info') LXRCore.Emit('lxr:love:declined', nil, from, src, a.id) return true, 'declined' end
    local def = L.Get(a.id)
    local PA = player(from)
    if not def or not PA or not GetPlayerName(from) then return false, 'gone' end
    if not near(from, src) then LXRCore.Notify(from, Lang:t('error.too_far'), 'error') return false, 'too_far' end
    if not free(from) or not free(src) then return false, 'busy' end
    if a.item then
        if not PA.Functions.RemoveItem(a.item, 1, nil, 'love:' .. a.id) then return false, 'no_item' end
        local PB = player(src)
        if PB then PB.Functions.AddItem(a.item, 1, nil, nil, 'love:' .. a.id) end
    end
    play(from, src, a.id, def, a.item)
    return true, 'played'
end)

RegisterNetEvent('lxr-love:server:missing', function(id, dict)
    local src = source
    local other = Player(src).state.loving
    LXRCore.Notify(src, Lang:t('error.missing_anim', { dict = tostring(dict) }), 'warning', 6000)
    if other and GetPlayerName(other) then LXRCore.Notify(other, Lang:t('error.missing_anim', { dict = tostring(dict) }), 'warning', 6000) end
    LXRCore.Log.info('love', ('animation missing for %s: %s'):format(tostring(id), tostring(dict)), { source = src })
end)

AddEventHandler('playerDropped', function() asks[source] = nil cooldown[source] = nil buckets[source] = nil for t, a in pairs(asks) do if a.from == source then asks[t] = nil TriggerClientEvent('lxr-love:client:ask', t, nil) end end end)
CreateThread(function()
    for _, p in ipairs(L.Validate()) do print('^3[lxr-love]^7 config: ' .. p) end
    if Config.Debug.printBanner then print(('^1[lxr-love]^7 v%s — %d interactions%s'):format(GetResourceMetadata(RES, 'version', 0), #L.Ids(), (Config.Adult and Config.Adult.enabled) and ' (adult set ON — operator responsibility)' or '')) end
end)
exports('IsPaired', function(src) return Player(src).state.loving ~= nil and Player(src).state.loving ~= false end)
