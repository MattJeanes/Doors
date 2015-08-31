-- Adds an interior

if SERVER then
	local function FindPosition(self,e)
		local td={}
		td.start=self:GetPos()+Vector(0,0,99999999)
		td.endpos=self:GetPos()
		td.mins=e:OBBMins()
		td.maxs=e:OBBMaxs()
		td.filter={self,e}
		td.mask = MASK_NPCWORLDSTATIC
		local tr=util.TraceHull(td)
		if util.IsInWorld(tr.HitPos) then -- single trace worked
			return tr.HitPos
		else -- double trace needed
			td.start=tr.HitPos+Vector(0,0,-6000)
			td.endpos=tr.HitPos
			td.mask = nil
			tr=util.TraceHull(td)
			if util.IsInWorld(tr.HitPos) then
				return tr.HitPos
			else -- last resort, thanks SuperLlama (https://github.com/superllama/gravityhull/blob/9de1db246f4079a0965075e17ae8abf370b942f7/lua/gravityhull/sv_main.lua#L332-L342)
				local nowhere = vector_origin
				local max=16384
				td.mask=MASK_SOLID + CONTENTS_WATER
				td.start=nowhere
				td.endpos=nowhere
				while not ((util.PointContents(nowhere)==CONTENTS_EMPTY or util.PointContents(nowhere)==CONTENTS_TESTFOGVOLUME)
					and util.TraceHull(td).Hit
					and self:CallHook("AllowInteriorPos",nil,nowhere,mins,maxs)~=false)
				do
					tr.start=nowhere
					tr.endpos=nowhere
					nowhere = Vector(math.random(-max,max),math.random(-max,max),math.random(-max,max))
				end
				return nowhere
			end
		end
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
		local pos=FindPosition(self,e)
		if not util.IsInWorld(pos,e) then
			self:GetCreator():ChatPrint("WARNING: TARDIS unable to locate space for interior, respawn in open space or use a different map.")
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
		end
	end)
end