#!/bin/bash

docker pull dxjoke/tectonic-docker
docker run --rm -v ${PWD}:/tex -w /tex dxjoke/tectonic-docker /bin/sh -c "biber anoncredsmain"
docker run --rm -v ${PWD}:/tex -w /tex dxjoke/tectonic-docker /bin/sh -c "tectonic anoncredsmain.tex"
mv anoncredsmain.pdf anoncreds1.pdf
