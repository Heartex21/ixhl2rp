
Schema.name = "HL2 RP"
Schema.author = "nebulous.cloud"
Schema.description = "Dive into the world of the City Outskirts of C27."

-- Include netstream
ix.util.Include("libs/thirdparty/sh_netstream2.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_ranks.lua")
ix.util.Include("sh_citycode.lua")
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


ix.anim.SetModelClass("models/ma/hla/terranovapolice.mdl", "metrocop")
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

if SERVER then
    util.AddNetworkString("ixZipTieOpenInventory")

	-- Ensure typing indicator net message is registered early so clients can start it during UI init
	util.AddNetworkString("ixTypeClass")

    hook.Add("KeyPress", "ixZiptieSearch", function(client, key)
        if key ~= IN_RELOAD then return end
        if not IsValid(client) or not client:Alive() then return end

        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv:HasItem("zip_tie") then return end

        local trace = client:GetEyeTrace()
        local target = trace.Entity

        if not (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then return end
        if not target:IsRestricted() then
            client:Notify("You can only search someone who is tied up!")
            return
        end

        if client._ixSearching then return end
        client._ixSearching = true

        client:SetAction("@searching", 2)
        client:DoStaredAction(target, function()
            client._ixSearching = nil
            if not (IsValid(client) and IsValid(target)) then return end
            if client:GetPos():DistToSqr(target:GetPos()) > 10000 then
                client:Notify("You moved too far away.")
                return
            end

            -- Send net message to client to open inventory
            net.Start("ixZipTieOpenInventory")
                net.WriteEntity(target) -- target player whose inventory to open
            net.Send(client)

            client:Notify("You searched " .. target:Name() .. "'s belongings.")
        end, 2, function()
            client._ixSearching = nil
            client:SetAction()
            client:Notify("Search cancelled.")
        end)
    end)
end


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
	-- Voiceline lookup (support multiple voice tokens in one message)
	local faction = speaker.GetFaction and speaker:GetFaction() or speaker:Team()
	-- Tokenize and match against the speaker's voice classes so multiple commands can be used
	local tokens = {}
	for token in string.gmatch(text or "", "[^,;|%s]+") do
		tokens[#tokens + 1] = token
	end

	local foundVoices = {}
	local classes = Schema.voices.GetClass(speaker)

	for _, className in ipairs(classes) do
		for _, token in ipairs(tokens) do
			local info = Schema.voices.Get(className, token)

			if (info) then
				foundVoices[#foundVoices + 1] = info
			end
		end
	end
	if (#foundVoices > 0) then
		local sounds = {}

		for _, fv in ipairs(foundVoices) do
			if fv.sound and not fv.global and IsValid(speaker) then
				sounds[#sounds + 1] = fv.sound
			elseif fv.sound and fv.global then
				netstream.Start(nil, "PlaySound", fv.sound)
			end
		end

		if (#sounds > 0 and IsValid(speaker)) then
			if (speaker:IsCombine()) then
				sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
			end

			ix.util.EmitQueuedSounds(speaker, sounds, nil, 0.1, 70)
		end

		local texts = {}
		for _, fv in ipairs(foundVoices) do
			texts[#texts + 1] = fv.text or ""
		end

		text = table.concat(texts, " ")
	end

	if (IsValid(speaker) and speaker:IsCombine()) then
		text = string.format("<:: %s ::>", text)
	end

	local name = hook.Run("GetCharacterName", speaker, "radio") or (IsValid(speaker) and speaker:Name() or "Console")
	local translated = L2("radioFormat", name, text)

	chat.AddText(self.color, translated or string.format(self.format, name, text))
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