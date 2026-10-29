# ⚙️ Windows Automation Hub

A modular, extensible framework for running scripts on your Windows PC based on specific system conditions, schedules, or events.

---

## 🖥️ Graphical Control Panels & Tools

The hub includes dedicated GUI dialogs for each automation that can be pinned directly to your Windows Start menu or Taskbar:

| Tool | Script | Description |
| :--- | :--- | :--- |
| **Automation Hub Dashboard** | `automation_hub_ui.ps1` | Central dashboard launching all tools and managing shortcuts. |
| **Power Timer** | `power_timer.ps1` | Set PC to sleep or shut down in X minutes with live countdown & cancel. |
| **Dumbbell Reminder** | `dumbell_ui.ps1` | Start/stop background monitor, toggle Windows Startup, and test alerts. |
| **OBS Wake Manager** | `obs_wake_ui.ps1` | Register/fix Task Scheduler wake trigger, test OBS restoration now. |

### Pinning Tools to Windows Start
Run `create_all_shortcuts.ps1` (or right-click -> *Run with PowerShell*). It creates shortcuts with native Windows icons in this directory, on your Desktop, and in your Start Menu. Right-click any shortcut and select **Pin to Start**.

---

## 📁 Repository Structure

```
windows-automation-hub/
├── tasks.json               # Central configuration defining tasks and conditions
├── runner.py                # Core engine: evaluates conditions and executes scripts
├── setup_windows_task.ps1   # Helper to register background task in Task Scheduler
├── conditions/              # Built-in condition evaluators
│   └── evaluators.py        # Logic for time, disk space, folder, process checks
├── tasks/                   # Directory where your custom scripts live
│   ├── example_disk_cleanup.py
│   ├── example_folder_organizer.py
│   └── example_system_info.ps1
└── logs/                    # Execution logs (automation.log)
```

---

## 🚀 Quick Start

### 1. List Configured Tasks
See all registered tasks, their condition types, and execution status:
```bash
python runner.py --list
```

### 2. Run Condition Evaluation (Single Pass)
Checks all enabled task conditions and runs any scripts whose conditions are met:
```bash
python runner.py
```

### 3. Force Run a Task
Run a specific task immediately regardless of conditions:
```bash
python runner.py --run system_info_snapshot
```

### 4. Background Watch Mode
Continuously monitors conditions at a set polling interval (e.g. every 60 seconds):
```bash
python runner.py --watch 60
```

---

## ⚙️ How to Add Your Own Tasks

Add a new task definition to `tasks.json` and place your script in `tasks/`.

### Task Configuration Schema (`tasks.json`)

```json
{
  "id": "my_custom_task",
  "name": "My Custom Task Name",
  "enabled": true,
  "script": "tasks/my_script.py",
  "type": "python",
  "condition": {
    "type": "interval",
    "seconds": 1800,
    "cooldown_seconds": 300
  }
}
```

### Supported Script Types (`type`)
- `python`: Executes Python scripts via `sys.executable`.
- `powershell`: Executes `.ps1` PowerShell scripts with execution policy bypass.
- `batch` / `cmd`: Executes `.bat` / `.cmd` Windows scripts.
- `executable`: Runs binary `.exe` commands directly.

---

## 🎯 Supported Condition Types

| Condition Type | Parameters | Description |
| :--- | :--- | :--- |
| `always` | None | Runs every time the runner is executed (subject to cooldown). |
| `interval` | `seconds` | Runs if the specified number of seconds has elapsed since last run. |
| `disk_space_below` | `drive`, `min_free_percent` | Runs if drive free space falls below percentage threshold (e.g., C: < 15%). |
| `folder_not_empty` | `path` | Runs if target folder contains 1 or more files. |
| `file_exists` | `path` | Runs if specific trigger file exists on disk. |
| `process_running` | `process_name` | Runs if specified process (e.g. `chrome.exe`) is actively running. |
| `process_not_running` | `process_name` | Runs if specified process is NOT running. |
| `time_window` | `start_hour`, `end_hour` | Runs only within specific hours of the day (e.g., 22 to 6 for night tasks). |

---

## ⏰ Automatic Execution via Windows Task Scheduler

To make tasks run in the background automatically on your Windows PC:

Run the PowerShell setup script (or right-click -> *Run with PowerShell*):
```powershell
.\setup_windows_task.ps1 -IntervalMinutes 15 -RunAtLogon
```
This registers a background scheduled task that wakes up every 15 minutes and on logon to check and run any due tasks.

---

## 📊 Logs & State Tracking

- **Execution Logs**: `logs/automation.log` records timestamped output and stderr/stdout from all task runs.
- **Task State**: `.task_state.json` tracks last execution timestamps and pass/fail status to enforce cooldowns and avoid duplicate executions.
