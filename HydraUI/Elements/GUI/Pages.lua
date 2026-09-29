local HydraUI = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local tinsert = table.insert

function GUI:GetCategoryDescriptor(name)
	local self = self
	local Category = self.Categories[name]

	if (not Category) then
		Category = {Name = name, Pages = {}, PageLookup = {}}
		self.Categories[name] = Category
		tinsert(self.CategoryOrder, Category)
		self.Pages[name] = Category.PageLookup
	end

	return Category
end

local NewPage = function(category, name)
	return {
		Category = category,
		Name = name,
		Parent = nil,
		Children = {},
		ChildLookup = {},
		Callbacks = {},
		Expanded = false,
		Button = nil,
		Window = nil,
	}
end

function GUI:GetOrCreatePage(categoryName, name, parentName)
	local self = self
	local Category = self:GetCategoryDescriptor(categoryName)
	local Page = Category.PageLookup[name]
	local ParentPage

	if parentName then
		if (name == parentName) then
			error(format("GUI page '%s/%s' cannot be its own parent", categoryName, name), 3)
		end

		ParentPage = Category.PageLookup[parentName]

		if (not ParentPage) then
			ParentPage = NewPage(Category, parentName)
			Category.PageLookup[parentName] = ParentPage
			tinsert(Category.Pages, ParentPage)
		end
	end

	if Page then
		if (Page.Parent ~= ParentPage) then
			error(format("Duplicate GUI page identity '%s/%s' registered with different parents", categoryName, name), 3)
		end
	else
		Page = NewPage(Category, name)
		Page.Parent = ParentPage
		Category.PageLookup[name] = Page

		if ParentPage then
			ParentPage.ChildLookup[name] = Page
			tinsert(ParentPage.Children, Page)
		else
			tinsert(Category.Pages, Page)
		end
	end

	Page.Defined = true

	return Page
end

function GUI:QueuePage(page)
	local self = self
	if page.Queued then
		return
	end

	page.Queued = true
	tinsert(self.ButtonQueue, page)
end

function GUI:ValidatePages()
	local self = self
	for i = 1, #self.CategoryOrder do
		local Category = self.CategoryOrder[i]

		for _, Page in next, Category.PageLookup do
			if (not Page.Defined) then
				error(format("GUI category '%s' references missing parent page '%s'", Category.Name, Page.Name), 3)
			elseif Page.Parent and Page.Parent.Parent then
				error(format("GUI page '%s/%s' has nested parent '%s'; only one child level is supported", Category.Name, Page.Name, Page.Parent.Name), 3)
			end
		end
	end
end


function GUI:HasButton(category, name, parent)
	local Category = self.Categories[category]
	local Page = Category and Category.PageLookup[name]

	if Page and ((not parent and not Page.Parent) or (Page.Parent and Page.Parent.Name == parent)) then
		return Page
	end
end


function GUI:AddWidgets(category, name, arg1, arg2)
	if (type(arg1) == "function") then
		local Page = self:GetOrCreatePage(category, name)

		tinsert(Page.Callbacks, arg1)
		self:QueuePage(Page)
	else -- string
		local Page = self:GetOrCreatePage(category, name, arg1)

		tinsert(Page.Callbacks, arg2)
		self:QueuePage(Page)
	end
end

