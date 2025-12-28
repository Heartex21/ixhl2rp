
local PLUGIN = PLUGIN

-- Handle corpse inventory opening
netstream.Hook("ixCorpseOpenInventory", function(data)
	if (IsValid(ix.gui.corpseInventory)) then
		ix.gui.corpseInventory:Remove()
	end
	
	local entity = Entity(data.entity)
	
	if (!IsValid(entity)) then
		return
	end
	
	local corpseInventory = ix.item.inventories[data.inventory]
	
	if (!corpseInventory) then
		return
	end
	
	-- Create the dual inventory panel
	local panel = vgui.Create("ixCorpseInventory")
	panel:SetCorpseInventory(corpseInventory, data.name)
	
	ix.gui.corpseInventory = panel
end)

-- Corpse Inventory Panel (dual inventory display)
local PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.corpseInventory)) then
		ix.gui.corpseInventory:Remove()
	end
	
	ix.gui.corpseInventory = self
	
	self:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	self:Center()
	self:MakePopup()
	self:SetTitle("")
	
	-- Close button
	self.closeButton = self:Add("DButton")
	self.closeButton:SetText("X")
	self.closeButton:SetSize(30, 30)
	self.closeButton:SetPos(self:GetWide() - 35, 5)
	self.closeButton.DoClick = function()
		self:Close()
	end
	
	-- Left side - Corpse inventory
	self.corpsePanel = self:Add("ixInventory")
	self.corpsePanel:SetPos(10, 40)
	self.corpsePanel:SetSize((self:GetWide() / 2) - 15, self:GetTall() - 50)
	self.corpsePanel:SetTitle("Corpse")
	self.corpsePanel.bNoBackgroundBlur = true
	self.corpsePanel:ShowCloseButton(false)
	
	-- Right side - Player inventory
	self.playerPanel = self:Add("ixInventory")
	self.playerPanel:SetPos((self:GetWide() / 2) + 5, 40)
	self.playerPanel:SetSize((self:GetWide() / 2) - 15, self:GetTall() - 50)
	self.playerPanel:SetTitle("Your Inventory")
	self.playerPanel.bNoBackgroundBlur = true
	self.playerPanel:ShowCloseButton(false)
	
	self.bNoBackgroundBlur = true
end

function PANEL:SetCorpseInventory(inventory, name)
	self.corpsePanel:SetInventory(inventory)
	self.corpsePanel:SetTitle(name or "Corpse")
	
	local character = LocalPlayer():GetCharacter()
	
	if (character) then
		local playerInventory = character:GetInventory()
		
		if (playerInventory) then
			self.playerPanel:SetInventory(playerInventory)
		end
	end
end

function PANEL:Close()
	netstream.Start("ixCorpseCloseInventory")
	self:Remove()
	
	if (ix.gui.corpseInventory == self) then
		ix.gui.corpseInventory = nil
	end
end

function PANEL:Paint(width, height)
	-- Draw background
	draw.RoundedBox(8, 0, 0, width, height, Color(40, 40, 40, 240))
	draw.RoundedBox(8, 2, 2, width - 4, height - 4, Color(20, 20, 20, 250))
	
	-- Draw title
	draw.SimpleText("Corpse Looting", "ixMediumFont", width / 2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	
	-- Draw divider line
	surface.SetDrawColor(100, 100, 100, 200)
	surface.DrawLine(width / 2, 40, width / 2, height - 10)
end

function PANEL:OnRemove()
	if (IsValid(self.corpsePanel)) then
		self.corpsePanel:Remove()
	end
	
	if (IsValid(self.playerPanel)) then
		self.playerPanel:Remove()
	end
end

vgui.Register("ixCorpseInventory", PANEL, "DFrame")
