#!/bin/bash

set -euxo pipefail

mkdir -p $M2_HOME
mkdir -p $HOME/.m2/{lib/ext,repository} $HOME/.mvn
curl -L -C - "http://www-eu.apache.org/dist/maven/maven-${MVN_MAJOR_VERSION}/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" | tar -xz --strip-components 1 -C $M2_HOME
ln -s $M2_HOME/bin/* /usr/bin/
curl -L -o $HOME/.m2/settings.xml "https://strongbox.github.io/assets/resources/maven/settings.xml"
chown -R ${USER_ID}.${GROUP_ID} $HOME
echo "Testing mvn $MVN_VERSION installation";
mvn -version
