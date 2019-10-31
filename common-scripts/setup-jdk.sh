#!/bin/bash

set -euxo pipefail

# The environment variables are set in the jdk file.
# If you need to debug - just copy them here.

# Creating JDK home
mkdir -p ${JAVA_HOME}
ln -s ${JAVA_HOME} /java/jdk

# Downloading & Installing
cd ${JAVA_HOME}
curl --fail -O -J -L "${JDK_DW_URL}"
echo "${JDK_CHECKSUM} ${JDK_DW_FILENAME}" | sha256sum -c -
7z l ${JDK_DW_FILENAME}
7z x -y -snl ${JDK_DW_FILENAME}

# Fixing directory structure
mv ${JAVA_HOME}/${JDK_DW_DIR_NAME}/* ${JAVA_HOME}
ls -al ${JAVA_HOME}/
ls -al ${JAVA_HOME}/bin/*
rm -rf ${JAVA_HOME:?}/${JDK_DW_DIR_NAME}*
rm -rfv "$JAVA_HOME/"*src.zip
rm -rfv "$JAVA_HOME/lib/missioncontrol" \
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
