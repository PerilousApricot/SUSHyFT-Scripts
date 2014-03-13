#!/bin/bash

# make a command unconditionally return zero. crab -status returns 1 for some
# reason

$@
exit 0
