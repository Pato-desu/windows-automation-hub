"""
Example Task: Folder Organizer Script
Sorts loose files in a target directory (e.g. Downloads or Scratch) into subfolders by extension.
"""

import os
import shutil
import sys

CATEGORY_MAP = {
    "Documents": [".pdf", ".docx", ".xlsx", ".pptx", ".txt", ".csv", ".md"],
    "Images": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp"],
    "Archives": [".zip", ".rar", ".7z", ".tar", ".gz"],
    "Executables": [".exe", ".msi", ".bat", ".ps1"],
    "Media": [".mp3", ".wav", ".mp4", ".mkv", ".flac", ".m4a"]
}

def get_category(filename):
    ext = os.path.splitext(filename)[1].lower()
    for category, extensions in CATEGORY_MAP.items():
        if ext in extensions:
            return category
    return "Others"

def main():
    target_dir = os.path.expandvars("%USERPROFILE%\\Downloads")
    if len(sys.argv) > 1:
        target_dir = sys.argv[1]

    if not os.path.exists(target_dir):
        print(f"[Folder Organizer] Target folder does not exist: {target_dir}")
        return

    print(f"[Folder Organizer] Scanning: {target_dir}")
    moved_count = 0

    for item in os.listdir(target_dir):
        item_path = os.path.join(target_dir, item)
        if os.path.isfile(item_path):
            category = get_category(item)
            dest_dir = os.path.join(target_dir, category)
            os.makedirs(dest_dir, exist_ok=True)
            dest_path = os.path.join(dest_dir, item)
            
            try:
                shutil.move(item_path, dest_path)
                print(f"[Folder Organizer] Moved '{item}' -> {category}/")
                moved_count += 1
            except Exception as e:
                print(f"[Folder Organizer] Could not move '{item}': {e}")

    print(f"[Folder Organizer] Processed {moved_count} file(s). Completed.")

if __name__ == "__main__":
    main()
