-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

if SERVER then
	function ENT:IsStuck(ply)
		if ply:GetMoveType()==MOVETYPE_NOCLIP then return false end
		local pos=ply:GetPos()
		local td={}
		td.start=pos
		td.endpos=pos
		td.mins=ply:OBBMins()
		td.maxs=ply:OBBMaxs()
		td.filter={ply,unpack(self.stuckfilter)}
		local tr=util.TraceHull(td)
		return tr.Hit
	end
	
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		if self.portals then
			net.WriteEntity(self.portals[1])
			net.WriteEntity(self.portals[2])
		end
	end)
	
	ENT:AddHook("Initialize", "portals", function(self)
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
		self.portals[1]:Spawn()
		self.portals[1]:Activate()
		
		self.portals[2]:SetWidth(int.width)
		self.portals[2]:SetHeight(int.height)
		self.portals[2]:SetPos(self:LocalToWorld(int.pos))
		self.portals[2]:SetAngles(self:LocalToWorldAngles(int.ang))
		self.portals[2]:SetExit(self.portals[1])
		self.portals[2]:SetParent(self)
		self.portals[2]:Spawn()
		self.portals[2]:Activate()
		
		self.portals[1].TPHook = function(s,ent)
			if ent:IsPlayer() then
				self.exterior:PlayerEnter(ent,true)
				if self:IsStuck(ent) then
					self.exterior:PlayerExit(ent)
					self.exterior:PlayerEnter(ent)
				end
			end
		end
		
		self.portals[2].TPHook = function(s,ent)
			if ent:IsPlayer() then
				self.exterior:PlayerExit(ent,false,true)
				if self:IsStuck(ent) then
					self.exterior:PlayerEnter(ent)
					self.exterior:PlayerExit(ent)
				end
			end
		end
	end)
else
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		local portal1=net.ReadEntity()
		local portal2=net.ReadEntity()
		if IsValid(portal1) and IsValid(portal2) then
			self.portals={}
			self.portals[1]=portal1
			self.portals[2]=portal2
		end
	end)
	
	ENT:AddHook("ShouldDraw", "portals", function(self)
		if wp.drawing and wp.drawingent and wp.drawingent:GetParent()~=self.exterior then
			return false
		end
	end)
	
	hook.Add("wp-shouldrender", "doors-portals", function(portal,exit,origin)
		local p=portal:GetParent()
		if IsValid(p) and p.DoorInterior and p._init and LocalPlayer().doori~=p then
			return false
		end
	end)
end