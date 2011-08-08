#!/bin/sh

basedir=`dirname "$0"`

. "$basedir"/commons.sh
params="$@"

# Build rpms
pushd "$GIT_SOURCE_DIR"
if [ "$USE_WAF" == "True" ]; then
   ./waf rpm $params
   rpms="artifacts/rpmbuild/RPMS"
else
   true
fi
popd
    
# write down the path to rpm files to file
echo "$GIT_SOURCE_DIR"/"$rpms" > "$RESULT_DIR"