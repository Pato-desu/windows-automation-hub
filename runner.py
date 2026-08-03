#!/usr/bin/env python3
"""
Windows Automation Task Runner
Evaluates tasks configured in tasks.json and executes them when specific conditions are met.
"""

import os
import sys
import json
import time
import argparse
import subprocess
from datetime import datetime
from conditions.evaluators import check_condition

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TASKS_CONFIG_FILE = os.path.join(SCRIPT_DIR, "tasks.json")
STATE_FILE = os.path.join(SCRIPT_DIR, ".task_state.json")
LOG_DIR = os.path.join(SCRIPT_DIR, "logs")
LOG_FILE = os.path.join(LOG_DIR, "automation.log")

def log(message: str, level: str = "INFO", echo: bool = True):
    """Writes log messages to console and log file."""
    os.makedirs(LOG_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [{level}] {message}"
    if echo:
        print(formatted)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception as e:
        print(f"[Error writing log file]: {e}")

def load_json(filepath: str, default: dict) -> dict:
    if os.path.exists(filepath):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            log(f"Failed to load JSON file {filepath}: {e}", level="ERROR")
    return default

def save_json(filepath: str, data: dict):
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        log(f"Failed to save JSON file {filepath}: {e}", level="ERROR")

def execute_task(task: dict) -> bool:
    """Executes a task based on its script type."""
    script_path = os.path.expandvars(task.get("script", ""))
    if not os.path.isabs(script_path):
        script_path = os.path.abspath(os.path.join(SCRIPT_DIR, script_path))

    if not os.path.exists(script_path):
        log(f"Script file not found for task '{task.get('id')}': {script_path}", level="ERROR")
        return False

    task_type = task.get("type", "python").lower()
    cmd = []

    if task_type == "python":
        cmd = [sys.executable, script_path]
    elif task_type == "powershell":
        cmd = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path]
    elif task_type in ["batch", "cmd"]:
        cmd = ["cmd.exe", "/c", script_path]
    elif task_type == "executable":
        cmd = [script_path]
    else:
        log(f"Unsupported task type '{task_type}' for task '{task.get('id')}'", level="ERROR")
        return False

    args = task.get("args", [])
    if args:
        cmd.extend(args)

    log(f"--- Executing Task: {task.get('name')} ({task.get('id')}) ---")
    log(f"Command: {' '.join(cmd)}")

    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=SCRIPT_DIR
        )
        duration = time.time() - start_time
        
        if result.stdout.strip():
            log(f"STDOUT:\n{result.stdout.strip()}", level="INFO")
        if result.stderr.strip():
            log(f"STDERR:\n{result.stderr.strip()}", level="WARN")

        if result.returncode == 0:
            log(f"Task '{task.get('id')}' finished successfully in {duration:.2f}s.")
            return True
        else:
            log(f"Task '{task.get('id')}' failed with exit code {result.returncode} in {duration:.2f}s.", level="ERROR")
            return False
    except Exception as e:
        log(f"Exception raised while executing task '{task.get('id')}': {e}", level="ERROR")
        return False

def run_task_evaluation(force_task_id: str = None, dry_run: bool = False):
    config = load_json(TASKS_CONFIG_FILE, {"tasks": []})
    state = load_json(STATE_FILE, {})
    tasks = config.get("tasks", [])

    if not tasks:
        log("No tasks configured in tasks.json", level="WARN")
        return

    log(f"Evaluating {len(tasks)} task(s)...")

    for task in tasks:
        task_id = task.get("id")
        if not task_id:
            continue

        if force_task_id and task_id != force_task_id:
            continue

        name = task.get("name", task_id)
        enabled = task.get("enabled", True)

        if not enabled and not force_task_id:
            log(f"Skipping disabled task: {name} ({task_id})")
            continue

        last_run = state.get(task_id, {}).get("last_run", 0)
        condition = task.get("condition", {})

        should_run = False
        if force_task_id:
            should_run = True
            log(f"Force running task: {name}")
        else:
            should_run = check_condition(condition, last_run)

        if should_run:
            log(f"Condition MET for task: {name}")
            if dry_run:
                log(f"[Dry Run] Would execute task: {name}")
            else:
                success = execute_task(task)
                state[task_id] = {
                    "last_run": time.time(),
                    "last_status": "SUCCESS" if success else "FAILED"
                }
                save_json(STATE_FILE, state)
        else:
            log(f"Condition NOT met for task: {name}")

def list_tasks():
    config = load_json(TASKS_CONFIG_FILE, {"tasks": []})
    state = load_json(STATE_FILE, {})
    tasks = config.get("tasks", [])

    print("\nConfigured Tasks:")
    print("=" * 70)
    for t in tasks:
        task_id = t.get("id")
        name = t.get("name")
        enabled = "ENABLED" if t.get("enabled", True) else "DISABLED"
        ttype = t.get("type", "python")
        last_info = state.get(task_id, {})
        last_run_time = last_info.get("last_run", 0)
        last_str = datetime.fromtimestamp(last_run_time).strftime("%Y-%m-%d %H:%M:%S") if last_run_time else "Never"
        last_status = last_info.get("last_status", "N/A")

        print(f"ID:       {task_id}")
        print(f"Name:     {name}")
        print(f"Status:   [{enabled}] | Type: {ttype}")
        print(f"Last Run: {last_str} ({last_status})")
        print(f"Condition: {json.dumps(t.get('condition', {}))}")
        print("-" * 70)

def main():
    parser = argparse.ArgumentParser(description="Windows Automation Task Runner")
    parser.add_argument("--watch", type=int, nargs="?", const=60, help="Run continuously in background watch mode with polling interval in seconds (default: 60s)")
    parser.add_argument("--run", type=str, help="Force run a specific task by ID")
    parser.add_argument("--list", action="store_true", help="List all configured tasks and status")
    parser.add_argument("--dry-run", action="store_true", help="Evaluate conditions without executing scripts")

    args = parser.parse_args()

    if args.list:
        list_tasks()
        return

    if args.run:
        run_task_evaluation(force_task_id=args.run, dry_run=args.dry_run)
        return

    if args.watch is not None:
        interval = max(5, args.watch)
        log(f"Starting Task Automation Watcher Daemon (Polling every {interval}s)... Press Ctrl+C to stop.")
        try:
            while True:
                run_task_evaluation(dry_run=args.dry_run)
                time.sleep(interval)
        except KeyboardInterrupt:
            log("Automation Watcher stopped by user.")
        return

    # Default: Run once
    run_task_evaluation(dry_run=args.dry_run)

if __name__ == "__main__":
    main()
