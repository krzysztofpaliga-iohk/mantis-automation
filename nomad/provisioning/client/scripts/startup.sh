#!/bin/bash
# set -x

USER_HOME="/root"
HOST="localhost"
RPC_PORT="8546"
MAIN_NET_BLOCK=155000
BUILD="build"
MANTIS="mantis"
DEFAULT="default"
RETESTETH="retesteth"
TESTS="tests"
CONF="conf"
KEY_STORE="keystore"
MANTIS_DIST="${MANTIS}-dist"
PRIVATE_TESTNET="private-testnet"
MANTIS_LAUNCHER="./bin/${MANTIS}-launcher"
MANTIS_BIN="./bin/${MANTIS}"
NODE_STORAGE_PATH="${USER_HOME}/${MANTIS}-testnet/${PRIVATE_TESTNET}"
NODE_KEY_FILE="${NODE_STORAGE_PATH}/node.key"
TEST_OUTPUT_FILE="${NODE_STORAGE_PATH}/test-iteration"
COINBASE_ADDRESS="0011223344556677889900112233445566778899"

HOST_IP=$(hostname -I | awk '{print $1}')

getBlockNumber() {
  curl -s http://${HOST}:${RPC_PORT} -H 'Content-Type: application/json' -d @<(
    cat <<EOF
        {
          "jsonrpc": "2.0",
          "method": "eth_blockNumber",
          "params": [],
          "id": 1
        }
EOF
  ) | jq -e -r .result | sed 's/^0x//'
}

