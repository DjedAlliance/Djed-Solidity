
#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi


forge create --legacy --rpc-url ${RPC_URL} \
    --constructor-args  ${ORACLE_ADDRESS} ${SCALING_FACTOR} ${TREASURY_ADDRESS} ${INITIAL_TREASURY_FEE} ${TREASURY_REVENUE_TARGET} ${RESERVE_RATIO_MIN} ${RESERVE_RATIO_MAX} ${FEE} ${THREASHOLD_SUPPLY_SC} ${RESERVE_COIN_MINIMUM_PRICE} ${RESERVE_COIN_INITIAL_PRICE} ${TX_LIMIT}\
    --private-key ${PRIVATE_KEY} src/Djed.sol:Djed
