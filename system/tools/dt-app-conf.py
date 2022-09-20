#!/usr/bin/python3

import sys
import yaml
import os
from pathlib import Path

CONF_ENV_PREFIX = 'DTCONF_'

def loadConfigFromYAML(file_full_path, statusOnError):
	try:
		with open(file_full_path) as fp:
			try:
				y = yaml.safe_load(fp)
			except yaml.YAMLError:
				print(CONF_ENV_PREFIX + 'STATUS=' + statusOnError)
				print(CONF_ENV_PREFIX + 'ERROR_MSG=YAML_FILE_DOES_NOT_EXIST')
				sys.exit(1);
	except:
		print(CONF_ENV_PREFIX + 'STATUS=' + statusOnError)
		print(CONF_ENV_PREFIX + 'ERROR_MSG=' + str(sys.exc_info()[1]))
		sys.exit(1);
	return y

dt_config = loadConfigFromYAML("{}/dt_config.yaml".format(str(Path.home())), "FAILURE_NO_MAIN_CONFIG")

schemaYaml = loadConfigFromYAML(os.path.join(sys.argv[1], "config_schema.yaml"), "FAILURE_NOT_AN_APP")
appName = schemaYaml['appName']
confSchema = schemaYaml['confSchema']

def parseConfig():
	global config_parse_status
	global error_msg

	if dt_config['apps'] != None and appName in dt_config['apps']:
		schemaSet = set(confSchema.keys())
		confSet = set(dt_config['apps'][appName].keys())

		diffSchemaConf = schemaSet - confSet
		if len(diffSchemaConf) > 0:
			config_parse_status = 'FAILURE_APP_MISCONFIGURED'
			error_msg = "App '" + appName + "': Config schema has values not in config: " + str(diffSchemaConf)
			return False
		diffConfSchema = confSet - schemaSet
		if len(diffConfSchema) > 0:
			config_parse_status = 'FAILURE_APP_MISCONFIGURED'
			error_msg = "App '" + appName + "': Config has values not in config schema: " + str(diffConfSchema)
			return False

		for k in dt_config['apps'][appName].keys():
			val = dt_config['apps'][appName][k]
			
			if type(val) is bool:
				valStr = str(val).upper()
			elif type(val) is list:
				valStr = ','.join(str(x) for x in val)
			else:
				valStr = str(val)

			print(CONF_ENV_PREFIX + k + '=' + valStr)

		return True
	else:
		config_parse_status = 'FAILURE_MISSING_CONFIG'
		error_msg = 'No such app \'' + appName + '\''
		return False

config_parse_status = 'SUCCESS'
error_msg = ''
exit_status = 0 if parseConfig() else 1

print(CONF_ENV_PREFIX + 'STATUS=' + config_parse_status)
print(CONF_ENV_PREFIX + 'ERROR_MSG=' + error_msg)

sys.exit(exit_status)