hexToDec() {
  echo $((16#${1}))
}

cd ${USER_HOME}/${MANTIS_DIST} || exit

rm -rf ${NODE_KEY_FILE}
mkdir -p "${NODE_STORAGE_PATH}/${KEY_STORE}/"

if [ -n "${EC_PRIVATE_KEY}" ]; then
  echo "${EC_PRIVATE_KEY}" >>${NODE_KEY_FILE}
fi

if [ -n "${EC_PUBLIC_KEY}" ]; then
  echo "${EC_PUBLIC_KEY}" >>${NODE_KEY_FILE}
fi

if [ "$RUN_TEST_ITERATION" == false ]; then
  ${MANTIS_LAUNCHER} ${PRIVATE_TESTNET} -Dmantis.network.server-address.interface="${HOST_IP}" "$@"
else
  if [[ $TEST_TYPE == *"MANTIS-RPC"* ]]; then
    MANTIS_TEST_HOME="${USER_HOME}/.mantis-rpc-test/rpc-test-private"
    mkdir -p "${MANTIS_TEST_HOME}/${KEY_STORE}/"
    cp -Rf ${USER_HOME}/${MANTIS}/src/rpcTest/resources/privateNetConfig/${KEY_STORE}/* ${MANTIS_TEST_HOME}/${KEY_STORE}/
    cp -Rf ${USER_HOME}/${MANTIS}/src/rpcTest/resources/privateNetConfig/${CONF}/* ${USER_HOME}/${MANTIS_DIST}/${CONF}/

    echo "======================================="
    echo "=== Starting the RPC test iteration ==="
    echo "======================================="
    echo ""

    echo ""
    echo "=== Starting the MainNet RPC test iteration ==="
    cd ${USER_HOME}/${MANTIS_DIST} || exit
    ${MANTIS_LAUNCHER} etc -Dmantis.network.server-address.interface="${HOST}" -Dmantis.sync.do-fast-sync=false -Dmantis.network.discovery.discovery-enabled=true -Dmantis.network.discovery.host="${HOST}" -Dmantis.network.discovery.scan-interval=15.seconds -Dmantis.network.discovery.kademlia-bucket-size=16 -Dmantis.network.discovery.kademlia-alpha=16 -Dmantis.network.rpc.http.mode=http &
    sleep 30
    while ! nc -z ${HOST} ${RPC_PORT}; do
      echo ""
      echo "=== Waiting for the RPC port availability, :${RPC_PORT}"
      echo ""
      sleep 1
    done
    BLOCK_NUMBER_DEC=0
    while [ $BLOCK_NUMBER_DEC -le $MAIN_NET_BLOCK ]; do
      BLOCK_NUMBER_HEX=$(getBlockNumber)
      BLOCK_NUMBER_DEC=$(hexToDec "$BLOCK_NUMBER_HEX")
      echo ""
      echo "=== Waiting for the appropriate block syncing with the MainNet: ${BLOCK_NUMBER_DEC} (< ${MAIN_NET_BLOCK})"
      echo ""
      sleep 10
    done
    cd ${USER_HOME}/${MANTIS} || exit
    sbt "rpcTest:testOnly -- -n MainNet" >>${TEST_OUTPUT_FILE}-MainNet.log 2>&1
    killall -9 java
    echo ""
    echo "=== MainNet RPC test iteration has been completed ==="
    echo ""

    echo "=== Starting the PrivNet RPC test iteration ==="
    echo ""
    cd ${USER_HOME}/${MANTIS_DIST} || exit
    ${MANTIS_BIN} -Dmantis.network.server-address.interface="${HOST}" -Dmantis.consensus.mining-enabled=true &
    sleep 120
    cd ${USER_HOME}/${MANTIS} || exit
    sbt "rpcTest:testOnly -- -n PrivNet" >>${TEST_OUTPUT_FILE}-PrivNet.log 2>&1
    killall -9 java
    echo ""
    echo "=== PrivNet RPC test iteration has been completed ==="
    echo ""

    echo "=== Starting the PrivNetNoMining RPC test iteration ==="
    echo ""
    cd ${USER_HOME}/${MANTIS_DIST} || exit
    ${MANTIS_BIN} -Dmantis.network.server-address.interface="${HOST}" -Dmantis.consensus.mining-enabled=false &
    sleep 60
    cd ${USER_HOME}/${MANTIS} || exit
    sbt "rpcTest:testOnly -- -n PrivNetNoMining" >>${TEST_OUTPUT_FILE}-PrivNetNoMining.log 2>&1
    killall -9 java
    echo ""
    echo "=== PrivNetNoMining RPC test iteration has been completed ==="
    echo ""

    echo "============================================="
    echo "=== RPC test iteration has been completed ==="
    echo "============================================="
    echo ""
  fi

  if [[ $TEST_TYPE == *"RETEST-ETH"* ]]; then
    cd ${USER_HOME} || exit
    git clone https://github.com/ethereum/${TESTS}.git

    cd ${USER_HOME} || exit
    git clone https://github.com/ethereum/${RETESTETH}.git
    cd ${RETESTETH} || exit
    mkdir ${BUILD}
    cd ${BUILD} || exit
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j4
    cp ${RETESTETH}/${RETESTETH} /bin/${RETESTETH}

    cd ${USER_HOME} || exit
    git clone https://github.com/ethereum/solidity.git
    cd solidity || exit
    git checkout 8f2595957bfc0f3cd18ca29240dabcd6b2122dfd
    mkdir ${BUILD}
    cd ${BUILD} || exit
    cmake .. -DCMAKE_BUILD_TYPE=Release -DLLL=1
    make lllc -j4
    make solc -j4
    cp lllc/lllc /bin/lllc
    cp solc/solc /bin/solc

    echo "============================================="
    echo "=== Starting the RetestEth test iteration ==="
    echo "============================================="
    echo ""

    ${RETESTETH} -t GeneralStateTests/stExample -- --testpath ${USER_HOME}/${TESTS} --datadir ${USER_HOME}/.${RETESTETH} >>${TEST_OUTPUT_FILE}-stExample.log 2>&1
    mkdir -p ${USER_HOME}/.${RETESTETH}/${MANTIS}
    cp -Rf ${USER_HOME}/.${RETESTETH}/${DEFAULT}/ ${USER_HOME}/.${RETESTETH}/${MANTIS}/
    cp -Rf ${USER_HOME}/${MANTIS_DIST}/${CONF}/config ${USER_HOME}/.${RETESTETH}/${MANTIS}/
    cp -Rf ${USER_HOME}/${MANTIS_DIST}/${CONF}/config ${USER_HOME}/.${RETESTETH}/${MANTIS}/${DEFAULT}
    rm -rf ${USER_HOME}/.${RETESTETH}/${MANTIS}/${DEFAULT}/*.sh
    sleep 20

    cd ${USER_HOME}/${MANTIS_DIST} || exit
    ${MANTIS_LAUNCHER} ${PRIVATE_TESTNET} -Dmantis.consensus.coinbase="${COINBASE_ADDRESS}" -Dmantis.network.server-address.interface="${HOST}" -Dmantis.consensus.mining-enabled=true -Dmantis.consensus.protocol=mocked &
    sleep 120
    # https://github.com/ethereum/tests
    cd ${USER_HOME} || exit
    ${RETESTETH} -t BlockchainTests -- --datadir ${USER_HOME}/.${RETESTETH} --clients ${MANTIS} --testpath ${USER_HOME}/${TESTS} --all >>${TEST_OUTPUT_FILE}-BlockchainTests.log 2>&1
    sleep 30
    ${RETESTETH} -t GeneralStateTests -- --datadir ${USER_HOME}/.${RETESTETH} --clients ${MANTIS} --testpath ${USER_HOME}/${TESTS} --all >>${TEST_OUTPUT_FILE}-GeneralStateTests.log 2>&1
    killall -9 java

    echo "==================================================="
    echo "=== RetestEth test iteration has been completed ==="
    echo "==================================================="
    echo ""
  fi
fi
