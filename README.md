# Durinal-Cycle

The *Durinal Cycle* is a strictly-typed open-sourced system that syncs the clock time in-game to a certain time zone in real life, with automatic adjustments to Daylight Savings Time. In addition, it also plays outdoor audio based on the current time, including outdoor ambient and brightness. Furthermore, the system ensures that the in-game clock time is synced with `DateTime.now()` to the user's preference. 

## Installation
Grab the `.rbxl` file from releases and insert it to `ServerScriptService`.

## Usage
Create a server script with the following code below:
```lua
local DurinalCycle = require(script.Parent.DurinalCycle)

-- configuration table
local config = {
	StandardUTCOffset = "-06:00", -- Central Time (MUST BE STANDARD TIME, NO DAYLIGHT SAVINGS)

  -- intensity configurations
	OutdoorAmbientIntensity = 1,
	BrightnessIntensity = 1.0,
	BloomDayIntensity = 0.5,
	BloomNightIntensity = 0.2,
	SunRaysDayIntensity = 0.5,
	SunRaysNightIntensity = 0.1,

	ResyncInterval = 10, -- how many seconds until the in-game clock time is synced again

	SoundVolume = 3, -- volume of outdoor sounds

  -- sound configuration
	NightSoundId = "rbxassetid://3214049808",
	DawnSoundId = "rbxassetid://9113444532",
	MorningSoundId = "rbxassetid://9112831284",
	NoonSoundId = "rbxassetid://4915214793",
	DuskSoundId = "rbxassetid://4915214793",
	MidnightSoundId = "rbxassetid://3214049808",

  -- debug profiling (memory)
	Profiling = false,
}

DurinalCycle.AssignConfiguration(config) -- assigns configuration
DurinalCycle.Start() -- starts!
```
## License
This project is licensed under the Apache 2.0 license.
