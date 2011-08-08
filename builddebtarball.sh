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

pkgname=$tarballname-$version-$distro
tmpdir=`mktemp -d`
destdir=$tmpdir/$pkgname
tarname=$pkgname.tar.gz
debDir=`cat $RESULT_DIR`
mkdir -p "$tmpdir"
rsync -a "$debDir"/oss "$destdir"/
if [ "$oss" != "True" ]; then
    rsync -a "$debDir"/premium "$destdir"/
fi
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
umount "$mntpoint"



