AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:SpawnFunction( ply, tr, ClassName )
	if (  !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	local ang=Angle(0, (ply:GetPos()-SpawnPos):Angle().y, 0)
	ent:SetAngles( ang )
	ent:SetCreator( ply )
	ent:Spawn()
	ent:Activate()
	return ent
end

util.AddNetworkString("DoorsI-Initialize")
net.Receive("DoorsI-Initialize", function(len,ply)
	local int=net.ReadEntity()
	if IsValid(int) then
		net.Start("DoorsI-Initialize")
			net.WriteEntity(int)
			net.WriteEntity(int.exterior)
			net.WriteEntity(int:GetCreator())
			int:CallHook("PlayerInitialize", ply)
		net.Send(ply)
		int:CallHook("PostPlayerInitialize", ply)
	end
end)
function ENT:Initialize()
	if self.spacecheck then
		if not (self.exterior and IsValid(self.exterior)) then
			error("Exterior not set, removing!")
			self:Remove()
		end
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		
		self.phys = self:GetPhysicsObject()
		if (self.phys:IsValid()) then
			self.phys:EnableMotion(false)
		end
		
		self.occupants = {}
		self.stuckfilter = {}
	else
		self:CallHook("Initialize")
	end
end

function ENT:Think()
	for k,v in pairs(self.occupants) do
		if not k or not IsValid(k) then
			self.occupants[k]=nil
		end
	end
	self:CallHook("Think")
end