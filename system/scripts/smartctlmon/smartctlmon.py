#!/usr/bin/python3

import json
import subprocess
import os
import sys

cmd = ['smartctl', '-a', '-j']

def print_err(device, device_name, param, value):
	print(f"Device {device} ({device_name}) has {param} with value {value}!!", file=sys.stderr)

drives = os.environ["DTCONF_drives"].split(",")
acceptable_temperatures = [int(x) for x in os.environ["DTCONF_acceptable_temperatures"].split(",")]
acceptable_usage_percents = [int(x) for x in os.environ["DTCONF_acceptable_usage_percents"].split(",")]

for i in range(0, len(drives)):
	drive = drives[i]
	acceptable_temperature = acceptable_temperatures[i]
	acceptable_usage_percent = acceptable_usage_percents[i]

	proc = subprocess.Popen(cmd+[drive], stdout=subprocess.PIPE)
	output = proc.stdout.read()

	j = json.loads(output)

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
		p = "Reallocated_Sector_Ct"
		ok_val = 0
		val = -1
		for attr in j["ata_smart_attributes"]["table"]:
			if attr["name"] == p:
				val = attr["raw"]["value"]
				break
		if val == -1:
			raise Exception(f"{p} param could not be found for drive {drive}")

		if val != ok_val:
			print_err(drive, j["model_name"], p, val)
	else:
		raise Exception(f"{drive} has unrecognized type: {device_type}")
