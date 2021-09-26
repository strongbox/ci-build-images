#!/bin/bash

CURRENT_DIR=$(realpath $(dirname "$0"))
BUILD_WITH_NO_CACHE_ARG=""
BUILD_PATH=$CURRENT_DIR
MAIN_BUILD_LOG=$CURRENT_DIR/build.log
TAG_SNAPSHOT=""
# So that we can pass the timestamp from the CI
TIMESTAMP=${TIMESTAMP:-`date +"%y%m%d%H%M%S"`}
GET_IMAGE=""

FORCE_PODMAN=""

getDistribution() {
  echo $1 | awk -F[=.] '{print $2}'
}

getBasePath() {
  echo $(dirname $1)
}

getFilename() {
  echo $(basename $1)
}

getTag() {
  TAG=$(echo $1 | awk -F "Dockerfile.$2." '{print $2}')
  if [[ -z $TAG ]]; then
    TAG="base"
  fi

  if [[ ! -z "$TAG_SNAPSHOT" ]]; then
    TAG="$TAG-$TAG_SNAPSHOT"
  fi
  echo "$TAG"
}

getImage() {
  echo "strongboxci/$1:$2"
}

getImageFromFile() {
  DOCKER_FILE=$1
  BASEPATH=$(getBasePath "$DOCKER_FILE")
  FILENAME=$(getFilename "$DOCKER_FILE")
  DISTRIBUTION=$(getDistribution "$FILENAME")
  TAG=$(getTag "$FILENAME" "$DISTRIBUTION")
  IMAGE=$(getImage "$DISTRIBUTION" "$TAG")
  echo $IMAGE
}

build() {
  DOCKER_FILE=$1

  echo "=== Building $DOCKER_FILE"
  echo ""

  BASEPATH=$(getBasePath "$DOCKER_FILE")
  FILENAME=$(getFilename "$DOCKER_FILE")
  DISTRIBUTION=$(getDistribution "$FILENAME")
  TAG=$(getTag "$FILENAME" "$DISTRIBUTION")
  IMAGE=$(getImage "$DISTRIBUTION" "$TAG")
  DOCKER_VERSION=$(docker -v)
  PODMAN_VERSION=$(podman -v 2> /dev/null)

  BUILD_CMD="docker"
  BUILD_ARGS=""
  [[ ! -z "$TAG_SNAPSHOT" ]] && BUILD_ARGS=" --build-arg SNAPSHOT=-$TAG_SNAPSHOT"

  [[ ! -z "$FORCE_PODMAN" ]] && BUILD_CMD="podman"

  printf "Distribution:\t %s\n" $DISTRIBUTION
  printf "Tag:\t\t %s\n" $TAG
  printf "Image:\t\t %s\n" $IMAGE
  printf "Docker:\t\t %s\n" "$DOCKER_VERSION"
  printf "Podman:\t\t %s\n\n" "$PODMAN_VERSION"

  (set -euxo pipefail; $BUILD_CMD build -f "$DOCKER_FILE" -t "$IMAGE" $BUILD_ARGS $BUILD_WITH_NO_CACHE_ARG $CURRENT_DIR | tee "$DOCKER_FILE.build.log") || {
    echo "fail: $IMAGE" >> $MAIN_BUILD_LOG
    echo "Done" >> $MAIN_BUILD_LOG
    exit 1
  }

  printf "\nTo test the image use: \n\n%s run -it --rm %s \n\n" "$BUILD_CMD" "$IMAGE"

  echo "success: $IMAGE" >> $MAIN_BUILD_LOG
}

usage() {
  cat <<EOF

 $0 [options] path

  path:
    is not specified  - will build all Dockerfiles under ./images/
    is a directory    - will build all Dockerfiles in that path
    is a file         - will build that Dockerfile.

  Options:
    -h |--help          Prints this help message.
    -c |--clear         Clears all temp/log files from the repository.
    -nc|--no-cache      Adds --no-cache to the docker build command
    --podman            Force build with podman (experimental)
    -s |--snapshot      Tag the images as snapshots (i.e. strongboxci/alpine:base-TIMESTAMP||PR-123||BRANCH)
    -gi|--get-image     Prints the full image and tag (i.e. strongboxci/alpine:base-TIMESTAMP||PR-123||BRANCH; needed for CI)

EOF
    exit 0
}

clearLogs() {
    (set -ex; find . -type f -name "*.log" -exec rm -rfv {} \;)
    exit 0
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--clear|--clean) clearLogs; exit 0; ;;
        -nc|--no-cache) BUILD_WITH_NO_CACHE_ARG=" --no-cache "; shift 1; ;;
        --podman) FORCE_PODMAN="true"; shift 1; ;;
        -s|--snapshot)
            # Jenkins PR/Branch env
            if [[ ! -z "$CHANGE_ID" ]]; then
              TAG_SNAPSHOT="PR-$CHANGE_ID"
            elif [[ ! -z "$BRANCH_NAME" ]]; then
              TAG_SNAPSHOT="$BRANCH_NAME"
            else
              TAG_SNAPSHOT="$TIMESTAMP"
            fi
            shift
        ;;
        --get-image) GET_IMAGE=true; shift; ;;
        -h|--help) usage; exit 0; ;;
    *) POSITIONAL+=("$1"); shift;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# Make it possible to pass multiple Dockerfile paths (either directories or files)
for BUILD_PATH in "$@"; do
  if [[ ! -z $BUILD_PATH ]]; then
    # Clear main build log before starting.
    if [[ -z "$GET_IMAGE" ]]; then
      truncate -s 0 $MAIN_BUILD_LOG
    fi

    # build all Dockerfiles in a directory
    if [[ -d $BUILD_PATH ]]; then
      for dockerFile in $(find $BUILD_PATH -type f -name "*Dockerfile*" ! -name "*.log" ! -name "*.bkp*" | sort | xargs); do
        if [[ -z "$GET_IMAGE" ]]; then
          build "$dockerFile"
        else
          getImageFromFile "$dockerFile"
        fi
      done
      if [[ -z "$GET_IMAGE" ]]; then
        echo "Done" >> $MAIN_BUILD_LOG
      fi
    # build a specific Dockerfile
    elif [[ -f $BUILD_PATH ]]; then
      if [[ -z "$GET_IMAGE" ]]; then
        build "$BUILD_PATH"
        echo "Done" >> $MAIN_BUILD_LOG
      else
        getImageFromFile "$BUILD_PATH"
      fi
    # what just happened?
    else
      echo "$BUILD_PATH neither a file nor a directory. Exiting."
      exit 1
    fi
  fi

  [[ ! -z "$GET_IMAGE" ]] || echo ""
done
