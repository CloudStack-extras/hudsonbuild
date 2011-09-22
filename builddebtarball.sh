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
debDir=`cat $RESULT_DIR`
mkdir -p "$tmpdir"
rsync -a "$debDir"/oss "$destdir"/
if [ "$oss" != "True" && x"$NO_PROPIRETARY" != x"true" ]; then
    rsync -a "$debDir"/premium "$destdir"/
fi
rsync -a "$DEPS_DIR" "$destdir"/
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

tgtfldr="$APTREPO":"$APTREPO_RELEASE_DIR"/"$SUB_DIR"
mntpoint="/media"
mount "$tgtfldr" "$mntpoint" -o nolock
mkdir -p "$mntpoint"/"$PUSH_TO_REPO"
mv "$tarname" "$mntpoint"/"$PUSH_TO_REPO"/
echo "Tarball URL:http://aptrepo.lab.vmops.com/releases/$SUB_DIR/$PUSH_TO_REPO/$tarname"
umount "$mntpoint"



