--!native
--!strict
local lighting: Lighting = game.GetService(game, "Lighting") :: Lighting

local Types = require(script.types)

local function safelook(look, type) -- don't do Instance.new(thing, parent)
	if not look then
		local instance = Instance.new(type)
		instance.Parent = lighting
		return instance
	else
		return look
	end
end

local colorCorrection: ColorCorrectionEffect = safelook(lighting:FindFirstChildOfClass("ColorCorrectionEffect"), "ColorCorrectionEffect")
local bloom: BloomEffect = safelook(lighting:FindFirstChildOfClass("BloomEffect"), "BloomEffect")
local sunRays: SunRaysEffect = safelook(lighting:FindFirstChildOfClass("SunRaysEffect"), "SunRaysEffect")

local UTC_OFFSET: string = "-06:00"

local outdoorAmbientIntensity: number = 1
local brightnessIntensity: number = 1.0
local bloomDayIntensity: number = 0.5
local bloomNightIntensity: number = 0.2
local sunRaysDayIntensity: number = 0.5
local sunRaysNightIntensity: number = 0.1
local resyncInterval: number = 10
local defaultSoundVolume: number = 3

local Profiling:boolean = false

local DefaultSoundIds: Types.SoundIdMap = {
	Night = "rbxassetid://3214049808",
	Dawn = "rbxassetid://9113444532",
	Morning = "rbxassetid://9112831284",
	Noon = "rbxassetid://4915214793",
	Dusk = "rbxassetid://4915214793",
	Midnight =  "rbxassetid://3214049808",
}

local Sounds: Types.SoundDataMap = {
	Night = {id = DefaultSoundIds.Night, volume = defaultSoundVolume},
	Dawn = {id = DefaultSoundIds.Dawn, volume = defaultSoundVolume},
	Morning = {id = DefaultSoundIds.Morning, volume = defaultSoundVolume},
	Noon = {id = DefaultSoundIds.Noon, volume = defaultSoundVolume},
	Dusk = {id = DefaultSoundIds.Dusk, volume = defaultSoundVolume},
	Midnight = {id = DefaultSoundIds.Midnight, volume = defaultSoundVolume}
}

local colors: {[number]: Color3} = {
	[0] = Color3.fromRGB(10, 20, 40), [1] = Color3.fromRGB(8, 15, 35), [2] = Color3.fromRGB(5, 10, 30),
	[3] = Color3.fromRGB(6, 12, 32), [4] = Color3.fromRGB(12, 25, 50), [5] = Color3.fromRGB(25, 45, 85),
	[6] = Color3.fromRGB(70, 60, 110), [7] = Color3.fromRGB(130, 90, 70), [8] = Color3.fromRGB(190, 170, 130),
	[9] = Color3.fromRGB(190, 170, 130), [10] = Color3.fromRGB(210, 190, 150), [11] = Color3.fromRGB(225, 205, 170),
	[12] = Color3.fromRGB(240, 230, 200), [13] = Color3.fromRGB(235, 225, 190), [14] = Color3.fromRGB(230, 215, 180),
	[15] = Color3.fromRGB(225, 205, 170), [16] = Color3.fromRGB(220, 195, 150), [17] = Color3.fromRGB(210, 175, 130),
	[18] = Color3.fromRGB(200, 140, 100), [19] = Color3.fromRGB(110, 80, 120), [20] = Color3.fromRGB(40, 50, 100),
	[21] = Color3.fromRGB(20, 35, 75), [22] = Color3.fromRGB(15, 25, 55), [23] = Color3.fromRGB(12, 20, 45)
}

local levels: {[number]: number} = {
	[0] = -0.5, [1] = -0.45, [2] = -0.4, [3] = -0.35, [4] = -0.3, [5] = -0.25,
	[6] = -0.2, [7] = -0.15, [8] = -0.1, [9] = -0.05, [10] = 0,
	[11] = 0.05, [12] = 0.1, [13] = 0.05, [14] = 0, [15] = -0.05,
	[16] = -0.1, [17] = -0.15, [18] = -0.2, [19] = -0.25, [20] = -0.3,
	[21] = -0.35, [22] = -0.4, [23] = -0.45
}


