-- Hooks

hook.Add("PostDrawTranslucentRenderables", "doors-i", function()
	for k,v in pairs(Doors:GetInteriors()) do
		if IsValid(k) then
			k:CallHook("PostDrawTranslucentRenderables")
		end
	end
end)