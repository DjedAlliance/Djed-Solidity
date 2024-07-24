
#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi


forge create --legacy --rpc-url ${RPC_URL} \
    --constructor-args  ${DATA_FEED_ADDRESS} ${DJED_DECIMALS} ${HEBESWAP_DECIMALS} ${BASE_TOKEN} ${QUOTE_TOKEN} \
    --private-key ${PRIVATE_KEY} src/HebeSwapInvertingOracle.sol:HebeSwapInvertingOracle
