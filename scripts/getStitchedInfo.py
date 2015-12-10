#!/usr/bin/env python

import ConfigParser
import json
import sys

config = ConfigParser.ConfigParser()
config.read(sys.argv[1])

ret = {}
for section in config.sections():
    curr = {}
    if config.has_option(section, 'input_file'):
        filename = config.get(section, 'input_file')
        filename = '_'.join(filename.split('_')[1:])
        curr['file'] = filename
    else:
        continue
    if config.has_option(section, 'xs'):
        curr['xs'] = config.get(section, 'xs')
    if config.has_option(section, 'filter'):
        curr['filter'] = config.get(section, 'filter')
    if config.has_option(section, 'prefix'):
        curr['prefix'] = config.get(section, 'prefix')
    ret[section] = curr

print json.dumps(ret, sort_keys=True, indent=4)
