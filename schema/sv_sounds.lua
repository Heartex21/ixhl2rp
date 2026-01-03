-- Precache and add custom sounds for download

local sounds = {
	"sound/hl2rp/terminal-open.wav",
	"sound/hl2rp/terminal-click.wav",
	"sound/hl2rp/terminal-hum.wav",
	"sound/hl2rp/passing.wav"
}

for _, soundPath in ipairs(sounds) do
	resource.AddFile(soundPath)
end

-- Precache sounds (without "sound/" prefix)
util.PrecacheSound("hl2rp/terminal-open.wav")
util.PrecacheSound("hl2rp/terminal-click.wav")
util.PrecacheSound("hl2rp/terminal-hum.wav")
util.PrecacheSound("hl2rp/passing.wav")

print("[HL2RP] Precached " .. #sounds .. " custom sounds")
