local _, ns = ...

-- HydraUI's unit-frame runtime reuses the element implementations and a small
-- subset of the frame helpers after oUF has finished loading.  Preserve only
-- that explicit boundary before removing the rest of oUF's private API.
ns.UnitFrameOUFBridge = {
	elements = ns.oUF.Private.elements,
	frameMethods = ns.oUF.Private.frame_metatable.__index,
}

-- It's named Private for a reason!
ns.oUF.Private = nil
