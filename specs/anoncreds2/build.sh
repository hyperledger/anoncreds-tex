#!/bin/bash

docker pull dxjoke/tectonic-docker
docker run --rm -v ${PWD}:/tex -w /tex dxjoke/tectonic-docker /bin/sh -c "tectonic anoncreds2.tex"
