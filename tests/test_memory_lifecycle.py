"""Regression checks for objects retained by long-lived UI drivers and pools."""
from pathlib import Path


LIB_MOTION = Path("HydraUI/Elements/Libraries/LibMotion.lua").read_text()
ALERTS = Path("HydraUI/Elements/Alerts.lua").read_text()
POPUP = Path("HydraUI/Elements/Popup.lua").read_text()


def test_animation_restarts_cannot_accumulate_updater_references():
    play = LIB_MOTION[LIB_MOTION.index("function Prototype:Play()") : LIB_MOTION.index("function Prototype:IsPlaying()")]
    pause = LIB_MOTION[LIB_MOTION.index("function Prototype:Pause()") : LIB_MOTION.index("function Prototype:IsPaused()")]
    stop = LIB_MOTION[LIB_MOTION.index("function Prototype:Stop(reset)") : LIB_MOTION.index("function Prototype:IsStopped()")]

    assert "RemoveFromUpdater(self)" in play
    assert play.index("RemoveFromUpdater(self)") < play.index("Updater[#Updater + 1] = self")
    assert "RemoveFromUpdater(self)" in pause
    assert "RemoveFromUpdater(self)" in stop


def test_detaching_animation_releases_the_group_reference():
    assert "tremove(self.Group.Animations, i)" in LIB_MOTION
    assert "tremove(self.Group, i)" not in LIB_MOTION


def test_recycled_alerts_stop_drivers_and_release_click_callbacks():
    recycle = ALERTS[ALERTS.index("RecycleAlert = function") : ALERTS.index("local CreateAlertFrame")]

    assert 'Alert.FadeIn:Stop()' in recycle
    assert 'Alert.FadeOut:Stop()' in recycle
    assert 'Alert:SetScript("OnMouseUp", nil)' in recycle
    assert "if not WasActive then" in recycle
    assert "self.Hold" not in ALERTS


def test_hidden_popup_releases_callbacks_and_arguments():
    release = POPUP[POPUP.index("local ReleasePopup") : POPUP.index("local ButtonOnMouseUp")]

    assert "PopupFrame.FadeIn:Stop()" in release
    assert "PopupFrame.FadeOut:Stop()" in release
    for button in ("Button1", "Button2"):
        assert f"PopupFrame.{button}.Callback = nil" in release
        assert f"PopupFrame.{button}.Arg1 = nil" in release
        assert f"PopupFrame.{button}.Arg2 = nil" in release
    assert "ReleasePopup(self.Parent)" in POPUP
