#!/bin/bash

# Simply copy the the version from https://adoptopenjdk.net/releases.html?variant=openjdk8&jvmVariant=hotspot
# i.e. jdk8u275-b01 || jdk-11.0.9.1+1 || etc
JDK_VERSION_STRING=${JDK_VERSION_STRING:-""}
# i.e. /java/jdk8u275-b01 || /java/jdk-11.0.9.1+1 || etc
JAVA_HOME=${JAVA_HOME:-"/java/jdk"}
# available at https://adoptopenjdk.net/releases.html?variant=openjdk8&jvmVariant=hotspot
JDK_CHECKSUM=${JDK_CHECKSUM:-""}

JDK_OS=${JDK_OS:-"linux"}
JDK_ARCH=${JDK_ARCH:-"x64"}
JDK_JVM=${JDK_JVM:-"hotspot"}

JDK_VERSION=""
JDK_MAJOR_VERSION=""
JDK_DW_URL=""
JDK_DW_FILENAME=""
JDK_PATH_VERSION="jdk"
PARSE_ONLY="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install)  INSTALL_HOME=$2; shift 2; ;;
    -a|--arch)     JDK_ARCH=$2; shift 2; ;;
    -c|--checksum) JDK_CHECKSUM=$2; shift 2; ;;
    -j|--jvm)      JDK_JVM=$2; shift 2; ;;
    -v|--version)  JDK_VERSION_STRING=$2; shift 2; ;;
    -p|--parse)    PARSE_ONLY="true"; shift;;
    *) echo "Unknown option $1 !"; exit 1;;
  esac
done

JDK_VERSION_STRING=${JDK_VERSION_STRING:-$1}

prepareUrl()
{
  # HotSpot
  # JDK  8 Linux = https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_hotspot_8u275b01.tar.gz
  # JDK 11 Linux = https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.9.1%2B1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.9.1_1.tar.gz
  # JDK 15 Linux = https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.1%2B9/OpenJDK15U-jdk_x64_linux_hotspot_15.0.1_9.tar.gz
  # JDK 17 Linux = https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.2%2B8/OpenJDK17U-jdk_x64_linux_hotspot_17.0.2_8.tar.gz

  # using -E since it's more universal / portable than -r
  JDK_VERSION=`echo "$JDK_VERSION_STRING" | sed -E 's/^(jdk(-)?)?(.+)$/\3/'`
  JDK_MAJOR_VERSION=`echo $JDK_VERSION | sed -E 's/^([0-9]+)(u|.)(.+)/\1/'`

  JDK_PATH_VERSION="jdk"
  if [[ $JDK_MAJOR_VERSION -gt 8 ]]; then
    JDK_PATH_VERSION+=-`echo $JDK_VERSION | sed -E 's/\+/\%2B/g'`
    FILENAME_VERSION=`echo $JDK_VERSION | sed -E 's/(\%2B9|\+)/_/g'`
    if [[ $JDK_MAJOR_VERSION -le 15 ]]; then
      JDK_DW_URL="https://github.com/AdoptOpenJDK/openjdk${JDK_MAJOR_VERSION}-binaries/releases/download/"
    else
      JDK_DW_URL="https://github.com/adoptium/temurin${JDK_MAJOR_VERSION}-binaries/releases/download/"
    fi
  else
    JDK_PATH_VERSION+=$JDK_VERSION;
    FILENAME_VERSION=`echo $JDK_VERSION | sed -E 's/-b/b/g'`
    JDK_DW_URL="https://github.com/AdoptOpenJDK/openjdk${JDK_MAJOR_VERSION}-binaries/releases/download/"
  fi

  JDK_DW_FILENAME="OpenJDK${JDK_MAJOR_VERSION}U-jdk_${JDK_ARCH}_${JDK_OS}_${JDK_JVM}_${FILENAME_VERSION}.tar.gz"

  if [[ -z $INSTALL_HOME && $JDK_MAJOR_VERSION -le 15 ]]; then
   INSTALL_HOME="/java/adoptopenjdk-$JDK_VERSION";
  else
   INSTALL_HOME="/java/temurin-$JDK_VERSION";
  fi

  JDK_DW_URL+="$JDK_PATH_VERSION/"
  JDK_DW_URL+="$JDK_DW_FILENAME"

  printf "Configuration: \n\n"
  printf "INSTALL_HOME\t\t= %s\n" $INSTALL_HOME
  printf "JAVA_HOME\t\t= %s\n" $JAVA_HOME
  printf "JDK_VERSION\t\t= %s\n" $JDK_VERSION
  printf "JDK_MAJOR_VERSION\t= %s\n" $JDK_MAJOR_VERSION
  printf "JDK_OS\t\t\t= %s\n" $JDK_OS
  printf "JDK_ARCH\t\t= %s\n" $JDK_ARCH
  printf "JDK_JVM\t\t\t= %s\n" $JDK_JVM
  printf "JDK_DW_URL\t\t= %s\n" $JDK_DW_URL
  printf "JDK_DW_FILENAME\t\t= %s\n" $JDK_DW_FILENAME
  printf "JDK_CHECKSUM\t\t= %s\n\n" $JDK_CHECKSUM

  # validate
  [[ -z $JDK_VERSION ]] && echo "Could not find JDK_VERSION in $JDK_VERSION_STRING!" && exit 1;
  [[ -z $JDK_MAJOR_VERSION ]] && echo "Could not find JDK_MAJOR_VERSION in $JDK_VERSION_STRING!" && exit 1;

  # exit, if parting only - useful for debugging.
  [[ "$PARSE_ONLY" == "true" ]] && echo "Parse only mode. Exiting." && exit 0;
}

