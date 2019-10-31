#!/bin/bash

set -euxo pipefail

groupadd -g ${GROUP_ID} jenkins
useradd -d $HOME -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash -m jenkins
getent group docker || groupadd docker
usermod -a -G docker jenkins
mkdir -p /home/jenkins 
chown ${USER_ID}.${GROUP_ID} /home/jenkins
mkdir -p /ci
curl -o /ci/strongbox-distribution.sh -L https://api.bitbucket.org/2.0/snippets/strongbox/ge7d85/files/strongbox-distribution.sh
curl -o /ci/wait-for-response.sh -L https://api.bitbucket.org/2.0/snippets/strongbox/eaGLo7/files/wait-for-response.sh
chmod -R 755 /ci/
