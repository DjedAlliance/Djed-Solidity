
#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi




forge create --legacy --rpc-url ${RPC_URL} \
    --constructor-args 10000000000000000000\
    --private-key ${PRIVATE_KEY} src/mock/MockOracle.sol:MockOracle