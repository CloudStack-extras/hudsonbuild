#!/bin/bash

basedir=`dirname "$0"`

. "$basedir"/commons.sh

params="$@"

# Build debs
cd "$GIT_SOURCE_DIR"
if [ "$USE_WAF" == "True" ]; then
    mvn build-helper:remove-project-artifact
    mvn install  -P deps
    dpkg-buildpackage
    debs="artifacts/debbuild/"
else
    true
fi
cd -
    
# write down the path to deb files to file
echo "$GIT_SOURCE_DIR"/"$debs" > "$RESULT_DIR"
