include('shared.lua')

local meta=FindMetaTable("Entity")
if not meta.SetCreator and not meta.GetCreator then
	function meta:SetCreator(creator)
		self._creator=creator
	end

	function meta:GetCreator(creator)
		return self._creator
	end
end

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

net.Receive("Doors-Initialize", function(len)
	local ext=net.ReadEntity()
	local int=net.ReadEntity()
	local ply=net.ReadEntity()
	if IsValid(ext) and IsValid(ply) then
		ext.interior=int
		ext:SetCreator(ply)
		ext.phys=ext:GetPhysicsObject()
		ext:CallHook("PlayerInitialize")
		ext:CallHook("Initialize")
		ext._init=true
	end
end)
function ENT:Initialize()
	net.Start("Doors-Initialize") net.WriteEntity(self) net.SendToServer()
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