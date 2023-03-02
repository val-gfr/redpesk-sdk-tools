#!/bin/bash

if [ -f ./test_SDK_var.sh ]; then
    source ./test_SDK_var.sh
    ./test_SDK.sh  --branch "${BRANCH}"
else
    ./test_SDK.sh 
fi