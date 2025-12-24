surface.CreateFont("CombineDisplayLarge", {
    font = "Combine", -- or any font you want
    size = 24,            -- change this to your desired size
    weight = 500,
    antialias = true,
})


local PANEL = {}

AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "maxLines", "MaxLines", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end

	self.lines = {}

	self:SetMaxLines(24)
	self:SetFont("CombineDisplayLarge")

	self:SetPos(6, 6) -- You can change these values to set the initial position
	self:SetSize(ScrW(), ScrH() / 2)
	self:ParentToHUD()

	ix.gui.combine = self
end

function PANEL:AddLine(text, color, expireTime, ...)
	if (#self.lines >= self.maxLines) then
		for k, info in ipairs(self.lines) do
			if (info.expireTime != 0) then
				table.remove(self.lines, k)
			end
		end
	end

	-- check for any phrases and replace the text
	if (text:sub(1, 1) == "@") then
		text = L(text:sub(2), ...)
	end

	local index = #self.lines + 1

	self.lines[index] = {
		text = "<:: Situation Index: " .. text .. " ::>",
		color = color or color_white,
		expireTime = CurTime() + 15,
		character = 1,
	}

	return index

end

function PANEL:RemoveLine(id)
	if (self.lines[id]) then
		table.remove(self.lines, id)
	end
end

function PANEL:Think()
	local x, _ = self:GetPos()
	local y = 4

	self:SetPos(x, y)
end

function PANEL:Paint(width, height)
	local textHeight = draw.GetFontHeight(self.font)
	local y = 10
	local padding = 20
	local maxWidth = ScrW() * 0.3 -- Max 30% of screen width

	surface.SetFont(self.font)

	for k, info in ipairs(self.lines) do
		if (info.expireTime != 0 and CurTime() >= info.expireTime) then
			table.remove(self.lines, k)
			continue
		end

		if (info.character < info.text:len()) then
			info.character = info.character + 1
		end
        local displayText = info.text:sub(1, info.character)
        local textWidth = surface.GetTextSize(displayText)
        
        -- Right-align with padding
        local x = ScrW() - textWidth - padding

        -- Draw outline (black, 1px offset in 8 directions)
        for ox = -1, 1 do
            for oy = -1, 1 do
                if ox ~= 0 or oy ~= 0 then
                    surface.SetTextColor(0, 0, 0, 255)
                    surface.SetTextPos(x + ox, y + oy)
                    surface.DrawText(displayText)
                end
            end
        end

        -- Draw main text
        surface.SetTextColor(info.color)
        surface.SetTextPos(x, y)
        surface.DrawText(displayText)

		y = y + textHeight
	end
end

vgui.Register("ixCombineDisplay", PANEL, "Panel")

if (IsValid(ix.gui.combine)) then
	vgui.Create("ixCombineDisplay")
end
