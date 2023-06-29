
#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi


forge create --legacy --rpc-url ${RPC_URL} \
    --constructor-args  ${PROXY_ADDRESS} ${API3_DECIMALS} ${DJED_DECIMALS} \
    --private-key ${PRIVATE_KEY} src/API3InvertingOracle.sol:API3InvertingOracle
