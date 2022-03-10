#!/usr/bin/env bash

DEPLOYER=$(forge create Deployer --rpc-url http://127.0.0.1:8545/ --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 | grep 'Deployed to:' | awk '{print $NF}'
0x5302e909d1e93e30f05b5d6eea766363d14f9892)

MASTER=$(cast call $DEPLOYER "master()(address)" --rpc-url  http://127.0.0.1:8545/)

ROUTER=$(cast call $DEPLOYER "router()(address)" --rpc-url  http://127.0.0.1:8545/)
LENS=$(cast call $DEPLOYER "lens()(address)" --rpc-url  http://127.0.0.1:8545/)

STRATEGY=$(cast call $DEPLOYER "strategy()(address)" --rpc-url  http://127.0.0.1:8545/)

echo "master=$MASTER router=$ROUTER lens=$LENS strategy=$STRATEGY"

BOOSTER=$(cast call $MASTER "booster()(address)" --rpc-url  http://127.0.0.1:8545/)
CLERK=$(cast call $MASTER "clerk()(address)" --rpc-url  http://127.0.0.1:8545/)
COMPTROLLER=$(cast call $MASTER "pool()(address)" --rpc-url  http://127.0.0.1:8545/)
FEI=$(cast call $MASTER "fei()(address)" --rpc-url  http://127.0.0.1:8545/)

echo "booster=$BOOSTER clerk=$CLERK comptroller=$COMPTROLLER"

FFEI=$(cast call $COMPTROLLER "cTokensByUnderlying(address)(address)" $FEI --rpc-url  http://127.0.0.1:8545/)
TIMELOCK=0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c
CORE=0x8d5ED43dCa8C2F7dFB20CF7b53CC7E593635d7b9

echo "impersonating timelock"
curl -X POST --data '{"jsonrpc":"2.0","method":"hardhat_impersonateAccount","params":["0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c"],"id":67}' http://127.0.0.1:8545/
        
echo "seeding timelock"

curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266\", \"to\": \"$TIMELOCK\", \"value\": \"0x56BC75E2D63100000\"}],\"id\":67}" http://127.0.0.1:8545/

echo "minting fei"
MINT_DATA=$(cast calldata "mint(address,uint256)" $TIMELOCK 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FEI\", \"data\": \"$MINT_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo "approving fei"
APPROVE_DATA=$(cast calldata "approve(address,uint256)" $FFEI 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FEI\", \"data\": \"$APPROVE_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo "seeding fFEI"
SEED_DATA=$(cast calldata "mint(uint256)" 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FFEI\", \"data\": \"$SEED_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo "allocate TRIBE"
ALLOCATE_DATA=$(cast calldata "allocateTribe(address,uint256)" 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$CORE\", \"data\": \"$ALLOCATE_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo ""
echo "DONE seeding pool and account 0"