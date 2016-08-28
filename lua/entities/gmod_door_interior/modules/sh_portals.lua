-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

if SERVER then	
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		if self.portals then
			net.WriteEntity(self.portals[1])
			net.WriteEntity(self.portals[2])
		end
	end)
	
	ENT:AddHook("PreInitialize", "portals", function(self)
		local int=self.Portal
		local ext=self.exterior.Portal
		if not (int and ext) then return end
		self.portals={}
		self.portals[1]=ents.Create("linked_portal_door")
		self.portals[2]=ents.Create("linked_portal_door")
		
		self.portals[1]:SetWidth(ext.width)
		self.portals[1]:SetHeight(ext.height)
		self.portals[1]:SetPos(self.exterior:LocalToWorld(ext.pos))
		self.portals[1]:SetAngles(self.exterior:LocalToWorldAngles(ext.ang))
		self.portals[1]:SetExit(self.portals[2])
		self.portals[1]:SetParent(self.exterior)
		self.portals[1].exterior = self.exterior
		self.portals[1].interior = self
		self.portals[1]:Spawn()
		self.portals[1]:Activate()
		
		self.portals[2]:SetWidth(int.width)
		self.portals[2]:SetHeight(int.height)
		self.portals[2]:SetPos(self:LocalToWorld(int.pos))
		self.portals[2]:SetAngles(self:LocalToWorldAngles(int.ang))
		self.portals[2]:SetExit(self.portals[1])
		self.portals[2]:SetParent(self)
		self.portals[2].interior = self
		self.portals[2].exterior = self.exterior
		self.portals[2]:Spawn()
		self.portals[2]:Activate()
	end)
else
	ENT:AddHook("Initialize","interior",function(self)
		self.contains = {}
	end)
	
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		local portal1=net.ReadEntity()
		local portal2=net.ReadEntity()
		if IsValid(portal1) and IsValid(portal2) then
			self.portals={}
			self.portals[1]=portal1
			self.portals[1].exterior=self.exterior
			self.portals[1].interior=self
			
			self.portals[2]=portal2
			self.portals[2].exterior=self.exterior
			self.portals[2].interior=self
		end
	end)
	
	ENT:AddHook("ShouldDraw", "portals", function(self)
		local insideof = IsValid(wp.drawingent) and wp.drawingent.exterior and wp.drawingent.exterior.insideof==self and wp.drawingent.interior.portals[2]==wp.drawingent
		if wp.drawing and wp.drawingent and wp.drawingent~=self.portals[1] and not (wp.drawingent==self.portals[2] and self.props[self.exterior]) and (not insideof) then
			return false
		end
	end)
	
	hook.Add("wp-shouldrender", "doors-portals", function(portal,exit,origin)
		local p=portal:GetParent()
		if IsValid(p) and p.DoorInterior and ((p._init and LocalPlayer().doori~=p) or (not p._init)) then
			return false
		end
	end)
end