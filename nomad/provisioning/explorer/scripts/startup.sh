#!/bin/bash
# set -x

USER_HOME="/root"
MANTIS_DIST="mantis-dist"
PRIVATE_TESTNET="private-testnet"
MANTIS_LAUNCHER="./bin/mantis-launcher"
MANTIS_EXPLORER="mantis-explorer"

#cd ${USER_HOME}/${MANTIS_DIST} || exit
#${MANTIS_LAUNCHER} ${PRIVATE_TESTNET} "$@" &

cd ${USER_HOME} 
sleep 30
wget -O service "http://${CONSUL_HOST}:8500/v1/health/service/${CONSUL_SERVICE}?dc=dc1&stale=&wait=120000ms"
cat service
SERVICE_PROVIDER=http://$(cat service | grep Address | tail -n 1 | awk '{print $2}' | awk -F"\"" '{print $2}'):8546
echo $SERVICE_PROVIDER
cd ${USER_HOME}/${MANTIS_EXPLORER} || exit
WEB3_PROVIDER=$SERVICE_PROVIDER yarn start

