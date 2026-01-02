-- City Code System
-- Manages city status codes

Schema.CityCode = Schema.CityCode or {}

-- City code definitions
Schema.CityCode.Codes = {
	[1] = {name = "SOCIOSTABLE", color = Color(50, 255, 50), description = "Normal operations, citizens compliant"},
	[2] = {name = "MARGINAL", color = Color(255, 200, 50), description = "Heightened alert, increased patrols"},
	[3] = {name = "JUDGMENT WAIVER", color = Color(255, 100, 50), description = "Civil protection authorized for immediate verdicts"},
	[4] = {name = "AUTONOMOUS WAIVER", color = Color(255, 50, 50), description = "Full authority, lethal force authorized"}
}

-- Current city code (stored server-side)
Schema.CityCode.Current = Schema.CityCode.Current or 1

-- Get current city code
function Schema:GetCityCode()
	return self.CityCode.Current or 1
end

-- Get city code info
function Schema:GetCityCodeInfo(code)
	return self.CityCode.Codes[code] or self.CityCode.Codes[1]
end

-- Set city code (server-only)
if (SERVER) then
	function Schema:SetCityCode(code)
		code = math.Clamp(code, 1, 4)
		self.CityCode.Current = code
		
		-- Network to all clients
		net.Start("ixCityCodeUpdate")
			net.WriteUInt(code, 3)
		net.Broadcast()
		
		-- Log the change
		print("[City Code] Changed to: " .. self:GetCityCodeInfo(code).name)
	end
	
	-- Network string
	util.AddNetworkString("ixCityCodeUpdate")
end

-- Client-side city code receiver
if (CLIENT) then
	net.Receive("ixCityCodeUpdate", function()
		local code = net.ReadUInt(3)
		Schema.CityCode.Current = code
		
		local info = Schema:GetCityCodeInfo(code)
		print("[City Code] Updated to: " .. info.name)
	end)
end
