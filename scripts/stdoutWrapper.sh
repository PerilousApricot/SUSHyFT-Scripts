#!/bin/bash

# stdoutWrapper [stdout target] [executable] [arg1] [arg2] ...

TARGET=$1
shift
exec $@ | tee $TARGET
