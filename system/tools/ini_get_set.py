#!/usr/bin/python3

import os
import sys
import configparser
import argparse

parser = argparse.ArgumentParser(description='Util to Get/Set values in INI style config files.')

group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('--set', dest='do_set', action='store_true', help='Set value')
group.add_argument('--get', dest='do_set', action='store_false', help='Get value')

parser.add_argument('--file', type=str, help='INI file', required=True)
parser.add_argument('--section', type=str, help='Config section', required=True)
parser.add_argument('--key', type=str, help='Config key', required=True)
parser.add_argument('--value', type=str, help='Config value')

args = parser.parse_args()

if args.do_set and args.value is None:
    parser.error("--set requires --value")

try:
    config = configparser.ConfigParser()
    # to prevent everything becoming lower case
    config.optionxform = str

    if not os.path.isfile(args.file):
        raise Exception("No such file: " + args.file)

    config.read(args.file)

    if args.do_set:
        print("Setting [" + args.section + "] " + args.key + "=" + args.value)
        config.set(args.section, args.key, args.value)
        with open(args.file, 'w') as configfile:
            config.write(configfile)
    else:
        print(config.get(args.section, args.key))

except Exception as e:
    print(str(e))
    sys.exit(1)

sys.exit(0)
