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

if [ x"$PACKAGE_NAME" != "x" ]; then
        pkgname=$tarballname-$version-$PACKAGE_NAME-$distro
else
        pkgname=$tarballname-$version-$distro
fi

tmpdir=`mktemp -d`
destdir=$tmpdir/$pkgname
tarname=$pkgname.tar.gz
rpmDir=`cat $RESULT_DIR`

mkdir -p "$tmpdir"
rsync -a "$rpmDir" "$destdir"/
createrepo -q -d "$destdir"
chmod +x install.sh
cp install.sh "$destdir"/
pushd "$tmpdir"
tar czf "$tarname" "$pkgname"
popd
mv "$tmpdir"/"$tarname" .
rm -rf "$tmpdir"
