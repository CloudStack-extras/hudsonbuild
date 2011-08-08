# Checkout $GIT_SOURCE_DIR from git

. `dirname $0`/commons.sh

echo "Checking out and cleaning the $GIT_SOURCE_DIR"
if [ "$BUILDABLE_TARGET" == "" ] ; then
	errExit "BUILDABLE_TARGET is empty"
fi

# BEGIN CODE CHECKOUT

if [ -d $GIT_SOURCE_DIR ] ; then
  	pushd $GIT_SOURCE_DIR
    git fetch --all -t
    git pull --tags || true
    git reset --hard
    git clean -fxd
    if git rev-parse origin/$BUILDABLE_TARGET ; then osscommitid=`git checkout origin/$BUILDABLE_TARGET &>commit.log;cat commit.log; rm -f commit.log`
    else osscommitid=`git checkout $BUILDABLE_TARGET &>commit.log;cat commit.log; rm -f commit.log` ; fi
  	popd
else
  git clone ssh://hudson@git.cloud.com/var/lib/git/cloudstack-oss $GIT_SOURCE_DIR
  #git clone https://github.com/CloudDotCom/CloudStack.git "$$GIT_SOURCE_DIR"
fi

pushd $GIT_SOURCE_DIR
  if [ -d cloudstack-proprietary ] ; then
   pushd cloudstack-proprietary
    git fetch --all -t
    git pull --tags || true
    git reset --hard
    git clean -fxd
    if git rev-parse origin/$BUILDABLE_TARGET ; then premiumcommitid=`git checkout origin/$BUILDABLE_TARGET &>commit.log;cat commit.log; rm -f commit.log`
    else premiumcommitid=`git checkout $BUILDABLE_TARGET &>commit.log;cat commit.log; rm -f commit.log` ; fi
   popd
  else
    git clone ssh://hudson@git.lab.vmops.com/var/lib/git/cloudstack-proprietary
  fi
popd

# END CODE CHECKOUT

echo Build description: "$BUILD_USER; $BUILDABLE_TARGET -> $osscommitid / $premiumcommitid -> $DO_DISTRO_PACKAGES -> $PUSH_TO_REPO | Checkout: $BUILDABLE_TARGET -- resulting commit IDs: $osscommitid and $premiumcommitid -- distro packages: $DO_DISTRO_PACKAGES -- upload to repository: $PUSH_TO_REPO -- prerelease labels: $LABEL_AS_PRERELEASE"

exit 0