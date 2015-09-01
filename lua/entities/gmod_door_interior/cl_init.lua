include('shared.lua')

function ENT:Draw()
	if self._init and self:CallHook("ShouldDraw")~=false then
		self:CallHook("PreDraw")
		self:DrawModel()
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
end

function ENT:Think()
	if self._init then
		self:CallHook("Think")
	end
end

hook.Add("PostDrawTranslucentRenderables", "TARDIS", function(...)
	for k,v in pairs(ents.FindByClass("gmod_door_interior")) do
		v:CallHook("PostDrawTranslucentRenderables",...)
	end
end)