--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-LOVE — Client: the options on a person, the consent card, the pair
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local L = LXRLove
local pending = nil

local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end
local function page(action, payload) SendNUIMessage({ action = action, payload = payload, brand = LXRCore.Brand, lang = Config.Lang, locale = Lang.bundle() }) end
local function serverIdOf(ped) return GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)) end

local function loadDict(dict)
    RequestAnimDict(dict)
    local t = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
    return HasAnimDictLoaded(dict)
end

RegisterNetEvent('lxr-love:client:play', function(id, side, other)
    local def = L.Get(id)
    if not def then return end
    local me = def[side]
    local ped = PlayerPedId()
    local otherPed = GetPlayerPed(GetPlayerFromServerId(other))
    if def.offset and otherPed and otherPed ~= 0 then
        if side == 'b' then
            local o = def.offset
            local pos = GetOffsetFromEntityInWorldCoords(otherPed, o.x, o.y, o.z)
            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
            SetEntityHeading(ped, (GetEntityHeading(otherPed) + (o.heading or 180.0)) % 360.0)
        else
            TaskTurnPedToFaceEntity(ped, otherPed, 500) Wait(500)
        end
    end
    if not me then return end
    if not loadDict(me.dict) then TriggerServerEvent('lxr-love:server:missing', id, me.dict) return end
    TaskPlayAnim(ped, me.dict, me.anim, 2.0, -2.0, def.seconds * 1000, 1, 0.0, false, false, false)
    Wait(def.seconds * 1000)
    StopAnimTask(ped, me.dict, me.anim, 1.0)
    RemoveAnimDict(me.dict)
end)

RegisterNetEvent('lxr-love:client:ask', function(ask)
    pending = ask
    if ask then page('ask', ask) else page('hide') end
end)

local function answer(yes)
    if not pending then return end
    pending = nil
    page('hide')
    local ok, res = LXR.RPC.Server('lxr-love:answer', yes)
    if not ok and res ~= 'invalid' then toast('error.' .. tostring(res), 'error') end
end
RegisterCommand('love_yes', function() answer(true) end, false)
RegisterCommand('love_no', function() answer(false) end, false)
RegisterKeyMapping('love_yes', 'Say yes', 'keyboard', 'Y')
RegisterKeyMapping('love_no', 'Say no', 'keyboard', 'N')

CreateThread(function()
    while GetResourceState('lxr-interact') ~= 'started' do Wait(1000) end
    local options = {}
    for _, id in ipairs(L.Ids()) do
        local def = L.Get(id)
        options[#options + 1] = { label = Lang:t('act.' .. id), key = 'J', canInteract = function(e) return e and not LocalPlayer.state.loving and not pending end, onSelect = function(d)
            local target = d.entity and serverIdOf(d.entity)
            if not target then return end
            local ok, res = LXR.RPC.Server('lxr-love:ask', id, target)
            if not ok then return toast('error.' .. tostring(res), 'error') end
            if res == 'asked' then toast('info.asked', 'info') end
        end }
    end
    exports['lxr-interact']:AddGlobal('lxr-love:player', 'player', { label = Lang:t('ui.person'), distance = Config.Rules.distance, options = options })
end)

RegisterNetEvent('lxr:client:unloaded', function() pending = nil page('hide') end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then exports['lxr-interact']:Remove('lxr-love:player') end end)
exports('IsPaired', function() return LocalPlayer.state.loving ~= nil and LocalPlayer.state.loving ~= false end)
