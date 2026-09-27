import re
import unittest
from pathlib import Path


GUI_SOURCE = Path(__file__).parents[1] / "HydraUI/Elements/GUI/GUI.lua"


class PageModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = GUI_SOURCE.read_text(encoding="utf-8")

    def function_body(self, start, end):
        match = re.search(
            rf"{re.escape(start)}(?P<body>.*?){re.escape(end)}",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(match, f"could not find {start}")
        return match.group("body")

    def test_multiple_child_callbacks_reuse_the_page_descriptor(self):
        helper = self.function_body(
            "local GetOrCreatePage = function", "local QueuePage = function"
        )
        add_widgets = self.function_body(
            "function GUI:AddWidgets", "function GUI:GetWidget"
        )

        self.assertIn("local Page = Category.PageLookup[name]", helper)
        self.assertIn("if Page then", helper)
        self.assertIn("tinsert(Page.Callbacks, arg2)", add_widgets)
        self.assertNotIn("NewPage(Category, name)", add_widgets)

    def test_page_queue_contains_descriptors_only_once(self):
        queue_page = self.function_body(
            "local QueuePage = function", "local ScrollWidgetColumn = function"
        )
        add_widgets = self.function_body(
            "function GUI:AddWidgets", "function GUI:GetWidget"
        )

        self.assertIn("if page.Queued then", queue_page)
        self.assertIn("page.Queued = true", queue_page)
        self.assertIn("tinsert(self.ButtonQueue, page)", queue_page)
        self.assertIn("QueuePage(self, Page)", add_widgets)

    def test_category_order_and_lookup_are_separate(self):
        storage = self.function_body("-- Storage", "local NewPage = function")

        self.assertIn("GUI.CategoryOrder = {}", storage)
        self.assertIn("GUI.Categories = {}", storage)
        self.assertIn("self.Categories[name] = Category", storage)
        self.assertIn("tinsert(self.CategoryOrder, Category)", storage)

    def test_page_descriptor_owns_navigation_state(self):
        descriptor = self.function_body(
            "local NewPage = function", "local GetOrCreatePage = function"
        )

        for field in (
            "Category",
            "Name",
            "Parent",
            "Children",
            "Callbacks",
            "Expanded",
            "Button",
            "Window",
        ):
            self.assertRegex(descriptor, rf"\b{field}\s*=")

    def test_registration_validation_reports_invalid_relationships(self):
        helper = self.function_body(
            "local GetOrCreatePage = function", "local QueuePage = function"
        )
        validation = self.function_body(
            "local ValidatePages = function", "local ScrollWidgetColumn = function"
        )

        self.assertIn("Duplicate GUI page identity", helper)
        self.assertIn("references missing parent page", validation)


if __name__ == "__main__":
    unittest.main()
