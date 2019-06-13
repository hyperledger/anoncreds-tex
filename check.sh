#!/bin/bash

GREEN="[0;32m"
NC="[0m"
ESCAPE="\033"

if [[ "$OSTYPE" == "darwin"* ]]; then
    FLAG="-E"
else
    FLAG="-r"
fi

FAIL=0

for f in $(find . -name main.tex | sed $FLAG 's|/[^/]+$||')
do
    echo -e "${ESCAPE}${GREEN}Checking $f/main.tex${ESCAPE}${NC}"
    docker run -v "$TRAVIS_BUILD_DIR/$f":/tex -w /tex dxjoke/tectonic-docker /bin/sh -c "tectonic main.tex"
    if [ $? -gt 0 ] ; then
        FAIL=1
    fi
done

exit $FAIL
