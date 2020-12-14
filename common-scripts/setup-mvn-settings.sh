#!/bin/bash

OWNER=$(id -u):$(id -g)
USER_HOME=/home/$(id -u -n)

while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--owner) OWNER=$2; shift 2; ;;
    -u|--user)  USER_HOME=/home/$2; shift 2; ;;
    -h|--help)
       printf "\nUsage %s: \n\n" $(basename $0)
       printf "  -o|--owner [default: \$(id -u):\$(id -g)]  The owner of the .m2 path \n"
       printf "  -u|--user  [default: \$(id -u -n)]        The user for which we're configuring the settings.xml\n\n"
       exit 1;;
    *) echo "Unknown option $1 !"; exit 1;;
  esac
done

set -euxo pipefail

# Use ":" for better compatibility with other distros (i.e. freebsd) and to avoid issues when username contains `.`
# https://www.freebsd.org/cgi/man.cgi?query=chown&sektion=8#end
echo "Creating $USER_HOME/.m2 and $USER_HOME/.mvn" > /dev/null
mkdir -p $USER_HOME/.m2/repository $USER_HOME/.mvn

# Setup settings.xml
curl -L -o $USER_HOME/.m2/settings.xml "https://strongbox.github.io/assets/resources/maven/settings.xml"

echo "Fixing ownership of $USER_HOME/.m2 and $USER_HOME/.mvn to $OWNER"
chown -R $OWNER $USER_HOME/.m2 $USER_HOME/.mvn
