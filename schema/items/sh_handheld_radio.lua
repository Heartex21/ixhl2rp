ITEM.name = "Handheld Radio"
ITEM.model = Model("models/deadbodies/dead_male_civilian_radio.mdl")
ITEM.description = "A shiny handheld radio with a frequency tuner.\nIt is currently turned %s%s."
ITEM.cost = 50
ITEM.classes = {CLASS_EMP, CLASS_EOW}
ITEM.flag = "v"

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("enabled")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end
-- Hook into the /radio chat command to play a voiceline
if (SERVER) then
	ix.chat.Register("radio", {
		format = "%s radios in \"<:: %s ::>\"",
		color = Color(150, 200, 100),
		onCanSay = function(self, speaker, text)
			local inv = speaker:GetCharacter():GetInventory()
			local hasRadio = false

			for _, item in pairs(inv:GetItems()) do
				if item.uniqueID == "handheld_radio" and item:GetData("enabled", false) then
					hasRadio = true
					break
				end
			end

			if not hasRadio then
				return false, "You need to have an enabled radio to use this."
			end

			return true
		end,
		OnChat = function(self, speaker, text)
			-- Find the correct voiceline for the player's faction and command
			local faction = speaker:GetFaction() -- or use speaker:GetFaction() depending on your schema
			local voiceList = ix.voices and ix.voices.stored or {}
			local foundVoice

			for _, v in pairs(voiceList) do
				if v.faction and istable(v.faction) then
					for _, fac in ipairs(v.faction) do
						if fac == faction then
							if v.command and string.lower(text) == string.lower(v.command) then
								foundVoice = v
								break
							end
						end
					end
				elseif v.faction == faction then
					if v.command and string.lower(text) == string.lower(v.command) then
						foundVoice = v
						break
					end
				end
			end

			if foundVoice then
				-- Play the voiceline and display the proper text
				hook.Run("PlayerRadioVoiceline", speaker, foundVoice.text or text, foundVoice.sound)
				return foundVoice.text or text
			else
				hook.Run("PlayerRadioVoiceline", speaker, text)
				return text
			end
		end,
		onChatAdd = function(self, speaker, text)
			chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
		end,
	})
end

-- Example voiceline hook
hook.Add("PlayerRadioVoiceline", "PlayRadioVoiceline", function(ply, text, sound)
	if sound then
		ply:EmitSound(sound, 70, 100, 0.5)
	else
		ply:EmitSound("npc/combine_soldier/vo/on3.wav", 70, 100, 0.5)
	end
end)
function ITEM:GetDescription()
	local enabled = self:GetData("enabled")
	return string.format(self.description, enabled and "on" or "off", enabled and (" and tuned to " .. self:GetData("frequency", "100.0")) or "")
end

function ITEM.postHooks.drop(item, status)
	item:SetData("enabled", false)
end

ITEM.functions.Frequency = {
	OnRun = function(itemTable)
		netstream.Start(itemTable.player, "Frequency", itemTable:GetData("frequency", "000.0"))

		return false
	end
}

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		local character = itemTable.player:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local bCanToggle = true

		-- don't allow someone to turn on another radio when they have one on already
		if (#radios > 1) then
			for k, v in ipairs(radios) do
				if (v != itemTable and v:GetData("enabled", false)) then
					bCanToggle = false
					break
				end
			end
		end

		if (bCanToggle) then
			itemTable:SetData("enabled", !itemTable:GetData("enabled", false))
			itemTable.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)
		else
			itemTable.player:NotifyLocalized("radioAlreadyOn")
		end

		return false
	end
}
