#!/bin/sh

basedir=`dirname "$0"`

. "$basedir"/commons.sh

oss="$1"
shift
distro="$1"
shift
version="$1"
shift
tarballname="$1"
shift
s3repo="$1"

pkgname=$tarballname-$version-$distro
tmpdir=`mktemp -d`
destdir=$tmpdir/$pkgname
tarname=$pkgname.tar.gz
rpmDir=`cat $RESULT_DIR`

mkdir -p "$tmpdir"
rsync -a "$rpmDir"/oss "$destdir"/
if [ "$oss" != "True" ]; then
	rsync -a "$rpmDir"/premium "$destdir"/
fi
rsync -a "$DEPS_DIR" "$destdir"/
createrepo -q -d "$destdir"
chmod +x install.sh
cp install.sh "$destdir"/
pushd "$tmpdir"
tar czf "$tarname" "$pkgname"
popd
mv "$tmpdir"/"$tarname" .
rm -rf "$tmpdir"

tgtfldr="$YUMREPO":"$YUMREPO_RELEASE_DIR"/"$SUB_DIR"
mntpoint="/media"
mount "$tgtfldr" "$mntpoint" -o nolock
mkdir -p "$mntpoint"/"$PUSH_TO_REPO"
if [ x"$s3repo" != x"" ]; then
	s3cmd put --acl-public "$tarname" "$s3repo"
fi
mv "$tarname" "$mntpoint"/"$PUSH_TO_REPO"/
umount "$mntpoint"