local function applyDSTOffset(baseOffset: string): string
	local nowUTC: DateTime = DateTime.now()

	local sign: string = string.sub(baseOffset, 1, 1)
	local hStr, mStr = string.match(baseOffset, "[+-](%d+):(%d+)")
	if hStr == nil or mStr == nil then
		warn("Invalid UTC offset format:", baseOffset)
		return baseOffset
	end

	local h: number = tonumber(hStr) or 0
	local m: number = tonumber(mStr) or 0
	local totalOffsetMinutes: number = h * 60 + m
	if sign == "-" then
		totalOffsetMinutes *= -1
	end

	local localTimestamp: number = nowUTC.UnixTimestampMillis + (totalOffsetMinutes * 60 * 1000)
	local localTime: {Year: number, Month: number, Day: number} = DateTime.fromUnixTimestampMillis(localTimestamp):ToLocalTime()

	local year: number = localTime.Year
	local month: number = localTime.Month
	local day: number = localTime.Day

	local function secondSundayInMarch(): number
		local march1: DateTime = DateTime.fromUniversalTime(year, 3, 1, 2, 0, 0)
		local wStr: string = march1:FormatUniversalTime("e", "en-us") -- 'e' = ISO day of week (1=Monday, 7=Sunday)
		local w: number = tonumber(wStr) or 0
		return 8 + (7 - w) % 7
	end

	local function firstSundayInNovember(): number
		local nov1: DateTime = DateTime.fromUniversalTime(year, 11, 1, 2, 0, 0)
		local wStr: string = nov1:FormatUniversalTime("e", "en-us")
		local w: number = tonumber(wStr) or 0
		return 1 + (7 - w) % 7
	end

	local isDST: boolean = false
	if month > 3 and month < 11 then
		isDST = true
	elseif month == 3 then
		isDST = day >= secondSundayInMarch()
	elseif month == 11 then
		isDST = day < firstSundayInNovember() -- this is fine

	end

	if isDST then
		totalOffsetMinutes += 60
		local newSign: string = (totalOffsetMinutes < 0) and "-" or "+"
		local absMinutes: number = math.abs(totalOffsetMinutes)
		local newH: string = string.format("%02d", math.floor(absMinutes / 60))
		local newM: string = string.format("%02d", absMinutes % 60)

		return newSign .. newH .. ":" .. newM
	end


	return baseOffset
end


local function safeAssign<T>(name: string, default: T, config: Types.Config): T
	local value: any = (config :: any)[name]
	if value ~= nil then
		return value
	else
		warn(":: LyliaTech DurinalCycle :: Missing config field '" .. name .. "' ... using default (" .. tostring(default) .. ")")
		return default
	end
end



local function getClockTimeAndHour(offset: string): (number, number)
	local finalOffset: string = applyDSTOffset(offset)

	local sign: string = string.sub(finalOffset, 1, 1)
	local hStr: string?, mStr: string? = string.match(finalOffset, "[+-](%d+):(%d+)")
	if hStr == nil or mStr == nil then
		-- fallback to UTC time
		local utc: {Hour: number, Minute: number, Second: number}  = DateTime.now():ToUniversalTime()
		local hour: number = utc.Hour
		local minute: number = utc.Minute
		local second: number = utc.Second
		local clockTime: number = hour + minute / 60 + second / 3600
		return clockTime, hour
	end

	local h: number = tonumber(hStr) or 0
	local m: number = tonumber(mStr) or 0
	local totalMinutes: number = h * 60 + m
	if sign == "-" then
		totalMinutes = -totalMinutes
	end

	local nowUTC: DateTime = DateTime.now()
	local timestamp: number = nowUTC.UnixTimestampMillis + totalMinutes * 60 * 1000
	local localTime: {Hour: number, Minute: number, Second: number} = DateTime.fromUnixTimestampMillis(timestamp):ToUniversalTime()

	local hour: number = localTime.Hour
	local minute: number = localTime.Minute
	local second: number = localTime.Second
	local clockTime: number = hour + minute / 60 + second / 3600
	return clockTime, hour
end



local function getOutdoorAmbientColorFromClockTime(clockTime: number): Color3
	local lowerHour = math.floor(clockTime) % 24
	local upperHour = (lowerHour + 1) % 24
	local t = clockTime - lowerHour

	local c1 = colors[lowerHour] or Color3.new()
	local c2 = colors[upperHour] or Color3.new()

	local interpolated = Color3.new(
		c1.R + (c2.R - c1.R) * t,
		c1.G + (c2.G - c1.G) * t,
		c1.B + (c2.B - c1.B) * t
	)

	return Color3.new(
		math.clamp(interpolated.R * outdoorAmbientIntensity, 0, 1.5),
		math.clamp(interpolated.G * outdoorAmbientIntensity, 0, 1.5),
		math.clamp(interpolated.B * outdoorAmbientIntensity, 0, 1.5)
	)
end

