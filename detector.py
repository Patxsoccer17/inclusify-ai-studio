"""
detector.py — passive microphone listener for sigh detection.

A sigh is identified as a sustained, smooth exhale:
  - RMS energy above a quiet-room floor
  - Low zero-crossing rate (breath is smooth, speech is jagged)
  - Consistent energy envelope (low coefficient of variation)
  - Duration between MIN_DURATION and MAX_DURATION seconds
  - Followed by a COOLDOWN gap before the next detection

No audio frames are stored beyond the current candidate segment.
No data ever leaves the device.
"""

import threading
import time

import numpy as np
import sounddevice as sd


class SighDetector:
    # Audio capture
    SAMPLE_RATE = 16_000        # Hz
    BLOCK_SIZE = 512            # samples per callback (~32 ms)

    # Sigh fingerprint
    ENERGY_THRESHOLD = 0.008    # minimum RMS to be considered "active"
    ZCR_THRESHOLD = 0.12        # max zero-crossing rate (sighs are smooth)
    SMOOTHNESS_CV = 0.75        # max coefficient of variation in energy frames

    # Timing
    MIN_DURATION = 1.5          # seconds — shorter is a cough or consonant
    MAX_DURATION = 4.0          # seconds — longer is ambient noise
    COOLDOWN = 2.0              # seconds between accepted detections

    def __init__(self, on_sigh):
        """
        on_sigh: zero-argument callable invoked on the audio callback thread
                 each time a sigh is detected.
        """
        self.on_sigh = on_sigh
        self._stream = None
        self._lock = threading.Lock()

        # Mutable detection state (guarded by _lock)
        self._active = False
        self._active_start = 0.0
        self._active_frames: list[float] = []
        self._last_detected = 0.0

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self):
        self._stream = sd.InputStream(
            samplerate=self.SAMPLE_RATE,
            channels=1,
            blocksize=self.BLOCK_SIZE,
            dtype="float32",
            callback=self._callback,
        )
        self._stream.start()

    def stop(self):
        if self._stream:
            self._stream.stop()
            self._stream.close()
            self._stream = None

    # ------------------------------------------------------------------
    # Audio callback (runs on sounddevice's internal thread)
    # ------------------------------------------------------------------

    def _callback(self, indata, frames, time_info, status):
        audio = indata[:, 0]

        rms = float(np.sqrt(np.mean(audio ** 2)))
        zcr = float(np.sum(np.abs(np.diff(np.sign(audio)))) / (2 * len(audio)))

        now = time.monotonic()
        sigh_like = rms > self.ENERGY_THRESHOLD and zcr < self.ZCR_THRESHOLD

        with self._lock:
            if sigh_like:
                if not self._active:
                    self._active = True
                    self._active_start = now
                    self._active_frames = []
                self._active_frames.append(rms)

                # Bail out early if segment already exceeds max duration
                if now - self._active_start > self.MAX_DURATION:
                    self._active = False
                    self._active_frames = []
            else:
                if self._active:
                    duration = now - self._active_start
                    if (
                        self.MIN_DURATION <= duration <= self.MAX_DURATION
                        and self._is_smooth(self._active_frames)
                        and now - self._last_detected > self.COOLDOWN
                    ):
                        self._last_detected = now
                        self.on_sigh()          # fire callback
                    self._active = False
                    self._active_frames = []

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _is_smooth(self, frames: list[float]) -> bool:
        """Return True if the energy envelope is consistent (low CV)."""
        if len(frames) < 5:
            return False
        arr = np.array(frames, dtype=np.float32)
        mean = arr.mean()
        if mean < 1e-9:
            return False
        cv = arr.std() / mean
        return float(cv) < self.SMOOTHNESS_CV
