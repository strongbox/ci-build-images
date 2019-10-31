#!/bin/bash

set -euxo pipefail

echo "Make dirs and fix permissions"
mkdir -p $SBT_HOME/.sbt $HOME/.sbt
chown -R $USER_ID.$GROUP_ID $SBT_HOME/.sbt $HOME/.sbt
echo "Downloading https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" > /dev/null
curl -L -C - "https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" | tar -xz --strip-components 1 -C ${SBT_HOME}
ln -s $SBT_HOME/bin/* /usr/bin/
