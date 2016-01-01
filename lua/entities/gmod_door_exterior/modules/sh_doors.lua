-- Doors

ENT:AddHook("Initialize", "doors", function(self)
	Doors:AddExterior(self)
end)

ENT:AddHook("OnRemove", "doors", function(self)
	Doors:RemoveExterior(self)
end)