#!/bin/bash

set -euxo pipefail

# The environment variables are set in the jdk file.
# If you need to debug - just copy them here.

# Creating JDK home
mkdir -p ${JAVA_HOME}
ln -s ${JAVA_HOME} /java/jdk

# Downloading & Installing
cd ${JAVA_HOME}
# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 1024000 -o $JDK_DW_FILENAME -J -L "${JDK_DW_URL}"
echo "${JDK_CHECKSUM} ${JDK_DW_FILENAME}" | sha256sum -c -
7z l ${JDK_DW_FILENAME}
7z x -y -snl ${JDK_DW_FILENAME}

# Fixing directory structure
mv ${JAVA_HOME}/${JDK_DW_DIR_NAME}/* ${JAVA_HOME}
ls -al ${JAVA_HOME}/
ls -al ${JAVA_HOME}/bin/*
rm -rfv "$JAVA_HOME/$JDK_DW_DIR_NAME"* \
        "$JAVA_HOME/man" \
        "$JAVA_HOME/"*src.zip \
        "$JAVA_HOME/lib/missioncontrol" \
        "$JAVA_HOME/lib/visualvm" \
        "$JAVA_HOME/lib/"*javafx* \
        "$JAVA_HOME/jre/lib/plugin.jar" \
        "$JAVA_HOME/jre/lib/ext/jfxrt.jar" \
        "$JAVA_HOME/jre/bin/javaws" \
        "$JAVA_HOME/jre/lib/javaws.jar" \
        "$JAVA_HOME/jre/lib/desktop" \
        "$JAVA_HOME/jre/plugin" \
        "$JAVA_HOME/jre/lib/"deploy* \
        "$JAVA_HOME/jre/lib/"*javafx* \
        "$JAVA_HOME/jre/lib/"*jfx* \
        "$JAVA_HOME/jre/lib/amd64/libdecora_sse.so" \
        "$JAVA_HOME/jre/lib/amd64/"libprism_*.so \
        "$JAVA_HOME/jre/lib/amd64/libfxplugins.so" \
        "$JAVA_HOME/jre/lib/amd64/libglass.so" \
        "$JAVA_HOME/jre/lib/amd64/libgstreamer-lite.so" \
        "$JAVA_HOME/jre/lib/amd64/"libjavafx*.so \
        "$JAVA_HOME/jre/lib/amd64/"libjfx*.so

# Testing JDK installation.
echo "Test jdk symlink..." > /dev/null;
if [[ ! -f "/java/jdk/bin/java" ]]; then
  echo "Symlink is broken!";
  exit 1;
fi

echo "Testing java installation..." > /dev/null;
java -version

echo "Testing javac installation..." > /dev/null;
javac -version

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
