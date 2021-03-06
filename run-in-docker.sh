#!/bin/sh

# Support --rm flag optionally
rmflag=
[ "$1" = "--rm" ] && rmflag="--rm"

PROJ_URL="https://github.com/gunnarx/build-common-api-cpp-native"
BRANCH="vsomeip_2.14.16"
DISTRO=ubuntu:18.04  # This has java version 8 available (not default)
JAVA_PACKAGE=openjdk-8-jre

echo This will run the script in a controlled docker container environment

set -e
docker run -d -i --name=buildcapicxx $DISTRO
docker exec buildcapicxx bash -c "apt-get update ; apt-get install -y git $JAVA_PACKAGE"
docker exec buildcapicxx bash -c "rm -rf /workdir ; mkdir /workdir"

# Instead of cloning the git repo we copy the local working directory so that
# any local changes get included during developmetn.
mkdir -p /tmp/workdir.tmp
# Files to copy from working directory to container:
cp -R *.sh examples /tmp/workdir.tmp
cd /tmp/workdir.tmp

docker cp . buildcapicxx:/workdir
set +e

docker exec buildcapicxx bash -c "cd /workdir ; ./build-commonapi.sh"

if [ -n "$rmflag" ] ; then
  docker stop buildcapicxx
  docker rm buildcapicxx
fi

echo "Running D-Bus tests"
docker exec  -ti buildcapicxx bash -c "/workdir/test_dbus.sh"
if [ $? -eq 0 ] ; then
  echo "docker-exec: D-bus test run in container succeeded."
else
  echo "docker-exec: D-bus test, something failed"
fi

echo "Running SOME/IP tests"
docker exec  -ti buildcapicxx bash -c "/workdir/test_someip.sh"
if [ $? -eq 0 ] ; then
  echo "docker-exec: SOME/IP test run in container succeeded."
else
  echo "docker-exec: SOME/IP test, something failed"
fi

echo "---"
echo "Container build is now done.  To look at the results, find it among docker ps (not running), start it and then exec a shell in the container."
echo
