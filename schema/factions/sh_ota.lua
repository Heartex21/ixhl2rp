
FACTION.name = "Overwatch Transhuman Arm"
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
FACTION.color = Color(150, 50, 50, 255)
FACTION.pay = 40
FACTION.models = {"models/cultist/hl_a/combine_grunt/npc/combine_grunt.mdl"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}
FACTION.armor = 150

function FACTION:OnCharacterCreated(client, character)
    local inventory = character:GetInventory()

    inventory:Add("tfa_osips", 1)
    inventory:Add("osipsammo", 8)
    inventory:Add("health_kit", 1)
    inventory:Add("zip_tie", 2)

    character:SetModel(self.models[1])

    -- Use a timer to ensure the model is fully initialized before setting bodygroups
    timer.Simple(0, function()
        if IsValid(client) and client:GetCharacter() == character then
            client:SetBodygroup(1, 1) -- Set "Skin" bodygroup to option 1
            client:SetBodygroup(8, 1) -- Set "Gas_canister" bodygroup to option 1
        end
    end)
end


function FACTION:GetDefaultName(client)
	return "OTA:ECHO.TGU-" .. Schema:ZeroNumber(math.random(1, 99), 2), true
end

function FACTION:OnSpawn(client)
    timer.Simple(0.1, function()
        if IsValid(client) then
            client:SetBodygroup(1, 1) -- Set "Skin" bodygroup to option 1
            client:SetBodygroup(8, 1) -- Set "Gas_canister" bodygroup to option 1
        end
    end)
end

function FACTION:OnTransferred(character)
	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])
	
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()

	if (!Schema:IsCombineRank(oldValue, "TGU") and Schema:IsCombineRank(value, "TGU")) then
		character:JoinClass(CLASS_TGU)
	elseif (!Schema:IsCombineRank(oldValue, "EOW") and Schema:IsCombineRank(value, "EOW")) then
		character:JoinClass(CLASS_EOW)
	end
end

FACTION_OTA = FACTION.index

function FACTION:OnSpawn(client)
    timer.Simple(0.1, function()
        if IsValid(client) then
            client:SetBodygroup(1, 1) -- Set "Skin" bodygroup to option 1
            client:SetBodygroup(8, 1) -- Set "Gas_canister" bodygroup to option 1

            -- Force the hands model
            local hands = client:GetHands()
            if IsValid(hands) then
                print("[DEBUG] FACTION:OnSpawn: Setting OTA hands for", client:Name())
                hands:SetModel("models/weapons/combine_arms/juonovom/HL2 Vanilla/c_arms_combine_regular.mdl")
            else
                print("[DEBUG] FACTION:OnSpawn: Hands entity is invalid for", client:Name())
            end
        end
    end)
end