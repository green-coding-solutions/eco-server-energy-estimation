import subprocess
import json
import re

def check_log_messages(service_name):
    pattern = re.compile(r"^\d+\.\d+$")

    command = ["journalctl",
               "-u", service_name,
               "-ojson",
               "--output-fields", "__REALTIME_TIMESTAMP,MESSAGE",
               ]
    try:
        logs = subprocess.check_output(command, encoding="utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Failed to fetch logs: {e}")
        return

    for line in logs.splitlines():
        try:
            log_entry = json.loads(line)

            message = log_entry.get('MESSAGE', '')
            if pattern.match(message):
                print(f"{log_entry.get('__REALTIME_TIMESTAMP')} {message}")

        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON: {e}")
            continue

if __name__ == "__main__":
    check_log_messages("xgb")
