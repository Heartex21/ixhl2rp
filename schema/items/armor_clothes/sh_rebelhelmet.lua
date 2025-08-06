ITEM.name = "L2 Helmet"
ITEM.description = "A resistance helmet,crafted from scrap metal and other materials. It provides decent protection against small arms fire."
ITEM.category = "Outfit"
ITEM.outfitCategory = "hat"
ITEM.bodyGroups = {
	["head"] = 4
}

function ITEM:OnEquipped()
    -- Ensure the armor value is not reset unnecessarily
    if not self.armor then
        self.armor = self.maxArmor
    end
end

function ITEM:OnUnequipped()
    self.bodyGroups = {
        ["head"] = 0
    }
end