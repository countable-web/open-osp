#!/bin/bash

set -uxo

if [ -f './local.env' ]; then
  source ./local.env
fi

./bin/clone.sh ${OSCAR_REPO:-""} ${OSCAR_TREEISH:-""}

cd docker/oscar/oscar

# increase java perm and gen memory for build
# other switches can be added here for debugging the build.
export MAVEN_OPTS="-Xms640m -Xmx960m -Xss512k -XX:NewRatio=4 -Djava.net.preferIPv4Stack=true"

# this repository should have passed unit testing and mvn verify 
# on the cis before being built here.
if [[ "${TEST_DURING_BUILD:-}" ]]; then
  mvn clean package
elif [[ "${DEVELOPMENT_MODE:-}" ]]; then
  mvn -T 1C install --offline
else
  mvn -Dcheckstyle.skip -Dmaven.test.skip=true clean package
fi

chmod 777 -R ./target/