local function getBrightnessFromClockTime(clockTime: number): number
	local lowerHour = math.floor(clockTime) % 24
	local upperHour = (lowerHour + 1) % 24
	local t = clockTime - lowerHour

	local b1 = levels[lowerHour] or 0
	local b2 = levels[upperHour] or 0

	return (b1 + (b2 - b1) * t) * brightnessIntensity
end

local function getTimeOfDay(hour: number): string
	if hour < 6 then return "Midnight"
	elseif hour < 9 then return "Dawn"
	elseif hour < 12 then return "Morning"
	elseif hour < 15 then return "Noon"
	elseif hour < 18 then return "Dusk"
	else return "Night"
	end
end

local function playSoundForTimeOfDay(): ()
	local currentSound: Sound? = nil
	local currentTimePeriod: string? = nil

	while true do
		local _, hour = getClockTimeAndHour(UTC_OFFSET)
		local timePeriod = getTimeOfDay(hour)
		local soundData = Sounds[timePeriod]

		if soundData and timePeriod ~= currentTimePeriod then
			if currentSound then
				currentSound:Stop()
				currentSound:Destroy()
			end
			local newSound = Instance.new("Sound")
			newSound.SoundId = soundData.id
			newSound.Volume = soundData.volume
			newSound.Looped = true
			newSound.Parent = workspace
			newSound:Play()
			currentSound = newSound
			currentTimePeriod = timePeriod
		end

		task.wait(60)
	end
end

local function AssignConfig(config: Types.Config?): ()
	if config then
		UTC_OFFSET = safeAssign("StandardUTCOffset", UTC_OFFSET, config)
		outdoorAmbientIntensity = safeAssign("OutdoorAmbientIntensity", outdoorAmbientIntensity, config)
		brightnessIntensity = safeAssign("BrightnessIntensity", brightnessIntensity, config)
		bloomDayIntensity = safeAssign("BloomDayIntensity", bloomDayIntensity, config)
		bloomNightIntensity = safeAssign("BloomNightIntensity", bloomNightIntensity, config)
		sunRaysDayIntensity = safeAssign("SunRaysDayIntensity", sunRaysDayIntensity, config)
		sunRaysNightIntensity = safeAssign("SunRaysNightIntensity", sunRaysNightIntensity, config)
		resyncInterval = safeAssign("ResyncInterval", resyncInterval, config)
		DefaultSoundIds.Night = safeAssign("NightSoundId", DefaultSoundIds.Night, config)
		DefaultSoundIds.Dawn = safeAssign("DawnSoundId", DefaultSoundIds.Dawn, config)
		DefaultSoundIds.Morning = safeAssign("MorningSoundId", DefaultSoundIds.Morning, config)
		DefaultSoundIds.Noon = safeAssign("NoonSoundId", DefaultSoundIds.Noon, config)
		DefaultSoundIds.Dusk = safeAssign("DuskSoundId", DefaultSoundIds.Dusk, config)
		DefaultSoundIds.Midnight = safeAssign("MidnightSoundId", DefaultSoundIds.Midnight, config)
		defaultSoundVolume = safeAssign("SoundVolume", defaultSoundVolume, config)
		Profiling = safeAssign("Profiling", Profiling, config)
	else
		warn(":: LyliaTech DurinalCycle :: No configuration provided! Resorting to default values...")
	end
end

local function Start(): ()
	
	if Profiling then 
		debug.setmemorycategory("DurinalCycle")
	end
	
	local counter = 0
	task.defer(playSoundForTimeOfDay)

	local ms = DateTime.now():ToUniversalTime().Millisecond
	task.wait((1000 - ms) / 1000)

	while true do
		local clockTime, hour = getClockTimeAndHour(UTC_OFFSET)
		lighting.ClockTime = clockTime
		colorCorrection.Brightness = getBrightnessFromClockTime(clockTime)
		bloom.Intensity = (clockTime >= 6 and clockTime < 18) and bloomDayIntensity or bloomNightIntensity
		sunRays.Intensity = (clockTime >= 6 and clockTime < 18) and sunRaysDayIntensity or sunRaysNightIntensity
		lighting.OutdoorAmbient = getOutdoorAmbientColorFromClockTime(clockTime)

		counter += 1
		if counter % resyncInterval == 0 then
			ms = DateTime.now():ToUniversalTime().Millisecond
			task.wait((1000 - ms) / 1000)
		else
			task.wait(1)
		end
	end
end

return table.freeze({
	Start = Start,
	GetTimeOfDay = getTimeOfDay,
	GetClockTimeAndHour = getClockTimeAndHour,
	AssignConfiguration = AssignConfig
})
