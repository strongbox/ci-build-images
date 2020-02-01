#!/bin/bash

set -euxo pipefail

echo "Testing mono installation..." > /dev/null;
mono --version

echo "Installing nuget $NUGET_VERSION..." > /dev/null
# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 1024000 -j -L -o ${NUGET_PATH} "https://dist.nuget.org/win-x86-commandline/v${NUGET_VERSION}/nuget.exe"
chmod +x ${NUGET_PATH}

echo "Creating /etc/mono/registry with the right permissions" > /dev/null
mkdir -p /etc/mono/registry
chmod uog+rw /etc/mono/registry

echo "Testing $NUGET_PATH installation..." > /dev/null;
mono $NUGET_PATH

echo "Fixing ${HOME} permissions..." > /dev/null
chown -R ${USER_ID}.${GROUP_ID} ${HOME}
