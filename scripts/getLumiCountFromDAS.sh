#!/bin/bash

das_client.py --query="run,lumi dataset=$1" --format=json --das-headers --limit=0 | countLumis.py 
