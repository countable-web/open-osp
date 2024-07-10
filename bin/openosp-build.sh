#!/bin/bash

# Builds all the docker images.

set -exo

COMPONENT=$1

if [[ $* == *--test* ]]; then
    export TEST_DURING_BUILD=1
    docker compose  up -d db # Need database to be up so it can run tests
elif [[ $* == *--dev* ]]; then
    export DEVELOPMENT_MODE=1
elif [[ $2 != *--* ]]; then
    WARFILE=$2
fi

case $COMPONENT in
    oscar)
        OSCAR_OUTPUT=docker/oscar

        # Using an existing warfile or compiling from scratch?
        if [ -z $WARFILE ]; then
            echo "Compiling OSCAR warfile. This may take some time...."
            docker compose  -f docker-compose.build.yml run --rm builder ./bin/build-oscar.sh
            mv $OSCAR_OUTPUT/oscar/target/oscar-*.war $OSCAR_OUTPUT/oscar.war
        else
            mkdir -p $OSCAR_OUTPUT
            cp $WARFILE $OSCAR_OUTPUT/oscar.war
        fi

        # Download drugref if we need it
        # For some reason this is only when not testing during build and not in development mode
        if [ -z $TEST_DURING_BUILD ] && [ -z $DEVELOPMENT_MODE ]; then
            echo "Retrieving current DrugRef2 binary"
            export DRUGREF_WAR=${DRUGREF_WAR:-"https://bitbucket.org/openoscar/drugref/downloads/drugref2.war"}
            docker run --rm -v $(pwd):/code/ alpine sh -c "apk add curl && cd /code/ && curl -Lo $OSCAR_OUTPUT/drugref2.war $DRUGREF_WAR"
        fi

        echo "Building Oscar Docker Image"
        docker compose  build oscar
        ;;
    expedius)
        echo "Building Expedius Docker Image"
        docker compose  build expedius
        ;;
    faxws)
        echo "Compiling FaxWS warfile"
        docker compose  -f docker-compose.build.yml run --rm builder ./bin/build-faxws.sh

        echo "Building FaxWs Docker Image"
        docker compose  build faxws
        ;;
esac
