#!/bin/bash

basedir=`dirname "$0"`

. "$basedir"/commons.sh

oss="$1"
shift
distro="$1"
shift
version="$1"
shift
tarballname="$1"

if [ x"$PACKAGE_NAME" != "x" ]; then
	pkgname=$tarballname-$version-$PACKAGE_NAME-$distro
else
	pkgname=$tarballname-$version-$distro
fi
tmpdir=`mktemp -d`
destdir=$tmpdir/$pkgname
tarname=$pkgname.tar.gz
debDir='source/artifacts/debbuild'
mkdir -p "$tmpdir"
rsync -a ./*.deb "$destdir"/
cd "$destdir"
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
cd -
chmod +x install.sh
cp install.sh "$destdir"/
cd "$tmpdir"
tar czf "$tarname" "$pkgname"
cd -
mv "$tmpdir"/"$tarname" .
rm -rf "$tmpdir"
rm -rf ./*.deb
