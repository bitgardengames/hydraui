import re
import unittest
from pathlib import Path


GUI_SOURCE = Path(__file__).parents[1] / "HydraUI/Elements/GUI/GUI.lua"


class LoadCallRegistryTests(unittest.TestCase):
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

        self.assertIn("local Page = ParentPage.Children[name]", helper)
        self.assertIn("if (not Page) then", helper)
        self.assertIn("tinsert(Page.Calls, arg2)", add_widgets)
        self.assertNotIn("Children[name] = {Calls = {}}", add_widgets)

    def test_child_registration_queues_its_parent_first_and_only_once(self):
        queue_page = self.function_body(
            "local QueuePage = function", "local ScrollWidgetColumn = function"
        )
        add_widgets = self.function_body(
            "function GUI:AddWidgets", "function GUI:GetWidget"
        )

        self.assertIn("if page.Queued then", queue_page)
        self.assertIn("page.Queued = true", queue_page)
        parent_queue = "QueuePage(self, ParentPage, category, arg1)"
        child_queue = "QueuePage(self, Page, category, name, arg1)"
        self.assertLess(add_widgets.index(parent_queue), add_widgets.index(child_queue))


if __name__ == "__main__":
    unittest.main()
