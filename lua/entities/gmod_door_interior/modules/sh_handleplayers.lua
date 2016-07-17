-- Handles players inside the interior

function ENT:PositionInside(pos)
	if self.ExitBox and (pos:WithinAABox(self:LocalToWorld(self.ExitBox.Min),self:LocalToWorld(self.ExitBox.Max))) then
		return true
	elseif self.ExitDistance and pos:Distance(self:GetPos()) < self.ExitDistance then
		return true
	end
	return false
end

if SERVER then	
	function ENT:CheckPlayer(ply,portal)
		local inbox = self:PositionInside(ply:GetPos())
		if self.occupants[ply] and not inbox then
			--print("out",self,ply,ply.door,ply.doori)
			self.exterior:PlayerExit(ply,true,IsValid(portal))
			if IsValid(portal) and IsValid(portal.interior) and portal.interior.DoorInterior then
				portal.interior:CheckPlayer(ply,true)
			end
		elseif not self.occupants[ply] and inbox then
			--print("in",self,ply,ply:GetPos())
			self.exterior:PlayerEnter(ply,true)
		end
	end
	
	ENT:AddHook("Think", "handleplayers", function(self)
		for k,v in pairs(player.GetAll()) do
			self:CheckPlayer(v)
		end
	end)
	
	hook.Add("wp-teleport","doors-handleplayers",function(portal,ent)
		if ent:IsPlayer() then
			for k,v in pairs(Doors:GetInteriors()) do
				k:CheckPlayer(ent,portal)
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