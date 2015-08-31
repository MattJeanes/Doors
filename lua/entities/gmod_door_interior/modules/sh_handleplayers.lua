-- Handles players inside the tardis interior

if SERVER then
	ENT:AddHook("Think", "handleplayers", function(self)
		local pos=self:GetPos()
		for k,v in pairs(self.occupants) do
			if k:GetPos():Distance(pos) > 600 then
				self.exterior:PlayerExit(k,true)
			end
		end
	end)
else
	ENT:AddHook("ShouldDraw", "players", function(self)
		if (LocalPlayer().doori~=self) and not wp.drawing then
			return false
		end
	end)
	ENT:AddHook("ShouldThink", "players", function(self)
		if LocalPlayer().doori~=self then
			return false
		end
	end)
end