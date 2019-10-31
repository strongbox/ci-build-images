# Intro

This repository contains all of our CI images which are used to build [Strongbox][strongbox]. 

# Build locally

You can use the `build.sh` script to build all of the images locally.
Check out `./build.sh -h` for the available commands.

Example
```
./build.sh ./images/alpine/Dockerfile.alpine
./build.sh ./images/alpine/jdk8
./build.sh ./images/alpine/jdk8/*mvn3.6*
./build.sh --snapshot ./images/alpine/jdk8/*mvn3.6* 
```

# Structure

To keep things in order we have divided our images into two types - `base` and `jdk`. 

## Base images

The `base` images contain packages/tools which are commonly used or necessary in multiple other images (i.e. jdk images or jdk images).

Each base image should be placed under a folder in `./images/` (i.e. `./images/alpine/`) and should be named using
the distribution they represent (i.e. `./images/alpine/Dockerfile.alpine`)

## JDK images (and build tools)

JDK images provide a specific JDK version (i.e. 8, 11, etc).
They are based on the `base` images and will inherit whatever tools are available there.

The files for jdk images are located in `./images/jdk$VERSION` and should be named using the distribution name, jdk version 
and the build tool they contain (i.e. `./images/jdk8/Dockerfile.alpine.jdk8`, `./images/jdk8/Dockerfile.alpine.jdk8-mvn3.6`)

JDK images are tagged and published as `strongboxci/distribution_name:jdk${VERSION}-${BUILD_TOOL_WITH_VERSION}`

# Publishing

Our images are published in [docker hub](https://cloud.docker.com/u/strongboxci).

[<--# Generic links -->]: #
[strongbox]: https://github.com/strongbox/strongbox
