# CM_BackseatDriver

A standalone FiveM script where one player steers and another controls the pedals of the same vehicle.

The driver keeps the wheel. A second player in a configurable seat gets the throttle, brake/reverse and (optionally) the handbrake. If only one person is in the vehicle, the script stays idle and the car drives normally.

## Features

- Split controls between two players in the same vehicle
- Works with keyboard and controller, including analog triggers for partial throttle and brake
- Uses GTA's own driving actions, so each player's key bindings and controller layout are respected automatically
- Per-vehicle seat configuration (choose which seat steers and which seat works the pedals)
- Idle when only one person is in the vehicle, active when both seats are occupied by players
- Server-side validation: pedal input is only accepted from the player actually sitting in the pedal seat of a configured vehicle, and values are clamped
- Failsafe: if pedal updates stop arriving (lag, disconnect), the pedals reset to zero so the car doesn't run away
- No framework required (standalone, no dependencies)
- When tested we reached a max of 10ms and 10% in resmon while spamming keys, and max idle of 0.01ms and 0.16%

## Requirements

- A FiveM server with OneSync enabled (the server uses server-side entity natives to check seats)
- Lua 5.4 (set in the manifest, no action needed)

## Installation

1. Download or clone this repository.
2. Put the folder in your server's `resources` directory.
3. Add this to your `server.cfg`:

   ```
   ensure CM_BackseatDriver
   ```

4. Edit `config.lua` to add the vehicles you want to use (see below).
5. Restart the server or run `refresh` then `ensure CM_BackseatDriver`.

## Usage

1. Two players get into a vehicle that is listed in `Config.Vehicles`.
2. One sits in the driver seat and the other sits in the pedal seat (front passenger by default).
3. Once both seats are occupied by players, both get a notification and backseat driver becomes active.
4. The driver steers. The pedal player uses their normal accelerate, brake/reverse and handbrake controls.
5. If either player leaves the vehicle, the script goes idle and normal driving returns.

## Configuration

Everything lives in `config.lua`.

### Vehicles and seats

Vehicles are keyed by spawn name. Each one can override the default seats.

```lua
Config.DriverSeat = -1   -- default steering seat
Config.PedalSeat  = 0    -- default pedal seat

Config.Vehicles = {
    blista = {},                                  -- uses the default seats
    sultan = { pedalSeat = 1 },                   -- pedal player sits rear left
    -- example = { driverSeat = -1, pedalSeat = 2 },
}
```

Seat indexes: `-1` driver, `0` front passenger, `1` rear left, `2` rear right. Custom vehicles may be differnt.

Make sure the seats you choose actually exist on that model. If a seat doesn't exist, the script simply never activates for that vehicle.

### Options

| Option | Default | Description |
| --- | --- | --- |
| `Config.Debug` | `false` | Prints debug info to the client (F8) and server console. |
| `Config.Controls` | `71 / 72 / 76` | GTA control IDs for throttle, brake/reverse and handbrake. |
| `Config.PedalPlayerHandbrake` | `true` | If `true`, the pedal player controls the handbrake. If `false`, the driver keeps it. |
| `Config.DriverPedalBlock` | `'smart'` | How the driver's own pedal input is blocked (see below). |
| `Config.SendInterval` | `50` | Minimum time in ms between pedal updates sent to the server. |
| `Config.Timeout` | `500` | If the driver gets no pedal update for this many ms, pedals reset to zero. |
| `Config.TriggerDeadzone` | `0.05` | Ignores tiny analog values so a resting controller trigger doesn't creep the car. |
| `Config.ShowNotifications` | `true` | Shows a notification when dual drive activates. |
| `Config.Text` | | The notification text for each role. |

### Driver pedal blocking modes

`Config.DriverPedalBlock` controls how the driver's own throttle, brake and handbrake are blocked while dual drive is active:

- `'smart'` (recommended): the driver's input is blocked whenever the pedal player isn't pressing that pedal, and overridden by the pedal player's value when they are.
- `'always'`: the driver's controls are always disabled, then the pedal player's values are injected. On some server builds this stops the injected values from working at all.
- `'off'`: nothing is disabled, the pedal player's values are only injected on top. The driver may still be able to use a pedal while the pedal player's is at zero.

If the pedals don't respond on your setup, try a different mode.

## Key bindings and controllers

The script reads GTA's driving actions rather than fixed keys, so it follows each player's own setup:

- Keys rebound in GTA's key bindings menu apply automatically.
- Controller players get analog throttle and brake from their triggers (on the default layout).
- The driver's steering is never touched, on keyboard or controller.

## How it works

1. Each client works out whether dual drive is active (configured vehicle, players in both the driver and pedal seats) and which role it has.
2. The pedal player's client reads their throttle, brake and handbrake input and sends it to the server.
3. The server checks that the sender is in the pedal seat of a configured vehicle, clamps the values, finds the player in the driver seat and relays the input to them.
4. The driver's client applies those values to the vehicle controls while blocking their own pedal input.

## Known limitations

- **Latency:** pedal input goes pedal player, then server, then driver, so there is a small delay compared to normal driving. Lowering `Config.SendInterval` can help at the cost of more network traffic.
- **Two players only:** only the driver seat and the pedal seat matter. Other passengers have no effect.
- **Other scripts:** vehicle control, fuel, anti-cheat or similar scripts that also read or override the same driving controls may interfere with this one.
- **Behaviour varies by build:** the way driving controls can be disabled and injected has differed between server builds, which is why `Config.DriverPedalBlock` has multiple modes.

## Troubleshooting

- **Nothing happens:** check that the vehicle's spawn name is in `Config.Vehicles`, that both seats exist on the model, and that both seats are occupied by real players. Turn on `Config.Debug` to see what's being sent.
- **The pedal player's input doesn't move the car:** try `Config.DriverPedalBlock = 'off'`, and check the server console with debug enabled to confirm updates are arriving.
- **The driver can still use the pedals:** make sure `Config.DriverPedalBlock` is `'smart'` or `'always'`.
- **Car creeps with a controller:** raise `Config.TriggerDeadzone`.

## License

[MIT License](https://choosealicense.com/licenses/mit/)

Copyright (c) 2026 Huw Evans

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.