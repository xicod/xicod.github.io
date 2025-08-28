#!/usr/bin/python3

import json
import subprocess
import os
import sys

cmd = ['smartctl', '-a', '-j']

def print_err(device, device_name, param, value):
	global exit_code
	exit_code = 1
	print(f"Device {device} ({device_name}) has {param} with value {value}!!", file=sys.stderr)

def check_ata_drive(j, drive):
	acceptable_values = {
		"Reallocated_Sector_Ct": 0,
	}

	for attr in j["ata_smart_attributes"]["table"]:
		if attr["name"] in acceptable_values:
			val = attr["raw"]["value"]
			ok_val = acceptable_values[attr["name"]]
			if val != ok_val:
				print_err(drive, j["model_name"], attr["name"], val)
			del acceptable_values[attr["name"]]

	if len(acceptable_values) > 0:
		global exit_code
		exit_code = 1
		for param in acceptable_values:
			print(f'Could not locate parameter {param} for {drive} ({j["model_name"]})!!', file=sys.stderr)

drives = os.environ["DTCONF_drives"].split(",")
acceptable_temperatures = [int(x) for x in os.environ["DTCONF_acceptable_temperatures"].split(",")]
acceptable_usage_percents = [int(x) for x in os.environ["DTCONF_acceptable_usage_percents"].split(",")]

exit_code = 0

for i in range(0, len(drives)):
	drive = drives[i]
	acceptable_temperature = acceptable_temperatures[i]
	acceptable_usage_percent = acceptable_usage_percents[i]

	proc = subprocess.Popen(cmd+[drive], stdout=subprocess.PIPE)
	output = proc.stdout.read()

	j = json.loads(output)

	if j["smartctl"]["exit_status"] != 0:
		print("smartctl: " + j["smartctl"]["messages"][0]["string"], file=sys.stderr)
		exit_code = 1
		continue

	temperature = j["temperature"]["current"]
	if temperature > acceptable_temperature:
		print_err(drive, j["model_name"], "temperature", temperature)

	device_type = j["device"]["type"]
	if device_type == "nvme":
		d = j["nvme_smart_health_information_log"]

		p = "percentage_used"
		if d[p] > acceptable_usage_percent:
			print_err(drive, j["model_name"], p, d[p])

		p = "critical_warning"
		ok_val = 0
		if d[p] != ok_val:
			print_err(drive, j["model_name"], p, d[p])

		p = "media_errors"
		ok_val = 0
		if d[p] != ok_val:
			print_err(drive, j["model_name"], p, d[p])

	elif device_type == "sat":
		check_ata_drive(j, drive)

	else:
		raise Exception(f"{drive} has unrecognized type: {device_type}")

sys.exit(exit_code)
