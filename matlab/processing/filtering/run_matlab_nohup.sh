#!/bin/bash

# Check if the user provided a command name
if [ -z "$1" ]; then
  echo "Usage: $0 <MatlabFunctionName>"
  exit 1
fi

MATLAB_COMMAND=$1

nohup matlab -nosplash -nodisplay -nodesktop -r "try; $MATLAB_COMMAND; catch; save code_err1; end; quit" &

