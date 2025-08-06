local playerMeta = FindMetaTable("Player")

function playerMeta:IsTGU()
    local character = self:GetCharacter()
    if character then
        local name = character:GetName()
        -- Check if the character's rank is TGU (e.g., "OTA:ECHO.TGU-01")
        return string.find(name, "TGU")
    end
    return false
end

function playerMeta:IsCombine()
	local faction = self:Team()
	return faction == FACTION_MPF or faction == FACTION_OTA
end

function playerMeta:IsDispatch()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = faction == FACTION_OTA

	if (!bStatus) then
		for k, v in ipairs({ "SCN", "DvL", "SeC" }) do
			if (Schema:IsCombineRank(name, v)) then
				bStatus = true

				break
			end
		end
	end

	return bStatus
end
