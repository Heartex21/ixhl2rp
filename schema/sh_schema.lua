
Schema.name = "HL2 RP"
Schema.author = "nebulous.cloud"
Schema.description = "Dive into the world of the City Outskirts of C27."

-- Include netstream
ix.util.Include("libs/thirdparty/sh_netstream2.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_commands.lua")

ix.util.Include("cl_schema.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sh_voices.lua")
ix.util.Include("sv_schema.lua")
ix.util.Include("sv_hooks.lua")



ix.util.Include("meta/sh_player.lua")
ix.util.Include("meta/sv_player.lua")
ix.util.Include("meta/sh_character.lua")

ix.flag.Add("v", "Access to light blackmarket goods.")
ix.flag.Add("V", "Access to heavy blackmarket goods.")


ix.anim.SetModelClass("models/wn7new/metropolice/male_07.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteghostcp.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteshockcp.mdl", "metrocop")
ix.anim.SetModelClass("models/leet_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/sect_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/willardnetworks/citizens/male01.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male02.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male03.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male04.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male05.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male06.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male07.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male08.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male09.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/male10.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_01.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_02.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_03.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_04.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_06.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/citizens/female_07.mdl", "citizen_female")
ix.anim.SetModelClass("models/cultist/hl_a/combine_grunt/npc/combine_grunt.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_elite_h.mdl", "overwatch")


function Schema:ZeroNumber(number, length)
	local amount = math.max(0, length - string.len(number))
	return string.rep("0", amount)..tostring(number)
end

function Schema:IsCombineRank(text, rank)
	return string.find(text, "[%D+]"..rank.."[%D+]")
end

do
	local CLASS = {}
	CLASS.color = Color(150, 100, 100)
	CLASS.format = "Dispatch broadcasts \"%s\""

	function CLASS:CanSay(speaker, text)
		if (!speaker:IsDispatch()) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, text))
	end

	ix.chat.Register("dispatch", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(75, 150, 50)
	CLASS.format = "%s radios in \"%s\""

	function CLASS:CanHear(speaker, listener)
		local character = listener:GetCharacter()
		local inventory = character:GetInventory()
		local bHasRadio = false

		for k, v in pairs(inventory:GetItemsByUniqueID("handheld_radio", true)) do
			if (v:GetData("enabled", false) and speaker:GetCharacter():GetData("frequency") == character:GetData("frequency")) then
				bHasRadio = true
				break
			end
		end

		return bHasRadio
	end

	function CLASS:OnChatAdd(speaker, text)
    -- Voiceline lookup
    local faction = speaker.GetFaction and speaker:GetFaction() or speaker:Team()
    local voiceList = ix.voices and ix.voices.stored or {}
    local foundVoice

    for _, v in pairs(voiceList) do
        local matchesFaction = false
        if v.faction and istable(v.faction) then
            for _, fac in ipairs(v.faction) do
                if fac == faction then
                    matchesFaction = true
                    break
                end
            end
        elseif v.faction == faction then
            matchesFaction = true
        end

        if matchesFaction and v.command and string.lower(text) == string.lower(v.command) then
            foundVoice = v
            break
        end
    end

    if foundVoice and foundVoice.sound then
        if IsValid(speaker) then
            speaker:EmitSound(foundVoice.sound, 70, 100, 0.5)
        end
        text = foundVoice.text or text
    end

    text = speaker.IsCombine and speaker:IsCombine() and string.format("<:: %s ::>", text) or text
    chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
end

	ix.chat.Register("radio", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(255, 255, 175)
	CLASS.format = "%s radios in \"%s\""

	function CLASS:GetColor(speaker, text)
		if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			return Color(175, 255, 175)
		end

		return self.color
	end

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.radio:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		text = speaker:IsCombine() and string.format("<:: %s ::>", text) or text
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("radio_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "%s requests \"%s\""

	function CLASS:CanHear(speaker, listener)
		return listener:IsCombine() or speaker:Team() == FACTION_ADMIN
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "%s requests \"%s\""

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.request:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:Team() == FACTION_CITIZEN and listener:Team() == FACTION_CITIZEN)
		and (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 125, 175)
	CLASS.format = "%s broadcasts \"%s\""

	function CLASS:CanSay(speaker, text)
		if (speaker:Team() != FACTION_ADMIN) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("broadcast", CLASS)
end

for k, v in pairs(ix.item.categories or {}) do
    print("Category:", k, "Description:", v.description)
end

local oldAdd = Schema.voices.Add
function Schema.voices.Add(class, key, text, sound, global)
    oldAdd(class, key, text, sound, global)

    class = string.lower(class)
    -- Only add to classTables if it's a tracked class
    if Schema.voices.classTables[class:upper()] then
        table.insert(Schema.voices.classTables[class:upper()], {key = key, text = text, sound = sound, global = global})
    end
end