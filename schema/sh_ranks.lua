-- Metropolice Rank System
-- Manages RP (Rank Points) and rank progression

-- Register RP as a persistent character variable
ix.char.RegisterVar("mpfRP", {
	field = "mpf_rp",
	fieldType = ix.type.number,
	default = 0,
	isLocal = true,
	bNoDisplay = true
})

Schema.MPFRanks = {
	[0] = {name = "C34.S17:RPU", display = "C34.S17:RPU", rp = 0},
	[1] = {name = "C34.S17:25%", display = "C34.S17:25%", rp = 25},
	[2] = {name = "C34.S17:50%", display = "C34.S17:50%", rp = 50},
	[3] = {name = "C34.S17:75%", display = "C34.S17:75%", rp = 75},
	[4] = {name = "C34.S17:RL", display = "C34.S17:RL", rp = 100} -- Rank Leader
}

-- Get rank based on RP amount
function Schema:GetMPFRankByRP(rp)
	local rank = 0
	
	for i = 4, 0, -1 do
		if (rp >= self.MPFRanks[i].rp) then
			rank = i
			break
		end
	end
	
	return rank
end

-- Get rank info
function Schema:GetMPFRankInfo(rankNum)
	return self.MPFRanks[rankNum] or self.MPFRanks[0]
end

-- Check if character is Rank Leader
function Schema:IsRankLeader(character)
	if (!character) then return false end
	
	local rp = character:GetData("mpfRP", 0)
	return rp >= 100
end

-- Generate MPF name based on RP
function Schema:GetMPFName(character)
	if (!character) then return "CP:RPU.000" end
	
	local rp = character:GetData("mpfRP", 0)
	local rank = self:GetMPFRankByRP(rp)
	local rankInfo = self:GetMPFRankInfo(rank)
	
	-- Get unit number from character ID or existing name
	local unitNum = character:GetID() % 1000
	local name = character:GetName()
	local numMatch = string.match(name, "%.(%d+)")
	if (numMatch) then
		unitNum = tonumber(numMatch)
	end
	
	return string.format("CP:%s.%s", rankInfo.display, self:ZeroNumber(unitNum, 3))
end
