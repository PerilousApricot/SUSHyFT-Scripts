#!/bin/bash

das_client.py --query="dataset dataset=$1 | grep dataset.nevents" --format=plain --das-headers --limit=0
