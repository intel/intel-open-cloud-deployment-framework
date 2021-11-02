#!/bin/bash

source ${RALLY_VIRTUAL_PATH}/bin/activate
source ${RALLY_OPS_ENV}

rally db recreate

# create deployment
rally deployment create --fromenv --name current

rally deployment check

# Start tasks
# You may uncomment the following lines to execute the rally benchmark
# rally task start task.json
