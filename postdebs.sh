#!/bin/bash
. `dirname $0`/commons.sh

debsDir=`cat $RESULT_DIR`
tgtfldr="$APTREPO":"$APTREPO_DEB_DIR"/"$SUB_DIR"
mntpoint="/media"
mount "$tgtfldr" "$mntpoint" -o nolock
repoDir="$mntpoint"/"$PUSH_TO_REPO"
mkdir -p "$repoDir"
cp -r "$debsDir"/oss "$repoDir"
cp -r "$debsDir"/premium "$repoDir"
umount "$mntpoint"