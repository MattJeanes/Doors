-- Doors

ENT:AddHook("Initialize", "doors", function(self)
	Doors:AddInterior(self)
end)

ENT:AddHook("OnRemove", "doors", function(self)
	Doors:RemoveInterior(self)
end)