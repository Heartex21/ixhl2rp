
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Combine Terminal"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
end

function ENT:Initialize()
	self:SetModel("models/props_combine/combine_interface001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	
	local physObj = self:GetPhysicsObject()
	if IsValid(physObj) then
		physObj:EnableMotion(false)
	end
	
	-- Start looping hum sound
	self.nextSoundTime = 0
end

function ENT:Think()
	-- Keep hum sound playing in loop
	if CurTime() >= self.nextSoundTime then
		self:EmitSound("hl2rp/terminal-hum.wav", 60, 100, 0.3, CHAN_STATIC)
		-- Restart sound every 10 seconds (adjust based on your sound file length)
		self.nextSoundTime = CurTime() + 10
	end
	
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer() then
		net.Start("ixOpenCombineTerminal")
		net.Send(caller)
	end
end

function ENT:OnRemove()
	-- Stop looping sound
	self:StopSound("hl2rp/terminal-hum.wav")
end

if SERVER then
	util.AddNetworkString("ixOpenCombineTerminal")
end
