#!/bin/bash
echo "Testing Redpesk container installer ..."
 
RUN_DEBUG="bash -x "
# This path must match that of the Vagrant provisioner
INSTALL_SCRIPT="/home/vagrant/install.sh"

${RUN_DEBUG} ${INSTALL_SCRIPT} config_host --non-interactive
${RUN_DEBUG} ${INSTALL_SCRIPT} create -c localbuilder-test --non-interactive
${RUN_DEBUG} ${INSTALL_SCRIPT} create -c redpesk-cloud-publication -t cloud-publication --non-interactive
