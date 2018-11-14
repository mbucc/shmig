#!/bin/bash

set -e

function setup_env() {
    builddir="pkg-build"
}

function place_files() {
    local pkgname="$1"
    local targdir="$2"
    local pkgtype="$3"

    mkdir -p "$targdir/usr/bin/"
    cp "shmig" "$targdir/usr/bin/"
}

function build_package() {
    local pkgtype="$1"
    local targdir="$2"
    local builddir="$3"

    if [ "$pkgtype" == "deb" ]; then
        if ! build_deb_package "$targdir" "$builddir"; then
            >&2 echo "E: Couldn't build $pkgtype package. Cleaning up and skipping."
            rm -Rf "$targdir"
        fi
    else
        >&2 echo
        >&2 echo "E: Don't know how to build packages of type '$pkgtype'"
        >&2 echo
        exit 11
    fi
}

. /usr/lib/ks-std-libs/libpkgbuilder.sh
build

