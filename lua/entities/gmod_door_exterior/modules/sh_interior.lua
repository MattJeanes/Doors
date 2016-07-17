-- Adds an interior

if SERVER then
	function ENT:FindPosition(e)
		local td={}
		td.mins=e.mins or e:OBBMins()
		td.maxs=e.maxs or e:OBBMaxs()		
		local max=16384
		local tries=10000
		local nowhere
		local highest
		while tries>0 do
			tries=tries-1
			nowhere=Vector(math.random(-max,max),math.random(-max,max),math.random(-max,max))
			td.start=nowhere
			td.endpos=nowhere
			if (not util.TraceHull(td).Hit)
				and (self:CallHook("AllowInteriorPos",nil,nowhere,mins,maxs)~=false)
				and ((not highest) or (highest and nowhere.z>highest.z))
			then
				highest = nowhere
			end
		end
		return highest
	end
	
	ENT:AddHook("Initialize", "interior", function(self)
		local e=ents.Create(self.Interior)
		e.spacecheck=true
		e.exterior=self
		e.ID=self.ID
		e:SetCreator(self:GetCreator())
		if CPPI then
			e:CPPISetOwner(self:GetCreator())
		end
		e:Spawn()
		e:Activate()
		e:CallHook("PreInitialize")
		local pos=self:FindPosition(e)
		if not pos then
			self:GetCreator():ChatPrint("WARNING: Unable to locate space for interior, respawn in open space or use a different map.")
			e:Remove()
			return
		end
		e:SetPos(pos)
		self:DeleteOnRemove(e)
		e:DeleteOnRemove(self)
		e.occupants=self.occupants -- Hooray for referenced tables
		self.interior=e
		e.spacecheck=nil
		e:Initialize()
	end)
	
	ENT:AddHook("OnRemove", "interior", function(self)
		for k,v in pairs(self.occupants) do
			self:PlayerExit(k,true)
			for int in pairs(Doors:GetInteriors()) do
				int:CheckPlayer(k)
			end
		end
	end)
else	
	ENT:AddHook("SlowThink","interior",function(self)
		local inside
		for k,v in pairs(Doors:GetInteriors()) do
			if k:PositionInside(self:GetPos()) then
				inside=k
				break
			end
		end
		if IsValid(inside) then
			if self.insideof~=inside then
				if IsValid(self.insideof) and self.insideof.contains then
					self.insideof.contains[self]=nil
				end
				self.insideof=inside
			end
			if inside.contains then
				inside.contains[self]=true
			end
		elseif IsValid(self.insideof) and self.insideof.contains then
			self.insideof.contains[self]=nil
			self.insideof=nil
		end
	end)
	
	ENT:AddHook("OnRemove","interior",function(self)
		for k,v in pairs(Doors:GetInteriors()) do
			if k.contains and k.contains[self] then
				k.contains[self] = nil
			end
		end
	end)
end