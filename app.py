"""
app.py — Sigh Counter Mac menubar app.

Sits in the menubar as 😮‍💨 <count>.
Passively listens to the microphone via detector.py.
All processing is local; no audio is recorded or stored.
"""

import plistlib
import subprocess
import sys
import threading
from datetime import datetime
from pathlib import Path

import rumps

from detector import SighDetector

# ------------------------------------------------------------------
# Launch-at-login helpers (launchd)
# ------------------------------------------------------------------

_PLIST_LABEL = "com.inclusify.sigh-counter"
_PLIST_PATH = (
    Path.home() / "Library" / "LaunchAgents" / f"{_PLIST_LABEL}.plist"
)


def _login_enabled() -> bool:
    return _PLIST_PATH.exists()


def _enable_login() -> None:
    plist = {
        "Label": _PLIST_LABEL,
        "ProgramArguments": [sys.executable, str(Path(__file__).resolve())],
        "RunAtLoad": True,
        "KeepAlive": False,
    }
    _PLIST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_PLIST_PATH, "wb") as fh:
        plistlib.dump(plist, fh)
    subprocess.run(
        ["launchctl", "load", str(_PLIST_PATH)],
        capture_output=True,
    )


def _disable_login() -> None:
    if _PLIST_PATH.exists():
        subprocess.run(
            ["launchctl", "unload", str(_PLIST_PATH)],
            capture_output=True,
        )
        _PLIST_PATH.unlink()


# ------------------------------------------------------------------
# App
# ------------------------------------------------------------------

class SighCounterApp(rumps.App):
    def __init__(self):
        super().__init__("😮‍💨 0", quit_button=None)

        self._count = 0
        self._last_time: datetime | None = None
        self._notified_today = False
        self._lock = threading.Lock()

        # --- Menu items ---
        self._count_item = rumps.MenuItem("Today: 0 sighs")
        self._last_item  = rumps.MenuItem("Last sigh: —")
        self._reset_item = rumps.MenuItem("Reset Count", callback=self._reset)
        self._login_item = rumps.MenuItem(
            ("✓ " if _login_enabled() else "") + "Start at Login",
            callback=self._toggle_login,
        )
        self.menu = [
            self._count_item,
            self._last_item,
            None,
            self._reset_item,
            self._login_item,
            None,
            rumps.MenuItem("Quit", callback=rumps.quit_application),
        ]

        # --- Audio detector ---
        self._detector = SighDetector(on_sigh=self._on_sigh)
        self._detector.start()

        # --- Timers ---
        # Refresh the menubar title and menu labels every second
        rumps.Timer(self._tick_ui, 1).start()
        # Check for midnight reset and 6 pm notification every 30 s
        rumps.Timer(self._tick_time, 30).start()

    # ------------------------------------------------------------------
    # Detection callback — called from the audio thread
    # ------------------------------------------------------------------

    def _on_sigh(self) -> None:
        with self._lock:
            self._count += 1
            self._last_time = datetime.now()

    # ------------------------------------------------------------------
    # Timer: UI refresh (main thread via rumps)
    # ------------------------------------------------------------------

    def _tick_ui(self, _) -> None:
        with self._lock:
            count = self._count
            last  = self._last_time

        self.title = f"😮‍💨 {count}"
        self._count_item.title = (
            f"Today: {count} sigh{'s' if count != 1 else ''}"
        )
        if last:
            self._last_item.title = f"Last sigh: {last.strftime('%-I:%M %p')}"

    # ------------------------------------------------------------------
    # Timer: midnight reset + 6 pm notification
    # ------------------------------------------------------------------

    def _tick_time(self, _) -> None:
        now = datetime.now()

        # Reset at midnight (fire in the first minute of the day)
        if now.hour == 0 and now.minute == 0:
            self._reset(None)

        # 6 pm daily summary notification
        if now.hour == 18 and now.minute < 1 and not self._notified_today:
            with self._lock:
                count = self._count
                self._notified_today = True
            rumps.notification(
                title="Sigh Counter",
                subtitle="Daily Summary",
                message=(
                    f"You sighed {count} time{'s' if count != 1 else ''} today."
                ),
            )

    # ------------------------------------------------------------------
    # Menu callbacks
    # ------------------------------------------------------------------

    def _reset(self, _) -> None:
        with self._lock:
            self._count = 0
            self._last_time = None
            self._notified_today = False
        # Immediate UI refresh
        self.title = "😮‍💨 0"
        self._count_item.title = "Today: 0 sighs"
        self._last_item.title  = "Last sigh: —"

    def _toggle_login(self, sender) -> None:
        if _login_enabled():
            _disable_login()
            sender.title = "Start at Login"
        else:
            _enable_login()
            sender.title = "✓ Start at Login"

    # ------------------------------------------------------------------
    # Cleanup
    # ------------------------------------------------------------------

    def __del__(self):
        try:
            self._detector.stop()
        except Exception:
            pass


# ------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------

if __name__ == "__main__":
    SighCounterApp().run()
