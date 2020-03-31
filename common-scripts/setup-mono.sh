#!/bin/bash

set -euxo pipefail

# Some tools like `nuget|choco` will attempt to write at `/usr/share/.mono/keypairs` when you attempt to push.
mkdir -p /usr/share/.mono
chmod -R 770 /usr/share/.mono
chown -R root.$GROUP_ID /usr/share/.mono

echo "Testing mono installation..." > /dev/null;
mono --version
