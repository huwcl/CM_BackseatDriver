-- role is 'driver', 'pedal', or nil (idle)
local role = nil

-- Latest pedal values received by the driver
local remote = { throttle = 0.0, brake = 0.0, handbrake = 0.0, last = 0 }

local function debugPrint(...)
    if Config.Debug then print('[CM_BackseatDriver]', ...) end
end

local function notify(text)
    if not Config.ShowNotifications then return end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

-- Returns { driverSeat, pedalSeat } for a configured vehicle, or nil
local function getVehicleSettings(veh)
    return Config.VehicleSet[GetEntityModel(veh) & 0xFFFFFFFF]
end

local function isPlayerPed(ped)
    return ped ~= 0 and DoesEntityExist(ped) and IsPedAPlayer(ped)
end

local function resetRemote()
    remote.throttle, remote.brake, remote.handbrake, remote.last = 0.0, 0.0, 0.0, 0
end

-- Work out whether dual drive is active and which role this player has.
-- Needs a configured vehicle with a player in BOTH the driver seat and the pedal seat.
-- With only one person inside, role stays nil and the script does nothing.
CreateThread(function()
    while true do
        local newRole = nil
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        local settings = veh ~= 0 and getVehicleSettings(veh) or nil
        if settings then
            local driver = GetPedInVehicleSeat(veh, settings.driverSeat)
            local pedal = GetPedInVehicleSeat(veh, settings.pedalSeat)

            if isPlayerPed(driver) and isPlayerPed(pedal) then
                if driver == ped then
                    newRole = 'driver'
                elseif pedal == ped then
                    newRole = 'pedal'
                end
            end
        end

        if newRole ~= role then
            debugPrint('role changed:', tostring(role), '->', tostring(newRole))
            role = newRole
            resetRemote()
            if role then notify(Config.Text[role]) end
        end

        Wait(role and 250 or 500)
    end
end)

-- Pedal player: read inputs and send to server
CreateThread(function()
    local cur = { t = 0.0, b = 0.0, h = 0.0 }
    local lastSent = { t = -1.0, b = -1.0, h = -1.0 }
    local lastSendTime = 0

    -- Reads a driving action through the player's own GTA bindings (keyboard or controller).
    -- Keyboard gives 0 or 1, controller triggers give the full analog range.
    local function readAnalog(control)
        local v = math.abs(GetControlNormal(0, control))
        if v < Config.TriggerDeadzone then return 0.0 end
        if v > 1.0 then return 1.0 end
        return v
    end

    while true do
        if role == 'pedal' then
            cur.t = readAnalog(Config.Controls.throttle)
            cur.b = readAnalog(Config.Controls.brake)
            cur.h = 0.0
            if Config.PedalPlayerHandbrake then
                cur.h = IsControlPressed(0, Config.Controls.handbrake) and 1.0 or 0.0
            end

            local now = GetGameTimer()
            local changed = math.abs(cur.t - lastSent.t) > 0.02
                or math.abs(cur.b - lastSent.b) > 0.02
                or cur.h ~= lastSent.h
            local keepAlive = (cur.t > 0.0 or cur.b > 0.0 or cur.h > 0.0)
                and (now - lastSendTime) >= (Config.Timeout / 2)

            if (changed or keepAlive) and (now - lastSendTime) >= Config.SendInterval then
                TriggerServerEvent('dualdrive:pedals', cur.t, cur.b, cur.h)
                lastSent.t, lastSent.b, lastSent.h = cur.t, cur.b, cur.h
                lastSendTime = now
            end

            Wait(0)
        else
            -- Idle: reset so the next activation starts clean
            if cur.t ~= 0.0 or cur.b ~= 0.0 or cur.h ~= 0.0 then
                cur.t, cur.b, cur.h = 0.0, 0.0, 0.0
            end
            lastSent.t, lastSent.b, lastSent.h = -1.0, -1.0, -1.0
            Wait(250)
        end
    end
end)

-- Applies one pedal value on the driver's client according to Config.DriverPedalBlock
local function applyPedal(control, value)
    local mode = Config.DriverPedalBlock

    if mode == 'always' then
        DisableControlAction(0, control, true)
    elseif mode == 'smart' and value <= 0.0 then
        -- Pedal player isn't pressing this pedal: just block the driver's own input. Seams to work reliability
        DisableControlAction(0, control, true)
        return
    end

    -- Pedal player is pressing: override whatever the driver's input would have been
    SetControlNormal(0, control, value)
end

-- Driver: block own pedals and apply the pedal player's values
CreateThread(function()
    while true do
        if role == 'driver' then
            -- Failsafe: stale data means pedals go to zero
            if GetGameTimer() - remote.last > Config.Timeout then
                remote.throttle, remote.brake, remote.handbrake = 0.0, 0.0, 0.0
            end

            applyPedal(Config.Controls.throttle, remote.throttle)
            applyPedal(Config.Controls.brake, remote.brake)
            if Config.PedalPlayerHandbrake then
                applyPedal(Config.Controls.handbrake, remote.handbrake)
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Pedal values arriving from the server (only meaningful for the driver)
RegisterNetEvent('dualdrive:apply', function(t, b, h)
    if role ~= 'driver' then return end
    remote.throttle = t
    remote.brake = b
    remote.handbrake = h
    remote.last = GetGameTimer()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    role = nil
    resetRemote()
end)