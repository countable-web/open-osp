#!/bin/bash

# Builds all the docker images.

set -exo

COMMAND=$1
if [[ $2 != *--* ]]
then
  WARFILE=$2
fi

case "${COMMAND}" in
    oscar)
        OSCAR_OUTPUT=docker/oscar
        if [[ "$*" == *--test* ]]
        then
            docker-compose up -d db
        fi

        if [ -z "$WARFILE" ]
        then
            echo "Compiling OSCAR. This may take some time...."
            docker-compose -f docker-compose.build.yml run builder ./bin/build-oscar.sh
            mv $OSCAR_OUTPUT/oscar/target/oscar-*-SNAPSHOT.war $OSCAR_OUTPUT/oscar.war
        else
            mkdir -p $OSCAR_OUTPUT
            cp $WARFILE $OSCAR_OUTPUT/oscar.war
        fi

        # download most current binary release of DrugRef2 from the Open OSP repository.
        # current version released December 30, 2021
        export DRUGREF_WAR=${DRUGREF_WAR:-"https://api.bitbucket.org/2.0/repositories/openoscar/drugref/downloads/drugref2.war"}

        # Download drugref if we need it.
        if [ ! -f $OSCAR_OUTPUT/drugref2.war ]; then
          echo "Retrieving current DrugRef2 binary"
          docker run -v $(pwd):/code/ alpine sh -c "cd /code/ && curl -o $OSCAR_OUTPUT/drugref2.war $DRUGREF_WAR"
        fi

        echo "Building Oscar Docker Image"
        if [[ "$*" == *--test* ]]
        then
            export TEST_DURING_BUILD=1
        elif [[ "$*" == *--dev* ]]
        then
            export DEVELOPMENT_MODE=1
        fi
        docker-compose build oscar
        ;;
    expedius)

        ;;
    faxws)
        echo "Compiling FaxWS"
        docker-compose -f docker-compose.build.yml run builder ./bin/build-faxws.sh

        echo "Building FaxWs Docker Image"
        docker-compose build faxws
        ;;
esac


