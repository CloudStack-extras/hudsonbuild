#!/bin/sh

. `dirname $0`/commons.sh

rpmsDir=`cat $RESULT_DIR`
tgtfldr="$YUMREPO":"$YUMREPO_RPM_DIR"/"$SUB_DIR"
mntpoint="/media"
mount "$tgtfldr" "$mntpoint" -o nolock
repoDir="$mntpoint"/"$PUSH_TO_REPO"
mkdir -p "$repoDir"
cp -r "$rpmsDir"/oss "$repoDir"
createrepo -q -d --update "$repoDir"/oss
cp -r "$rpmsDir"/premium "$repoDir"
createrepo -q -d --update "$repoDir"/premium
umount "$mntpoint"