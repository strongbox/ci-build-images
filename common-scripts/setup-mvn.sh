#!/bin/bash

set -euxo pipefail

# The environment variables are set in the jdk file.
# If you need to debug - just copy them here.

export | grep -E '(JAVA_.+|MVN_.+|M2_.+|PATH)='

# Creating MDN home
mkdir -p $M2_HOME
mkdir -p $HOME/.m2/{lib/ext,repository} $HOME/.mvn

# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 1024000  -L -o "/tmp/apache-maven-${MVN_VERSION}-bin.tar.gz" "http://www-eu.apache.org/dist/maven/maven-${MVN_MAJOR_VERSION}/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz"

# Two spaces between checksum and file name - https://github.com/gliderlabs/docker-alpine/issues/174
echo "${MVN_CHECKSUM}  /tmp/apache-maven-${MVN_VERSION}-bin.tar.gz" | sha512sum -c -

# Untar.
tar --strip-components 1 -C "$M2_HOME" -xzf "/tmp/apache-maven-${MVN_VERSION}-bin.tar.gz"
ln -s $M2_HOME/bin/* /usr/bin/

# Setup settings.xml
curl -L -o $HOME/.m2/settings.xml "https://strongbox.github.io/assets/resources/maven/settings.xml"

# Use ":" for better compatibility with other distros (i.e. freebsd) and to avoid issues when username contains `.`
# https://www.freebsd.org/cgi/man.cgi?query=chown&sektion=8#end
chown -R $(id -u):$(id -g) $HOME

# Test command.
echo "Testing mvn $MVN_VERSION installation";
mvn -version

# this is necessary for VMs, since docker images already have the proper env vars pre-defined.
echo "Setup /etc/profile.d/mvn.sh"
printf "export M2_HOME=$M2_HOME \nexport PATH=\$PATH:$M2_HOME/bin\n" > /etc/profile.d/mvn.sh
chmod 644 /etc/profile.d/mvn.sh
