#!/bin/bash

echo "Stop250 Stop300 Stop350 Stop400 Stop450 Stop500 Stop600" | xargs -P 8 -n1 -I {} ./run_mass.sh {} OLD

