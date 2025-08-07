ITEM.name = "L2 Helmet"
ITEM.description = "A resistance helmet,crafted from scrap metal and other materials. It provides decent protection against small arms fire."
ITEM.model = Model("models/willardnetworks/clothingitems/head_helmet.mdl")
ITEM.category = "Outfit"
ITEM.outfitCategory = "hat"
ITEM.bodyGroups = {
	["head"] = 4
}

function ITEM:OnEquipped()
	self.player:SetArmor(self:GetData("armor", self.maxArmor))
end

function ITEM:OnUnequipped()
	self:SetData("armor", math.Clamp(self.player:Armor(), 0, self.maxArmor))
	self.player:SetArmor(0)
    self.bodyGroups = {
        ["head"] = 0
    }
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self.player:SetArmor(self:GetData("armor", self.maxArmor))
	end
end

function ITEM:OnSave()
	if (self:GetData("equip")) then
		self:SetData("armor", math.Clamp(self.player:Armor(), 0, self.maxArmor))
	end
end
