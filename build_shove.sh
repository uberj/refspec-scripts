#!/bin/bash
set -x -e

BRANCH=rpm-build
REMOTE=https://github.com/uberj/shove.git
SRC0=shove
RPM_DIR=$(pwd)/shove-rpm/
DEB_DIR=$(pwd)/shove-deb/

rm -rf $RPM_DIR
rm -rf $DEB_DIR
mkdir -p $RPM_DIR
mkdir -p $DEB_DIR
rm -rf $SRC0
git clone --depth 1 -b $BRANCH --single-branch $REMOTE $SRC0

function build_rpm () {
    pushd shove
        python setup.py bdist_rpm --source-only
        python setup.py bdist_rpm --spec-only --requires "pika>=0.9.13" 
        rpmbuild -ba --define "_topdir ${PWD}/build/bdist.linux-x86_64/rpm" dist/shove.spec

        # TODO, don't hardcode the version
        cp build/bdist.linux-x86_64/rpm/RPMS/noarch/shove-0.1.4-1.noarch.rpm $1
    popd shove
}

function build_deb () {
    pushd $1
        cp $RPM_DIR/shove-0.1.4-1.noarch.rpm .
        alien --generate shove-0.1.4-1.noarch.rpm
        cd shove-0.1.4/
        sed -i 's/Depends: ${shlibs:Depends}/Depends: python-pika (>= 0.9.13)/' debian/control
        dpkg-buildpackage -d -us -uc
    popd
}

build_rpm $RPM_DIR
build_deb $DEB_DIR
