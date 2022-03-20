#!/usr/bin/env bash

RPC_URL=http://127.0.0.1:8545/
PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADMIN=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
ZERO=0x0000000000000000000000000000000000000000
FEI=0x956F47F50A910163D8BF957Cf5846D573E7f87CA
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

COMPTROLLER=0x1d9EEE473CC1B3b6D316740F5677Ef36E8f0329e

CONFIGURER=$(forge create Configurer --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

TIMELOCK=$(forge create TimelockController --constructor-args 0 [] [] --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

pushd lib/solmate

AUTHORITY=$(forge create MultiRolesAuthority --constructor-args $CONFIGURER $ZERO --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')
DEFAULT_AUTHORITY=$(forge create MultiRolesAuthority --constructor-args $CONFIGURER $ZERO --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

popd

cast send $CONFIGURER "configureDefaultAuthority(address)" $DEFAULT_AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Grant admin to the configurer
cast send $COMPTROLLER "_setPendingAdmin(address)" $CONFIGURER --rpc-url $RPC_URL --private-key $ETH_PRIVATE_KEY

TURBO_ADMIN=$(forge create TurboAdmin --constructor-args $COMPTROLLER $TIMELOCK $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

cast send $CONFIGURER "configureAdmin(address,address,address)" $AUTHORITY $COMPTROLLER $TURBO_ADMIN --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $TIMELOCK "grantRole(bytes32,address)" 0x5f58e3a2316349923ce3780f8d587db2d72378aed66a8261c916544fa6846ca5 $CONFIGURER --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $CONFIGURER "configureTimelock(address,address)" $TIMELOCK $TURBO_ADMIN --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $CONFIGURER "configureAuthority(address)" $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY

MASTER=$(forge create TurboMaster --constructor-args $COMPTROLLER $FEI $TIMELOCK $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

CLERK=$(forge create TurboClerk --constructor-args $TIMELOCK $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')
BOOSTER=$(forge create TurboBooster --constructor-args $TIMELOCK $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')
cast send $CONFIGURER "configureMaster(address,address,address,address,address)" $MASTER $CLERK $BOOSTER $TURBO_ADMIN $DEFAULT_AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY

LENS=$(forge create TurboLens --constructor-args $MASTER --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

cast send $CONFIGURER "configurePool(address,address)" $TURBO_ADMIN $BOOSTER --rpc-url $RPC_URL --private-key $PRIVATE_KEY

GIBBER=$(forge create TurboGibber --constructor-args $MASTER $TIMELOCK $ZERO --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')
SAVIOR=$(forge create TurboSavior --constructor-args $MASTER $TIMELOCK $AUTHORITY --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')
ROUTER=$(forge create TurboRouter --constructor-args $MASTER $TIMELOCK $ZERO $WETH --rpc-url $RPC_URL --private-key $PRIVATE_KEY | grep 'Deployed to:' | awk '{print $NF}')

cast send $CONFIGURER "configureRoles(address,address,address,address,address)" $AUTHORITY $DEFAULT_AUTHORITY $ROUTER $SAVIOR $GIBBER --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $CONFIGURER "configureClerk(address)" $CLERK --rpc-url $RPC_URL --private-key $PRIVATE_KEY
cast send $CONFIGURER "configureSavior(address)" $SAVIOR --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $CONFIGURER "resetOwnership(address,address,address,address)" $DEFAULT_AUTHORITY $AUTHORITY $TIMELOCK $ADMIN --rpc-url $RPC_URL --private-key $PRIVATE_KEY

echo "TIMELOCK=$TIMELOCK"
echo "AUTHORITY=$AUTHORITY"
echo "DEFAULT_AUTHORITY=$DEFAULT_AUTHORITY"
echo "CONFIGURER=$CONFIGURER"
echo "TURBO_ADMIN=$TURBO_ADMIN"
echo "MASTER=$MASTER"
echo "CLERK=$CLERK"
echo "BOOSTER=$BOOSTER"
echo "LENS=$LENS"
echo "GIBBER=$GIBBER"
echo "SAVIOR=$SAVIOR"
echo "ROUTER=$ROUTER"

## Cleanup items
# Increase timelock timer to a large value
# Remove turbo admin role from admin
# revoke admin role from timelock controller