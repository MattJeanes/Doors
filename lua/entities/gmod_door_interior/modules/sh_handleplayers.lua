-- Handles players inside the interior

if SERVER then
	ENT:AddHook("Think", "handleplayers", function(self)
		local pos=self:GetPos()
		for k,v in pairs(self.occupants) do
			local exit
			if self.ExitBox and (not k:GetPos():WithinAABox(self:LocalToWorld(self.ExitBox.Min),self:LocalToWorld(self.ExitBox.Max))) then
				exit=true
			elseif self.ExitDistance and k:GetPos():Distance(pos) > self.ExitDistance then
				exit=true
			end
			if exit then
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