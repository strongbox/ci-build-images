#!/bin/bash

set -euxo pipefail

# The environment variables are set in the jdk file.
# If you need to debug - just copy them here.

export | grep -E '(JAVA_.+|JDK_.+|JMETER_.+|PATH)='

echo "Installing jmeter" > /dev/null
cd /java
curl --fail --speed-time 15 --speed-limit 1024000 -O -J -L "http://apache.cbox.biz/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz"
echo "${JMETER_CHECKSUM} apache-jmeter-${JMETER_VERSION}.tgz" | sha512sum -c -
tar zxf apache-jmeter-${JMETER_VERSION}.tgz
ln -s /java/apache-jmeter-${JMETER_VERSION}/bin/{jmeter,jmeter-server} /usr/local/bin/
rm -rfv "/java/apache-jmeter-${JMETER_VERSION}/"*docs*

echo "Testing jmeter installation..." > /dev/null;
jmeter --version
rm -rf apache-jmeter-${JMETER_VERSION}.tgz
