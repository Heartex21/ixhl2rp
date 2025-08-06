CLASS.name = "Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = true

function CLASS:OnSet(client)
    local character = client:GetCharacter()

    if (character) then
        character:SetModel("models/cultist/hl_a/combine_grunt/npc/combine_grunt.mdl")
        print("[DEBUG] Model set for " .. client:Name())

        -- Apply skin and bodygroups after setting the model
        timer.Simple(0.5, function() -- Delay to ensure model is initialized
			if IsValid(client) and client:GetCharacter() == character then
				print("[DEBUG] Setting skin and bodygroups for " .. client:Name())
				client:SetSkin(1) -- Set the skin to 2

				-- Use a helper function to set bodygroups by name
				local function SetBodygroupByName(entity, groupName, value)
					local groupIndex = entity:FindBodygroupByName(groupName)
					if groupIndex ~= -1 then
						entity:SetBodygroup(groupIndex, value)
					else
						print("[DEBUG] Bodygroup '" .. groupName .. "' not found for " .. entity:Name())
					end
				end

				SetBodygroupByName(client, "Skin", 1) -- Set "Skin" bodygroup to option 1
				SetBodygroupByName(client, "Gas_canister", 1) -- Set "Gas_canister" bodygroup to option 1
            else
                print("[DEBUG] Failed to set skin and bodygroups for " .. (client:Name() or "unknown"))
            end
        end)
    end
end

CLASS_TGU = CLASS.index
