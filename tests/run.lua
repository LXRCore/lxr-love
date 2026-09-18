--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-LOVE — Offline tests: the book, consent, the adult switch, items, locale parity
     Usage (from the lxr-love folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE) os.exit(2) end
local Shim = require('tests.lib.fxshim')
for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil Locale = nil
Shim.load('shared/locale.lua') Shim.load('locales/en.lua') Shim.load('locales/ka.lua') Shim.load('config.lua') Shim.load('shared/rules.lua')
local L = LXRLove

local passed, failed = 0, 0
local function test(name, fn) local okT, err = xpcall(fn, debug.traceback) if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-love offline tests')
test('the book is valid and labelled; the adult set ships off and empty', function()
    eq(#L.Validate(), 0, table.concat(L.Validate(), '; '))
    for _, id in ipairs(L.Ids()) do assert(Locale.Bundles.en['act.' .. id] and Locale.Bundles.en['ask.' .. id], 'labels for ' .. id) end
    eq(Config.Adult.enabled, false, 'adult set must ship off')
    eq(next(Config.Adult.interactions), nil, 'adult set must ship empty')
    assert(L.Get('hug') and L.Get('propose') and L.Get('slap'))
end)
test('consent: everything but the slap; adult entries always', function()
    assert(L.NeedsConsent('hug')) assert(L.NeedsConsent('propose')) assert(not L.NeedsConsent('slap')) assert(not L.NeedsConsent('nothing'))
    Config.Adult.enabled = true
    Config.Adult.interactions = { test_adult = { consent = false, seconds = 1, a = { dict = 'x', anim = 'y' } } }
    assert(L.NeedsConsent('test_adult'), 'adult entries cannot opt out of consent')
    assert(L.Get('test_adult').adult)
    Config.Adult.enabled = false Config.Adult.interactions = {}
    assert(L.Get('test_adult') == nil, 'off means gone')
end)
test('the proposal needs a ring from the catalog', function()
    local def = L.Get('propose')
    for _, n in ipairs(def.item) do assert(LXRShared.Items[n], n) end
    local item, held = L.ItemHeld(def, function(n) return n == 'ring_silver' and 1 or 0 end)
    eq(item, 'ring_silver') assert(held)
    local none, held2 = L.ItemHeld(def, function() return 0 end) assert(none == nil and not held2)
    local _, free = L.ItemHeld(L.Get('hug'), function() return 0 end) assert(free, 'a hug needs nothing')
end)
test('validate catches broken entries', function()
    local saved = Config.Interactions
    Config.Interactions = { bad = { seconds = 0, a = { dict = 'x' } } }
    assert(#L.Validate() >= 2)
    Config.Interactions = saved
end)
test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)
print(('%d passed, %d failed'):format(passed, failed))
if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'ask', payload = { id = 'dance', from = 4, name = 'Nino Kvaratskhelia', timeout = 15000 }, lang = Config.Lang, locale = Lang.bundle(), brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
