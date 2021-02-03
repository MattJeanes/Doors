-- Cordon

ENT:AddHook("PreRenderPortal", "cordon", function(self,portal)
	if portal ~= self.portals.interior then return end
	for k,v in pairs(self.props) do
		if IsValid(k) then
			k.olddraw=k:GetNoDraw()
			k:SetNoDraw(true)
		end
	end
end)

ENT:AddHook("PostRenderPortal", "cordon", function(self,portal)
	if portal ~= self.portals.interior then return end
	for k,v in pairs(self.props) do
		if IsValid(k) and k.olddraw~=nil then
			k:SetNoDraw(k.olddraw)
			k.olddraw=nil
		end
	end
end)

ENT:AddHook("Initialize", "cordon", function(self)
	self.props={}
	self.propscan=0
	if not (self.mins and self.maxs) then
		self.mins,self.maxs=self:OBBMins()*0.95, self:OBBMaxs()*0.95
	end
end)

local blacklist={
	["player"] = true,
	["viewmodel"] = true
}

ENT:AddHook("Cordon", "cordon", function(self,class,ent)
	if ent.DoorInterior then return false end
end)

function ENT:UpdateCordon()
	for k,v in pairs(ents.FindInBox(self:LocalToWorld(self.mins),self:LocalToWorld(self.maxs))) do
		local check=true
		local class=v:GetClass()
		if blacklist[class] or self:CallHook("Cordon",class,v)==false then
			check=false
		end
		local p=v:GetParent()
		if IsValid(p) then
			local class=p:GetClass()
			if blacklist[class] or self:CallHook("Cordon",class,p)==false then
				check=false
			end
		end
		if check then
			-- if not self.props[v] then
			-- 	print("enter",v)
			-- end
			self.props[v]=1
			if v.doors_cordon==nil then
				v.doors_cordon=v:GetNoDraw()
			end
		end
	end
	for k,v in pairs(self.props) do
		if IsValid(k) then
			if v==true then -- left
				k:SetNoDraw(k.doors_cordon)
				k.doors_cordon=nil
				self.props[k]=nil
				-- print("exit",k)
			elseif v==1 then
				self.props[k]=true
			end
		else
			self.props[k]=nil
		end
	end
end

ENT:AddHook("OnRemove", "cordon", function(self)
	if self.props then
		for k,v in pairs(self.props) do
			if IsValid(k) then
				--print("onremove",k)
				k:SetNoDraw(k.doors_cordon)
				k.doors_cordon=nil
				self.props[k]=nil
			end
		end
	end
end)

ENT:AddHook("Think", "cordon", function(self)
	if CurTime()>self.propscan then
		self.propscan=CurTime()+1
		self:UpdateCordon()
	end
	local inside=LocalPlayer().doori==self or self.contains[LocalPlayer().door] or false
	for k,v in pairs(self.props) do
		if IsValid(k) and k:GetNoDraw()==inside then
			-- Need to do this every frame unfortunately as GMod resets it really fast
			k:SetNoDraw(not inside)
		end
	end
end)

ENT:AddHook("PlayerEnter", "cordon", function(self)
	self:UpdateCordon()
end)

ENT:AddHook("PlayerExit", "cordon", function(self)
	self:UpdateCordon()
end)