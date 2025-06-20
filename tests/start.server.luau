local DurinalCycle = require(script.Parent.DurinalCycle)

local config = {
	StandardUTCOffset = "-06:00", -- Central Time

	OutdoorAmbientIntensity = 1,
	BrightnessIntensity = 1.0,
	BloomDayIntensity = 0.5,
	BloomNightIntensity = 0.2,
	SunRaysDayIntensity = 0.5,
	SunRaysNightIntensity = 0.1,

	ResyncInterval = 10, 

	SoundVolume = 3,

	NightSoundId = "rbxassetid://3214049808",
	DawnSoundId = "rbxassetid://9113444532",
	MorningSoundId = "rbxassetid://9112831284",
	NoonSoundId = "rbxassetid://4915214793",
	DuskSoundId = "rbxassetid://4915214793",
	MidnightSoundId = "rbxassetid://3214049808",
	
	Profiling = true,
}

DurinalCycle.AssignConfiguration(config)
DurinalCycle.Start()
