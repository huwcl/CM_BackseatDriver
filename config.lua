Config = {}

-- Please note you need to have OneSync enabled

-- Print debug info to the console (F8 on clients, server console on server)
Config.Debug = false

-- Vehicles that use dual drive. Use the spawn name of the model.
-- If only ONE person is in the vehicle, the script stays idle and the car drives normally.
-- When the driver seat AND the pedal seat are both occupied by players, it becomes active.
-- You can specify which seats to use for pedal/driver, the driver needs to be the seat you would use to drive normally.
Config.Vehicles = {
    sultan = { 
        driverSeat = -1, -- this seat steers
        pedalSeat = 0 -- this seat controls pedals
    },
}

-- Default seats, used by any vehicle above that doesn't set its own.
-- Seat indexes: -1 = driver, 0 = front passenger, 1 = rear left, 2 = rear right
Config.DriverSeat = -1
Config.PedalSeat  = 0

-- Control IDs, automatically gets the players keybind.
Config.Controls = {
    throttle  = 71, -- INPUT_VEH_ACCELERATE
    brake     = 72, -- 	INPUT_VEH_BRAKE
    handbrake = 76, -- INPUT_VEH_HANDBRAKE
}

-- Who owns the handbrake while active?
-- true = pedal player, false = driver keeps it
Config.PedalPlayerHandbrake = true

-- How the driver's own throttle/brake/handbrake input is blocked while dual drive is active:
--   'smart'  = block the driver's input whenever the pedal player isn't pressing that pedal, and
--              override it with the pedal player's value whenever they are. (Recommended)
--   'always' = always disable the driver's controls and then inject the pedal player's values.
--              On some builds this stops the injected values from working at all.
--   'off'    = never disable anything, only override with the pedal player's values.
--              The driver can still use a pedal while the pedal player's is at zero.
Config.DriverPedalBlock = 'smart'

-- How often (ms) the pedal player's inputs are sent to the server at most.
-- Lower = more responsive, higher = less network traffic.
-- If controls are laggy lower this value.
-- Please note setting this value too low can cause server hitches
Config.SendInterval = 45

-- If the driver hasn't received a pedal update for this long (ms), pedals reset to 0.
-- Stops the car running away if the pedal player lags out or leaves.
Config.Timeout = 500

-- Ignore tiny analog values (0.0 - 1.0) so a controller trigger that rests slightly pressed
-- doesn't creep the car forward. Doesn't affect keyboard input.
Config.TriggerDeadzone = 0.05

-- Notifications shown when backseat driver switches on. Set to false to disable.
Config.ShowNotifications = true
Config.Text = {
    driver = 'Backseat Driver active: you steer, your passenger controls the pedals.',
    pedal  = 'Backseat Driver  active: you control the pedals, the driver steers.',
}

-- Only edit if you know what your doing :)
Config.VehicleSet = {}
for name, opts in pairs(Config.Vehicles) do
    Config.VehicleSet[GetHashKey(name) & 0xFFFFFFFF] = {
        driverSeat = opts.driverSeat or Config.DriverSeat,
        pedalSeat  = opts.pedalSeat  or Config.PedalSeat,
    }
end