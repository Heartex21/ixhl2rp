ITEM.name = "P-35 Gas Mask"
ITEM.description = "A resistance gas mask,crafted from scrap metal and other plastic materials. It provides decent protection against harmful smokes."
ITEM.category = "Outfit"
ITEM.model = Model("models/willardnetworks/update_items/m40_item.mdl")
ITEM.outfitCategory = "mask"
ITEM.bodyGroups = {
	["face"] = 3
}

function ITEM:OnEquipped()
    local faceIndex = self.player:FindBodygroupByName("face")
    if faceIndex >= 0 then
        self.player:SetBodygroup(faceIndex, 3)
    end
end

function ITEM:OnUnequipped()
    local faceIndex = self.player:FindBodygroupByName("face")
    if faceIndex >= 0 then
        self.player:SetBodygroup(faceIndex, 0)
    end
end