prepareUrl

printf "\nDownloading...\n"

set -euxo pipefail

export | grep -E '(JAVA_.+|JDK_.+|GLIBC_.+|PATH)='

# Creating JDK home
mkdir -p ${INSTALL_HOME}
ln -s ${INSTALL_HOME} /java/jdk

# Creating /etc/profile.d/autojdk paths for distributions which support it.
mkdir -p /usr/java/
ln -s ${INSTALL_HOME} /usr/java/latest

# Downloading & Installing
cd ${INSTALL_HOME}
# https://ec.haxx.se/usingcurl/usingcurl-timeouts
# speed-limit is in bytes.
curl --fail --speed-time 15 --speed-limit 512000 -o $JDK_DW_FILENAME -J -L "${JDK_DW_URL}"

# Two spaces between checksum and file name - https://github.com/gliderlabs/docker-alpine/issues/174
echo "${JDK_CHECKSUM}  ${JDK_DW_FILENAME}" | sha256sum -c -
tar --strip-components 1 -xzf ${JDK_DW_FILENAME}

# Fixing directory structure
ls -al ${INSTALL_HOME}/
ls -al ${INSTALL_HOME}/bin/*
rm -rfv "$INSTALL_HOME/man" \
        "$INSTALL_HOME/"*src.zip \
        "$INSTALL_HOME/lib/missioncontrol" \
        "$INSTALL_HOME/lib/visualvm" \
        "$INSTALL_HOME/lib/"*javafx* \
        "$INSTALL_HOME/jre/lib/plugin.jar" \
        "$INSTALL_HOME/jre/lib/ext/jfxrt.jar" \
        "$INSTALL_HOME/jre/bin/javaws" \
        "$INSTALL_HOME/jre/lib/javaws.jar" \
        "$INSTALL_HOME/jre/lib/desktop" \
        "$INSTALL_HOME/jre/plugin" \
        "$INSTALL_HOME/jre/lib/"deploy* \
        "$INSTALL_HOME/jre/lib/"*javafx* \
        "$INSTALL_HOME/jre/lib/"*jfx* \
        "$INSTALL_HOME/jre/lib/amd64/libdecora_sse.so" \
        "$INSTALL_HOME/jre/lib/amd64/"libprism_*.so \
        "$INSTALL_HOME/jre/lib/amd64/libfxplugins.so" \
        "$INSTALL_HOME/jre/lib/amd64/libglass.so" \
        "$INSTALL_HOME/jre/lib/amd64/libgstreamer-lite.so" \
        "$INSTALL_HOME/jre/lib/amd64/"libjavafx*.so \
        "$INSTALL_HOME/jre/lib/amd64/"libjfx*.so

# this is necessary for VMs, since docker images already have the proper env vars pre-defined.
echo "Setup /etc/profile.d/java.sh"
printf "export JAVA_HOME=/java/jdk \nexport PATH=\$JAVA_HOME/bin:\$PATH\n" > /etc/profile.d/java.sh
chmod 644 /etc/profile.d/java.sh
rm -rfv "/java/${JDK_DW_FILENAME}"
. /etc/profile.d/java.sh

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
