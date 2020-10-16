#!/bin/bash

set -euxo pipefail

echo "Make dirs and fix permissions"
mkdir -p $SBT_HOME/.sbt $HOME/.sbt $HOME/.ivy2 $HOME/.cache
chown -R $USER_ID.$GROUP_ID $SBT_HOME/.sbt $HOME/.sbt $HOME
echo "Downloading https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" > /dev/null
# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 1024000 -L -C - "https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" | tar -xz --strip-components 1 -C ${SBT_HOME}
ln -s $SBT_HOME/bin/* /usr/bin/

# This is a special patch, which fixes some mysterious issue with SBT's bash script which is unable
# to pick the environment variables for some unknown reason.
# Removing this will result in the following build failure:
#  gave the following error:
#  [ERROR] /java/sbt-1.1.6/bin/sbt-launch-lib.bash: line 258: java: command not found
#   mkdir: cannot create directory ??????: No such file or directory
#   java/sbt-1.1.6/bin/sbt-launch-lib.bash: line 73: java: command not found
#   java/sbt-1.1.6/bin/sbt-launch-lib.bash: line 73: java: command not found
# OR something like
#  gave the following error:
#  [ERROR] /usr/bin/sbt: line 336: java: command not found
#    mkdir: cannot create directory ??????: No such file or directory
#    /usr/bin/sbt: line 343: java: command not found
#    /usr/bin/sbt: line 127: exec: java: not found
sed -i 's/^declare java_cmd=java/declare java_cmd=\/java\/jdk\/bin\/java/' /java/sbt-$SBT_VERSION/bin/sbt 
