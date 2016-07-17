include('shared.lua')

function ENT:Draw()
	if self._init and self:CallHook("ShouldDraw")~=false then
		self:CallHook("PreDraw")
		if self.CustomDrawModel then
			self:CustomDrawModel()
		else
			self:DrawModel()
		end
		if WireLib then
			Wire_Render(self)
		end
		self:CallHook("Draw")
	end
end

net.Receive("DoorsI-Initialize", function(len)
	local int=net.ReadEntity()
	local ext=net.ReadEntity()
	local ply=net.ReadEntity()
	if IsValid(int) and IsValid(ext) then
		int.exterior=ext
		int:SetCreator(ply)
		int.phys=int:GetPhysicsObject()
		int:CallHook("PlayerInitialize")
		int:CallHook("Initialize")
		int._init=true
	end
end)
function ENT:Initialize()
	net.Start("DoorsI-Initialize") net.WriteEntity(self) net.SendToServer()
	self.nextslowthink=0
end

function ENT:Think()
	if self._init then
		self:CallHook("Think",FrameTime())
		if CurTime()>=self.nextslowthink then
			self.nextslowthink=CurTime()+1
			self:CallHook("SlowThink")
		end
	end
end