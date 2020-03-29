#!/bin/bash

function setup
{
	if [[ $1 == "build" ]]
		then
		build
	elif [[ $1 == "setupScript" ]]
		then
		setupScript
	fi
}


function build
{
	curl -s -L https://github.com/chocolatey/choco/archive/${CHOCO_VERSION}.tar.gz --output ${CHOCO_VERSION}.tar.gz
	tar -xzf ${CHOCO_VERSION}.tar.gz 
	mv choco-${CHOCO_VERSION} choco
	cd choco
	chmod +x build.sh zip.sh 
	./build.sh -v
}


function setupScript
{
	cp -r choco/build_output/chocolatey/ /opt/chocolatey

	echo $'\n
	#!/bin/bash \n
	set -e \n
	function cleanup { \n
	    if [ $PWD != "/" ] && [ -d opt ]; then \n
	        rm -rf opt \n
	    fi \n
	} \n
	trap cleanup EXIT \n
	mono /opt/chocolatey/choco.exe "$@" --allow-unofficial \n
	'  > /usr/bin/choco 

	chmod +x /usr/bin/choco
	mkdir -p /opt/chocolatey/lib
	choco --version
}

setup $1
