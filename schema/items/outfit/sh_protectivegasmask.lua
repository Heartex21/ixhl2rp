ITEM.name = "P-35 Gas Mask"
ITEM.description = "A resistance gas mask,crafted from scrap metal and other plastic materials. It provides decent protection against harmful smokes."
ITEM.category = "Outfit"
ITEM.model = Model("models/willardnetworks/update_items/m40_item.mdl")
ITEM.outfitCategory = "mask"

function ITEM:OnEquipped()
    self.bodyGroups = self.bodygroups or {}
    self.bodyGroups["face"] = 1
end

function ITEM:OnUnequipped()
    self.bodyGroups = self.bodyGroups or {}
    self.bodyGroups["face"] = 0
end