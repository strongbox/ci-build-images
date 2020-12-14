#!/bin/bash

set -euxo pipefail

mkdir -p $GRADLE_HOME $HOME/.gradle
echo "Downloading https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 1024000 -o /tmp/gradle-$GRADLE_VERSION.zip -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
unzip -d /java /tmp/gradle-$GRADLE_VERSION.zip
ln -s $GRADLE_HOME/bin/* /usr/bin/
chown ${USER_ID}:${GROUP_ID} $HOME/.gradle $GRADLE_HOME
echo "Testing gradle installation" > /dev/null
gradle --version
