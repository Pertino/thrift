#!/bin/bash -xue

check_options()
{
	local _var=$(echo $1 | tr '[a-z]' '[A-Z]')

	[ "${_var}" = "YES" ] || [ "${_var}" = "1" ]
}

build_timestamp()
{
	local _step=$1

	echo "Build ${_step} at $(date "+%Y-%m-%d %X %z")"
}

build_timestamp "started"

# Options
BUILD_ONLY=${BUILD_ONLY:=NO}
BUILD_NUMBER=${BUILD_NUMBER:=0}
WORKSPACE=${WORKSPACE:=$(dirname $0)}

cd ${WORKSPACE}

mkdir obj
cd obj

PACKAGE_VENDOR_VERSION_SUFFIX="cp${BUILD_NUMBER}"

cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_TESTING=OFF \
	-DBUILD_EXAMPLES=OFF \
	-DTHRIFT_PACKAGE_VENDOR_VERSION_SUFFIX="${PACKAGE_VENDOR_VERSION_SUFFIX}" \
	..

make -j $(nproc)
make package

build_timestamp "finished"

if check_options "${BUILD_ONLY}"; then
	exit 0
fi

THRIFT_PACKAGE_NAME=$(echo *.deb)
ARTIFICATORY_URL=https://pertino.artifactoryonline.com/pertino/private-deb/pool

THRIFT_COMPONENT=deb.component=main
THRIFT_ARCHITECTURE=deb.architecture=amd64
THRIFT_DISTRO=deb.distribution=$(lsb_release -c | awk '{ print $2 }')

curl \
	--netrc-file ~/.netrc \
	-X PUT ${ARTIFICATORY_URL}/${THRIFT_PACKAGE_NAME}\;${THRIFT_DISTRO}\;${THRIFT_COMPONENT}\;${THRIFT_ARCHITECTURE} \
	-T ${THRIFT_PACKAGE_NAME}

build_timestamp "deployed"
