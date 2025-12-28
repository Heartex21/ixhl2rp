
local PLUGIN = PLUGIN

print("[CORPSE] sv_hooks.lua loaded")

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
	
	-- Mark this as a lootable corpse
	corpse.ixCorpseInventory = inventory:GetID()
	corpse.ixCorpseCharacter = character:GetID()
	corpse.ixCorpseName = character:GetName()
	corpse.ixCorpseSearching = {}
	
	print("[CORPSE] Marked with inventory ID:", corpse.ixCorpseInventory)
	
	-- Set collision
	corpse:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	-- Remove the corpse after 15 minutes
	timer.Simple(900, function()
		if (IsValid(corpse)) then
			print("[CORPSE] Removing corpse after 15 minutes")
			corpse:Remove()
		end
	end)
end

-- Handle player pressing E on corpse
function PLUGIN:PlayerUse(client, entity)
	if (entity:GetClass() == "prop_ragdoll" and entity.ixCorpseInventory) then
		-- Check distance
		if (client:GetPos():Distance(entity:GetPos()) > 150) then
			return
		end
		
		-- Check if already searching
		if (entity.ixCorpseSearching[client]) then
			return false
		end
		
		-- Start searching
		entity.ixCorpseSearching[client] = true
		client:SetAction("Searching corpse...", 3)
		
		client:DoStaredAction(entity, function()
			-- After 3 seconds, open the inventory
			if (IsValid(entity) and entity.ixCorpseInventory) then
				local inventory = ix.item.inventories[entity.ixCorpseInventory]
				
				if (inventory) then
					-- Open the corpse inventory for the client
					inventory:Sync(client, true)
					
					netstream.Start(client, "ixCorpseOpenInventory", {
						entity = entity:EntIndex(),
						inventory = entity.ixCorpseInventory,
						name = entity.ixCorpseName or "Unknown"
					})
					
					client.ixCorpseEntity = entity
				end
			end
			
			entity.ixCorpseSearching[client] = nil
		end, 3, function()
			-- On fail/cancel
			if (IsValid(entity)) then
				entity.ixCorpseSearching[client] = nil
			end
		end)
		
		return false -- Prevent default use behavior
	end
end

-- Handle closing the corpse inventory
netstream.Hook("ixCorpseCloseInventory", function(client)
	if (IsValid(client.ixCorpseEntity) and client.ixCorpseEntity.ixCorpseInventory) then
		local inventory = ix.item.inventories[client.ixCorpseEntity.ixCorpseInventory]
		
		if (inventory) then
			inventory:Sync(client, false)
		end
		
		client.ixCorpseEntity = nil
	end
end)

-- Clean up when player disconnects
function PLUGIN:PlayerDisconnected(client)
	if (IsValid(client.ixCorpseEntity)) then
		local entity = client.ixCorpseEntity
		
		if (entity.ixCorpseSearching) then
			entity.ixCorpseSearching[client] = nil
		end
	end
end
