#!/bin/bash
echo "Testing local builder!"
 
RUN_DEBUG="bash -x "

${RUN_DEBUG} /tmp/install.sh config_host --non-interactive
${RUN_DEBUG} /tmp/install.sh create -c localbuilder-test --non-interactive
