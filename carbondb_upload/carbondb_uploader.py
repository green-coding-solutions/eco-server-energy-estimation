import os
import subprocess
import json
import re
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import datetime

def parse_config(file_path):
    config = {}
    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                config[key.strip()] = value.strip()
    return config

def get_last_time(config):
    try:
        with open(config['db_file'], 'r') as file:
            for line in file:
                key, value = line.strip().split('=', 1)
                if key == 'last_timestamp':
                    return int(value)
    except FileNotFoundError:
        pass
    except ValueError:
        pass

    # If there is an error or no file we just return 1 for the beginning of time
    return 1

def set_last_time(config, time_stamp):
    properties = {}

    try:
        with open(config['db_file'], 'r') as file:
            for line in file:
                key, value = line.strip().split('=', 1)
                properties[key] = value
    except FileNotFoundError:
        pass

    properties['last_timestamp'] = str(time_stamp)

    with open(config['db_file'], 'w') as file:
        for key, value in properties.items():
            file.write(f"{key}={value}\n")

def check_log_messages(service_name, config):
    pattern = re.compile(r"^\d+\.\d+$")

    epoch_time_seconds = get_last_time(config) // 1e6
    datetime_obj = datetime.datetime.utcfromtimestamp(epoch_time_seconds)
    formatted_time = datetime_obj.strftime('%Y-%m-%d %H:%M:%S')


    command = ["journalctl",
               "-u", service_name,
               "-ojson",
               "--output-fields", "__REALTIME_TIMESTAMP,MESSAGE",
               "--since", formatted_time
               ]
    print(f"Calling: {command}")

    try:
        logs = subprocess.check_output(command, encoding="utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Failed to fetch logs: {e}")
        return

    to_upload = []
    for line in logs.splitlines():
        try:
            log_entry = json.loads(line)

            message = log_entry.get('MESSAGE', '')
            if pattern.match(message):
                to_upload.append({
                    'type': 'machine.server',
                    'company': config.get('company_id'),
                    'machine': config.get('machine_id'),
                    'project': config.get('project_id'),
                    'tags': config.get('tags'),
                    'time_stamp': log_entry.get('__REALTIME_TIMESTAMP'),
                    'energy_value': message,
                })
                #print(f"Found matching message: {log_entry}")


        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON: {e}")
            continue

    to_upload = sorted(to_upload, key=lambda x: x['time_stamp'])

    block_size = 1000
    for i in range(0, len(to_upload), block_size):
        block = to_upload[i:i+block_size]

        # Upload data to server
        json_data = json.dumps(block).encode('utf-8')
        req = Request(config.get('endpoint'), data=json_data, headers={'Content-Type': 'application/json'})
        try:
            # Send the request and read the response
            with urlopen(req, timeout=10) as response:
                response_body = response.read()
                print(f"Block {i}/{len(to_upload)} response:{response_body.decode('utf-8')}")

        except HTTPError as e:
            print('HTTPError:', e.code, e.reason)
            return #If there is an error we just stop and try the next time

        except URLError as e:
            print('URLError:', e.reason)
            return #If there is an error we just stop and try the next time

    # Save biggest timestamp to file
    # If we are here everything has worked out and we can save the value
    set_last_time(config, to_upload[-1]['time_stamp'])

if __name__ == "__main__":
    config_path = '/etc/carbondb_uploader.conf'
    config = parse_config(config_path)
    print('Welcome to the GMT upload script')
    print(f"Config is: {config}")
    check_log_messages("xgb", config)
