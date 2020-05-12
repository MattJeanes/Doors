-- Handles players

if SERVER then
	util.AddNetworkString("Doors-EnterExit")
	
	function ENT:PlayerEnter(ply,notp)
		if ply.doors_cooldowncur and ply.doors_cooldowncur>CurTime() then return end
		if self.occupants[ply] then
			return
		end
		local allowed,allowforced = self:CallHook("CanPlayerEnter",ply)
		if allowed==false and not allowforced then
			return
		end
		if IsValid(ply.door) and ply.door~=self then
			ply.door:PlayerExit(ply,true,true)
		end
		self.occupants[ply]=true
		net.Start("Doors-EnterExit")
			net.WriteBool(true)
			net.WriteEntity(self)
			net.WriteEntity(self.interior)
		net.Send(ply)
		ply.door = self
		ply.doori = self.interior
		if IsValid(self.interior) then
			local portals=self.interior.portals
			if (not notp) and portals and self.interior.Fallback then
				local pos=self:WorldToLocal(ply:GetPos())
				ply:SetPos(self.interior:LocalToWorld(self.interior.Fallback.pos))
				local ang=wp.TransformPortalAngle(ply:EyeAngles(),portals.exterior,portals.interior)
				local fwd=wp.TransformPortalAngle(ply:GetVelocity():Angle(),portals.exterior,portals.interior):Forward()
				ply:SetEyeAngles(Angle(ang.p,ang.y,0))
				ply:SetLocalVelocity(fwd*ply:GetVelocity():Length())
			end
		end
		self:CallHook("PlayerEnter", ply, notp)
		if IsValid(self.interior) then
			self.interior:CallHook("PlayerEnter", ply, notp)
		end
	end

	function ENT:PlayerExit(ply,forced,notp)
		if self:CallHook("CanPlayerExit",ply)==false and (not forced) then
			return
		end
		self:CallHook("PlayerExit", ply, forced, notp)
		if IsValid(self.interior) then
			self.interior:CallHook("PlayerExit", ply, forced, notp)
		end
		if not IsValid(self.interior) then
			-- spectator mode doesn't exit properly without respawning
			local pos,ang=ply:GetPos(),ply:EyeAngles()
			local hp,armor=ply:Health(),ply:Armor()
			local weps={}
			local ammo={}
			for k,v in pairs(ply:GetWeapons()) do
				table.insert(weps, v:GetClass())
				local p=v:GetPrimaryAmmoType()
				local s=v:GetSecondaryAmmoType()
				if p != -1 then
					ammo[p]=ply:GetAmmoCount(p)
				end
				if s != -1 then
					ammo[s]=ply:GetAmmoCount(s)
				end
			end
			--[[ restoring active wep doesn't work clientside properly
			local activewep
			if IsValid(ply:GetActiveWeapon()) then
				activewep=ply:GetActiveWeapon():GetClass()
			end
			]]--
			
			ply:Spawn()
			
			ply:SetPos(pos)
			ply:SetEyeAngles(ang)
			ply:SetHealth(hp)
			ply:SetArmor(armor)
			for k,v in pairs(weps) do
				ply:Give(tostring(v))
			end
			for k,v in pairs(ammo) do
				ply:SetAmmo(v,k)
			end
			ply.doors_cooldowncur=CurTime()+1
		end
		--if ply:InVehicle() then ply:ExitVehicle() end
		self.occupants[ply]=nil
		net.Start("Doors-EnterExit")
			net.WriteBool(false)
			net.WriteEntity(self)
			net.WriteEntity(self.interior)
		net.Send(ply)
		ply.door = nil
		ply.doori = nil
		if not notp and self.Fallback then
			ply:SetPos(self:LocalToWorld(self.Fallback.pos))
			if IsValid(self.interior) then
				local portals=self.interior.portals
				if (not forced) and portals then
					local ang=wp.TransformPortalAngle(ply:EyeAngles(),portals.interior,portals.exterior)
					local fwd=wp.TransformPortalAngle(ply:GetVelocity():Angle(),portals.interior,portals.exterior):Forward()
					ply:SetEyeAngles(Angle(ang.p,ang.y,0))
					ply:SetLocalVelocity(fwd*ply:GetVelocity():Length())
				end
			end
		end
		self:CallHook("PostPlayerExit", ply, forced, notp)
		if IsValid(self.interior) then
			self.interior:CallHook("PostPlayerExit", ply, forced, notp)
		end
	end
	
	hook.Add("wp-shouldtp", "doors-players", function(self,ent)
		local e=self:GetParent()
		if IsValid(e) and IsValid(ent) and ent:IsPlayer() and (e.DoorExterior or e.DoorInterior) then
			if (e.DoorExterior and e or e.exterior):CallHook(e.DoorExterior and "CanPlayerEnter" or "CanPlayerExit",ent)==false then
				return false
			end
		end
	end)
else	
	net.Receive("Doors-EnterExit", function()
		local enter=net.ReadBool()
		local ext=net.ReadEntity()
		local int=net.ReadEntity()
		
		if enter then
			LocalPlayer().door=ext
			LocalPlayer().doori=int
		else
			LocalPlayer().door=nil
			LocalPlayer().doori=nil
		end
		
		if IsValid(ext) then
			if enter then
				ext:CallHook("PlayerEnter")
			else
				ext:CallHook("PlayerExit")
			end
		end
		
		if IsValid(int) then
			if enter then
				int:CallHook("PlayerEnter")
			else
				int:CallHook("PlayerExit")
			end
		end
	end)
end