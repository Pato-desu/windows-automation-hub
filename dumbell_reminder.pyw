import pygetwindow as gw
import time
import tkinter as tk
from tkinter import messagebox

# --- CONFIGURATION ---
WATCH_THRESHOLD = 600    
COOLDOWN_PERIOD = 1200    
CHECK_INTERVAL = 30        

def show_popup():
    # This creates a hidden root window to host the message box
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True) # Force it above full-screen apps
    messagebox.showwarning("Watchtime heat is high", "Mancuernas o pará de mirar weas")
    root.destroy()

def is_watching():
    try:
        active_window = gw.getActiveWindow()
        if not active_window: return False
        title = active_window.title.lower()
        return "stremio" in title or "youtube" in title
    except:
        return False

def main():
    active_watch_time = 0

    while True:
        current_time = time.time()
        
        if is_watching():
            active_watch_time += CHECK_INTERVAL
            print(f"Watching... Heat: {active_watch_time}")
        
        elif active_watch_time > 0:
            active_watch_time -= CHECK_INTERVAL/2

        # Check if both conditions are met:
        # 1. Have you watched enough?
        # 2. Has enough time passed since the last nudge?
        
        if active_watch_time >= WATCH_THRESHOLD:
            
            # RESET
            show_popup()
            active_watch_time = 0
            time.sleep(COOLDOWN_PERIOD)
            
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()