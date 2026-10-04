local _, ns = ...

-- Element files register focused installers before the Unit Frames module exists.
-- Compose them here once UnitFrames.lua creates the shared module.
ns.UnitFrameComponentFactory = function(UF, Hider)
	for i = 1, #ns.UnitFrameElementInstallers do
		ns.UnitFrameElementInstallers[i](UF, Hider)
	end
end
