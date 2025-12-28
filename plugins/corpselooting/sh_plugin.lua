
local PLUGIN = PLUGIN

PLUGIN.name = "Corpse Looting"
PLUGIN.description = "Allows players to search corpses and loot their inventory."
PLUGIN.author = "Helix"

print("[CORPSE PLUGIN] Loading corpse looting plugin...")

if (SERVER) then
	util.AddNetworkString("ixCorpseSearch")
	util.AddNetworkString("ixCorpseOpenInventory")
	util.AddNetworkString("ixCorpseCloseInventory")
	print("[CORPSE PLUGIN] Server-side network strings registered")
	
	-- Create a corpse prop when player dies
	function PLUGIN:PlayerDeath(client, inflictor, attacker)
		print("[CORPSE] PlayerDeath called for", client:Name())
		
		local character = client:GetCharacter()
		
		if (!character) then 
			print("[CORPSE] No character found")
			return 
		end
		
		local inventory = character:GetInventory()
		if (!inventory) then 
			print("[CORPSE] No inventory found")
			return 
		end
		
		print("[CORPSE] Creating corpse at", client:GetPos())
		
		-- Create a corpse ragdoll prop at death location
		local corpse = ents.Create("prop_ragdoll")
		corpse:SetModel(client:GetModel())
		corpse:SetPos(client:GetPos())
		corpse:SetAngles(client:GetAngles())
		corpse:Spawn()
		corpse:Activate()
		
		print("[CORPSE] Corpse created:", IsValid(corpse))
		
		-- Copy the player's skin and bodygroups
		corpse:SetSkin(client:GetSkin())
		for i = 0, client:GetNumBodyGroups() - 1 do
			corpse:SetBodygroup(i, client:GetBodygroup(i))
		end
		
		-- Apply death velocity to make it look natural
		local velocity = client:GetVelocity()
		for i = 0, corpse:GetPhysicsObjectCount() - 1 do
			local bone = corpse:GetPhysicsObjectNum(i)
			if (IsValid(bone)) then
				bone:SetVelocity(velocity)
			end
		end
		
		-- Set up the corpse as a container
		local w = inventory.w or 6
		local h = inventory.h or 4
		local corpseInventory = ix.inventory.Create(w, h, os.time())
		corpseInventory:SetOwner(nil)
		corpseInventory.isCorpse = true -- Mark as corpse inventory
		
		-- Make the corpse act like a container
		corpse.ixInventory = corpseInventory
		corpse.ixCorpseName = character:GetName()
		corpse.GetDisplayName = function() return corpse.ixCorpseName .. "'s Corpse" end
		
		-- Transfer items to corpse inventory
		timer.Simple(0, function()
			if (!IsValid(corpse) or !corpseInventory) then return end
			
			local itemsToTransfer = {}
			for _, item in pairs(inventory:GetItems()) do
				table.insert(itemsToTransfer, item)
			end
			
			for _, item in ipairs(itemsToTransfer) do
				if (item and item.Transfer) then
					item:Transfer(corpseInventory:GetID(), item.gridX, item.gridY)
				end
			end
			
			print("[CORPSE] Transferred", #itemsToTransfer, "items to corpse container")
		end)
		
		-- Set collision
		corpse:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		
		-- Remove the corpse after 15 minutes and cleanup inventory
		timer.Simple(900, function()
			if (IsValid(corpse)) then
				print("[CORPSE] Removing corpse after 15 minutes")
				
				if (corpseInventory) then
					corpseInventory:Remove()
				end
				
				corpse:Remove()
			end
		end)
	end
	
	-- Handle player pressing E on corpse (use container system)
	function PLUGIN:PlayerUse(client, entity)
		if (entity:GetClass() == "prop_ragdoll" and entity.ixInventory) then
			-- Add cooldown to prevent spam
			local currentTime = CurTime()
			client.ixCorpseLastUse = client.ixCorpseLastUse or 0
			
			if (currentTime - client.ixCorpseLastUse < 5) then
				return false -- Still on cooldown
			end
			
			client.ixCorpseLastUse = currentTime
			
			local inventory = entity.ixInventory
			
			if (inventory) then
				ix.storage.Open(client, inventory, {
					entity = entity,
					name = entity:GetDisplayName()
				})
				
				return false
			end
		end
	end
	
	-- Allow multiple people to access corpses at the same time
	function PLUGIN:CanPlayerAccessStorage(client, inventory)
		-- Check if this is a corpse inventory
		if (inventory and inventory.isCorpse) then
			return true -- Always allow access to corpses
		end
	end
	
	-- Override the storage access check for corpses
	function PLUGIN:StorageCanOpen(client, inventory)
		if (inventory and inventory.isCorpse) then
			return true -- Skip the "someone else is using this" check
		end
	end
	
	-- Clean up when player disconnects
	function PLUGIN:PlayerDisconnected(client)
		-- Container system handles this automatically
	end
end

if (CLIENT) then
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
end
