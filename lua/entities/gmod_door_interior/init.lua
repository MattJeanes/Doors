AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:SpawnFunction( ply, tr, ClassName )
	if not tr.Hit then return end
	local SpawnPos = tr.HitPos + tr.HitNormal
	local ent = ents.Create( ClassName )
	ent:SetPos(SpawnPos)
	local ang=Angle(0, (ply:GetPos()-SpawnPos):Angle().y, 0)
	ent:SetAngles(ang)
	Doors:SetupOwner(ply)
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:InitializePlayer(ply)
	net.Start("DoorsI-Initialize")
		net.WriteEntity(self)
		net.WriteEntity(self.exterior)
		net.WriteEntity(self:GetCreator())
		self:CallHook("PlayerInitialize", ply)
	net.Send(ply)
	self:CallHook("PostPlayerInitialize", ply)
end

util.AddNetworkString("DoorsI-Initialize")
net.Receive("DoorsI-Initialize", function(len,ply)
	local int=net.ReadEntity()
	if IsValid(int) then
		if int.spacecheck then
			int.initqueue[ply] = true
		else
			int:InitializePlayer(ply)
		end
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
		self.lastthink = CurTime()
		self.initqueue = {}
	else
		self:CallHook("Initialize")
		self._init = true
		self:CallHook("PostInitialize")
	end
end

ENT:AddHook("PostInitialize","interior",function(self)
	if self.initqueue then
		for k,v in pairs(self.initqueue) do
			self:InitializePlayer(k)
		end
		self.initqueue=nil
	end
end)

function ENT:Think()
	for k,v in pairs(self.occupants) do
		if not k or not IsValid(k) then
			self.occupants[k]=nil
		end
	end
	self:CallHook("Think",CurTime()-self.lastthink)
	self.lastthink=CurTime()
	if self:CallHook("ShouldThinkFast") then
		self:NextThink(CurTime())
		return true
	end
end