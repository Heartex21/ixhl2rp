
function Schema:CanPlayerUseBusiness(client, uniqueID)
	if (client:Team() == FACTION_CITIZEN) then
		local itemTable = ix.item.list[uniqueID]

		if (itemTable) then
			if (itemTable.permit) then
				local character = client:GetCharacter()
				local inventory = character:GetInventory()

				if (!inventory:HasItem("permit_"..itemTable.permit)) then
					return false
				end
			elseif (itemTable.base ~= "base_permit") then
				return false
			end
		end
	end
end

hook.Add("PlayerMessageSend", "ixRadioVoiceline", function(speaker, chatType, text, bAnonymous, receivers, rawText)
    if chatType ~= "radio" then return end

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
        for _, ply in ipairs(receivers) do
            if IsValid(ply) then
                ply:EmitSound(foundVoice.sound, 70, 100, 0.5)
            end
        end
    end
end)

-- called when the client wants to view the combine data for the given target
function Schema:CanPlayerViewData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

-- called when the client wants to edit the combine data for the given target
function Schema:CanPlayerEditData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

function Schema:CanPlayerViewObjectives(client)
	return client:IsCombine()
end

function Schema:CanPlayerEditObjectives(client)
	if (!client:IsCombine() or !client:GetCharacter()) then
		return false
	end

	local bCanEdit = false
	local name = client:GetCharacter():GetName()

	for k, v in ipairs({"OfC", "EpU", "DvL", "SeC"}) do
		if (self:IsCombineRank(name, v)) then
			bCanEdit = true
			break
		end
	end

	return bCanEdit
end

function Schema:CanDrive()
	return false
end

hook.Add("PlayerSetHandsModel", "SetOverwatchHands", function(player, hands)
    local character = player:GetCharacter()

    if character and character:GetFaction() == FACTION_OTA then
        print("[DEBUG] PlayerSetHandsModel: Setting OTA hands for", player:Name())
        hands:SetModel("models/weapons/combine_arms/juonovom/HL2 Vanilla/c_arms_combine_regular.mdl")
    else
        print("[DEBUG] PlayerSetHandsModel: Not OTA for", player:Name())
    end
end)

hook.Add("PlayerSpawn", "SetOverwatchHandsOnSpawn", function(player)
    local character = player:GetCharacter()

    if character and character:GetFaction() == FACTION_OTA then
        print("[DEBUG] PlayerSpawn: Setting OTA hands for", player:Name())
        local hands = player:GetHands()
        if IsValid(hands) then
            hands:SetModel("models/weapons/combine_arms/juonovom/HL2 Vanilla/c_arms_combine_regular.mdl")
        else
            print("[DEBUG] PlayerSpawn: Hands entity is invalid for", player:Name())
        end
    else
        print("[DEBUG] PlayerSpawn: Not OTA for", player:Name())
    end
end)