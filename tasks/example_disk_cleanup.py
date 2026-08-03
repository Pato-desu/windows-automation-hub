"""
Example Task: Low Disk Space Alert & Cleanup Script
This script is executed when C: drive free space drops below a threshold.
"""

import os
import shutil
import sys

def main():
    print("[Low Disk Cleanup] Starting disk check...")
    drive = "C:\\"
    total, used, free = shutil.disk_usage(drive)
    free_gb = free / (1024 ** 3)
    total_gb = total / (1024 ** 3)
    free_percent = (free / total) * 100

    print(f"[Low Disk Cleanup] Drive {drive}: {free_gb:.2f} GB free out of {total_gb:.2f} GB ({free_percent:.1f}%)")

    # Clean user temporary directory top-level files if possible
    temp_dir = os.environ.get("TEMP", "")
    if temp_dir and os.path.exists(temp_dir):
        print(f"[Low Disk Cleanup] Checking Temp directory: {temp_dir}")
        cleaned_files = 0
        freed_bytes = 0

        try:
            for item in os.listdir(temp_dir):
                item_path = os.path.join(temp_dir, item)
                if os.path.isfile(item_path):
                    try:
                        file_stat = os.stat(item_path)
                        # Files older than 1 day
                        if file_stat.st_mtime < (os.path.getmtime(item_path) - 86400):
                            size = file_stat.st_size
                            os.remove(item_path)
                            cleaned_files += 1
                            freed_bytes += size
                    except Exception:
                        pass
        except Exception as e:
            print(f"[Low Disk Cleanup] Temp scan error: {e}")

        freed_mb = freed_bytes / (1024 * 1024)
        print(f"[Low Disk Cleanup] Cleaned {cleaned_files} top-level temp files ({freed_mb:.2f} MB freed).")
    
    print("[Low Disk Cleanup] Task completed successfully.")

if __name__ == "__main__":
    main()
