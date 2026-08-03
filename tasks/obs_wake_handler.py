"""
OBS Studio Wake & Focus Handler
Restores and maximizes OBS Studio on system wake from sleep/hibernation to refresh display/graphics capture sources and replay buffer.
"""

import os
import sys
import time
import ctypes
import subprocess
from datetime import datetime

# Win32 Constants
SW_RESTORE = 9
SW_MAXIMIZE = 3
OBS_PATH = r"C:\Program Files\obs-studio\bin\64bit\obs64.exe"
OBS_CWD  = r"C:\Program Files\obs-studio\bin\64bit"

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [OBS Wake] {msg}"
    print(formatted)
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "automation.log")
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass

def get_obs_hwnd():
    obs_hwnd = 0

    def enum_windows_callback(hwnd, lparam):
        nonlocal obs_hwnd
        length = user32.GetWindowTextLengthW(hwnd)
        if length > 0:
            buffer = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buffer, length + 1)
            title = buffer.value
            if title.startswith("OBS ") or "OBS Studio" in title:
                obs_hwnd = hwnd
                return False  # Stop enumeration
        return True

    EnumWindowsProc = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    user32.EnumWindows(EnumWindowsProc(enum_windows_callback), 0)
    return obs_hwnd

def restore_and_maximize_obs():
    log("System wake event received. Checking OBS Studio status...")
    
    # Wait briefly for display drivers to wake up
    time.sleep(1.5)

    hwnd = get_obs_hwnd()

    if hwnd:
        log(f"Found OBS Studio window handle: 0x{hwnd:X}.")
        # Restore from minimized/tray state
        user32.ShowWindow(hwnd, SW_RESTORE)
        time.sleep(0.3)
        # Maximize to force GPU viewport recalculation
        user32.ShowWindow(hwnd, SW_MAXIMIZE)
        user32.SetForegroundWindow(hwnd)
        log("OBS Studio window restored, maximized, and focused successfully.")
        return True
    else:
        log("OBS Studio is not running. Launching OBS Studio...")
        if os.path.exists(OBS_PATH):
            subprocess.Popen([OBS_PATH, "--startreplaybuffer"], cwd=OBS_CWD)
            log(f"Launched OBS Studio from '{OBS_PATH}'. Waiting for window...")
            time.sleep(3.5)
            
            new_hwnd = get_obs_hwnd()
            if new_hwnd:
                user32.ShowWindow(new_hwnd, SW_MAXIMIZE)
                user32.SetForegroundWindow(new_hwnd)
                log("Newly launched OBS Studio window maximized.")
            return True
        else:
            log(f"ERROR: OBS executable not found at '{OBS_PATH}'.")
            return False

if __name__ == "__main__":
    restore_and_maximize_obs()
