#!/bin/bash

BASE_PATH=/usr/src
SRC_PATH=$BASE_PATH/choco

function setup
{
	if [[ $1 == "build" ]]
		then
		build
	elif [[ $1 == "setupScript" ]]
		then
		setupScript
  else
    echo "This script accepts requires either build or setupScript as argument."
	fi
}


function build
{
  set -ex
  cd $BASE_PATH
	curl -s -L https://github.com/chocolatey/choco/archive/${CHOCO_VERSION}.tar.gz --output ${CHOCO_VERSION}.tar.gz
	tar -xzf ${CHOCO_VERSION}.tar.gz 
	mv choco-${CHOCO_VERSION} $SRC_PATH
	cd $SRC_PATH
	chmod +x build.sh zip.sh 
	./build.sh -v
	# Check compiled binary.
	mono /usr/src/choco/build_output/chocolatey/choco.exe --version --allow-unofficial
}


function setupScript
{
  set -ex

  # https://chocolatey.org/docs/chocolatey-faqs#portable-application-something-that-doesnt-require-a-system-install-to-use
  # helpers, redirects, lib and tools are directories which need to be existing and writable for choco to work properly.
	mkdir -p $ChocolateyInstall/{helpers,redirects,lib,tools}
	chmod -R 750 $ChocolateyInstall/{helpers,redirects,lib,tools}
	chown -R $USER_ID.$GROUP_ID $ChocolateyInstall/{helpers,redirects,lib,tools}

  cat <<'EOF' >/usr/bin/choco
#!/bin/bash
set -e
function cleanup {
    if [ $PWD != "/" ] && [ -d opt ]; then
        rm -rf opt
    fi
}
trap cleanup EXIT
mono $ChocolateyInstall/choco.exe "$@" --allow-unofficial
EOF
  cat /usr/bin/choco
	chmod +x /usr/bin/choco
	# Check installation.
	choco --version
}

setup $1
