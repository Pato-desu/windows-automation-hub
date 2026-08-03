import os
import time
import shutil
import subprocess

def check_condition(condition_config: dict, last_run_timestamp: float) -> bool:
    """
    Evaluates whether a condition is satisfied based on task configuration.
    """
    cond_type = condition_config.get("type", "always")
    cooldown = condition_config.get("cooldown_seconds", 0)
    now = time.time()

    # Cooldown check
    if last_run_timestamp > 0 and (now - last_run_timestamp) < cooldown:
        return False

    if cond_type == "always":
        return True

    elif cond_type == "interval":
        interval = condition_config.get("seconds", 3600)
        return (now - last_run_timestamp) >= interval

    elif cond_type == "disk_space_below":
        drive = os.path.expandvars(condition_config.get("drive", "C:"))
        min_free_percent = condition_config.get("min_free_percent", 10)
        try:
            total, used, free = shutil.disk_usage(drive)
            free_percent = (free / total) * 100
            return free_percent < min_free_percent
        except Exception as e:
            print(f"[Condition Error] Failed to check disk space for {drive}: {e}")
            return False

    elif cond_type == "file_exists":
        file_path = os.path.expandvars(condition_config.get("path", ""))
        return os.path.isfile(file_path)

    elif cond_type == "folder_not_empty":
        folder_path = os.path.expandvars(condition_config.get("path", ""))
        if os.path.isdir(folder_path):
            try:
                return len(os.listdir(folder_path)) > 0
            except PermissionError:
                return False
        return False

    elif cond_type == "process_running" or cond_type == "process_not_running":
        process_name = condition_config.get("process_name", "")
        if not process_name:
            return False
        try:
            # Query active tasklist on Windows
            output = subprocess.check_output(
                ["tasklist", "/FI", f"IMAGENAME eq {process_name}"],
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )
            is_running = process_name.lower() in output.lower()
            return is_running if cond_type == "process_running" else not is_running
        except Exception as e:
            print(f"[Condition Error] Failed to check process status: {e}")
            return False

    elif cond_type == "time_window":
        start_hour = condition_config.get("start_hour", 0)
        end_hour = condition_config.get("end_hour", 23)
        current_hour = time.localtime().tm_hour
        return start_hour <= current_hour <= end_hour

    else:
        print(f"[Condition Error] Unknown condition type: {cond_type}")
        return False
