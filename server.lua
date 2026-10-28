local lastMessage = {}

local function clamp01(v)
    if type(v) ~= 'number' or v ~= v then return 0.0 end -- reject non-numbers and NaN
    if v < 0.0 then return 0.0 end
    if v > 1.0 then return 1.0 end
    return v
end

RegisterNetEvent('dualdrive:pedals', function(throttle, brake, handbrake)
    local src = source

    -- Basic rate limit
    local now = GetGameTimer()
    if lastMessage[src] and (now - lastMessage[src]) < 20 then return end
    lastMessage[src] = now

    throttle = clamp01(throttle)
    brake = clamp01(brake)
    handbrake = clamp01(handbrake)

    -- Sender must be sitting in the pedal seat of a configured vehicle
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    if not Config.VehicleSet[GetEntityModel(veh) & 0xFFFFFFFF] then return end
    if GetPedInVehicleSeat(veh, Config.PedalSeat) ~= ped then return end

    -- A real player must be in the driver seat
    local driverPed = GetPedInVehicleSeat(veh, Config.DriverSeat)
    if driverPed == 0 or not IsPedAPlayer(driverPed) then return end

    local driverSrc = NetworkGetEntityOwner(driverPed)
    if not driverSrc or driverSrc == src then return end

    TriggerClientEvent('dualdrive:apply', driverSrc, throttle, brake, handbrake)

    if Config.Debug then
        print(('[CM_BackseatDriver] %s -> %s  t=%.2f b=%.2f h=%.0f'):format(src, driverSrc, throttle, brake, handbrake))
    end
end)

AddEventHandler('playerDropped', function()
    lastMessage[source] = nil
end)