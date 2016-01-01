-- Entities

Doors.Interiors={}
function Doors:AddInterior(e)
	self.Interiors[e]=true
end
function Doors:RemoveInterior(e)
	self.Interiors[e]=nil
end
function Doors:GetInteriors()
	return self.Interiors
end

Doors.Exteriors={}
function Doors:AddExterior(e)
	self.Exteriors[e]=true
end
function Doors:RemoveExterior(e)
	self.Exteriors[e]=nil
end
function Doors:GetExteriors()
	return self.Exteriors
end