export type SoundIdMap = {
	Night: string,
	Dawn: string,
	Morning: string,
	Noon: string,
	Dusk: string,
	Midnight: string,
}

export type SoundData = {
	id: string,
	volume: number,
}

export type SoundDataMap = {
	[string]: SoundData,
}

export type Config = {
	UTCOffset: string?,
	OutdoorAmbientIntensity: number?,
	BrightnessIntensity: number?,
	BloomDayIntensity: number?,
	BloomNightIntensity: number?,
	SunRaysDayIntensity: number?,
	SunRaysNightIntensity: number?,
	ResyncInterval: number?,
	NightSoundId: string?,
	DawnSoundId: string?,
	MorningSoundId: string?,
	NoonSoundId: string?,
	DuskSoundId: string?,
	MidnightSoundId: string?,
	SoundVolume: number?,
}

return {}
