#!/bin/bash
set -x -e

BRANCH=master
REMOTE=https://github.com/mozilla/shove
SRC0=shove
RPM_DIR=$(pwd)/shove-rpm/
DEB_DIR=$(pwd)/shove-deb/
SHOVE_VERSION=0.1.5
SHOVE_TAG=v$SHOVE_VERSION
SHOVE_PKG_NAME=python-captain-shove

rm -rf $RPM_DIR
rm -rf $DEB_DIR
mkdir -p $RPM_DIR
mkdir -p $DEB_DIR
rm -rf $SRC0
git clone $REMOTE $SRC0
cd $SRC0
    git checkout $SHOVE_TAG
cd ../
# Need to rename this so that rpmbuilder will pick it up
mv $SRC0/README.rst $SRC0/README
sed s/README.rst/README/g $SRC0/setup.py > setup.py; mv setup.py $SRC0/

function build_rpm () {
    pushd $SRC0
        python setup.py bdist_rpm --source-only
        python setup.py bdist_rpm --spec-only --requires "python-pika >= 0.9.13" 
        rpmbuild -ba --define "_topdir ${PWD}/build/bdist.linux-x86_64/rpm" dist/$SHOVE_PKG_NAME.spec

        # TODO, don't hardcode the version
        cp build/bdist.linux-x86_64/rpm/RPMS/noarch/$SHOVE_PKG_NAME-$SHOVE_VERSION-1.noarch.rpm $1
    popd $SRC0
}

function build_deb () {
    pushd $1
        cp $RPM_DIR/$SHOVE_PKG_NAME-$SHOVE_VERSION-1.noarch.rpm .
        alien --generate $SHOVE_PKG_NAME-$SHOVE_VERSION-1.noarch.rpm
        cd $SHOVE_PKG_NAME-$SHOVE_VERSION/
        sed -i 's/Depends: ${shlibs:Depends}/Depends: python-pika (>= 0.9.13)/' debian/control
        dpkg-buildpackage -d -us -uc
    popd
}

build_rpm $RPM_DIR
build_deb $DEB_DIR
