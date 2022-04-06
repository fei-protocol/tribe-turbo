#!/usr/bin/env bash

# --------------------------------------------------------------------------------------------------
# Purpose: This script will grant turbo authority role 4 to a given address.
# Usage: sh devnetSetup.sh
# -- 
# TLDR: This script will impersonate the turbo timelock to grant a given address the turbo role 4. 
#       This will allow the given address to create safes.
#       Meant for development purposes. Run on a hardhat project.
# --------------------------------------------------------------------------------------------------

RPC_URL=http://127.0.0.1:8545/
TRIBE=0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B
TURBO_AUTHORITY=0x286c9724a0C1875233cf17A4ffE475A0BD8158dE
TURBO_TIMELOCK=0xfc083469EF154eb69FC0674cd6438530B6D92366
TIMELOCK=0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c
CORE=0x8d5ED43dCa8C2F7dFB20CF7b53CC7E593635d7b9
FEI=0x956f47f50a910163d8bf957cf5846d573e7f87ca
FFEI=0x081E7C60bCB8A2e7E43076a2988068c0a6e69e27
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

echo "${YELLOW}=======================================${NOCOLOR}"
echo "Please provide the address you want to use. If left empty a default address will be used."
read ADDRESS

if [ ${#ADDRESS} != 42 ]
then 
echo " ${YELLOW} The default address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 will be used. \n ${NOCOLOR}"
ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
fi

echo "${GREEN}1.${NOCOLOR} impersonating TribeDAO timelock"
curl -X POST --data '{"jsonrpc":"2.0","method":"hardhat_impersonateAccount","params":["0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c"],"id":67}' http://127.0.0.1:8545/
      
echo "\n\nseeding timelock"
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266\", \"to\": \"$TIMELOCK\", \"value\": \"0x56BC75E2D63100000\"}],\"id\":67}" http://127.0.0.1:8545/

echo "\n\n${GREEN}2.${NOCOLOR} allocating TRIBE to" $ADDRESS

ADDRESS_TRIBE_BALANCE=$(cast call $TRIBE "balanceOf(address)" $ADDRESS --rpc-url $RPC_URL)
BALANCE_DECODED=$(cast --abi-decode 'balanceOf(address) returns (uint256)' $ADDRESS_TRIBE_BALANCE)
echo "\nTRIBE balance before:" $BALANCE_DECODED

echo "\nsending tx"
ALLOCATE_DATA=$(cast calldata "allocateTribe(address,uint256)" 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$CORE\", \"data\": \"$ALLOCATE_DATA\"}],\"id\":67}" $RPC_URL

ADDRESS_TRIBE_BALANCE=$(cast call $TRIBE "balanceOf(address)" $ADDRESS --rpc-url $RPC_URL)
BALANCE_DECODED=$(cast --abi-decode 'balanceOf(address) returns (uint256)' $ADDRESS_TRIBE_BALANCE)
echo "\n\nTRIBE balance after:" $BALANCE_DECODED

echo "\n${GREEN}3.${NOCOLOR} seeding Tribe pool fei"
echo "\nminting fei"
MINT_DATA=$(cast calldata "mint(address,uint256)" $TIMELOCK 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FEI\", \"data\": \"$MINT_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo "\n\napproving fei"
APPROVE_DATA=$(cast calldata "approve(address,uint256)" $FFEI 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FEI\", \"data\": \"$APPROVE_DATA\"}],\"id\":67}" http://127.0.0.1:8545/

echo "\n\nseeding fFEI"
SEED_DATA=$(cast calldata "mint(uint256)" 10000000000000000000000000)
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TIMELOCK\", \"to\": \"$FFEI\", \"data\": \"$SEED_DATA\"}],\"id\":67}" http://127.0.0.1:8545/


echo "\n\n${GREEN}4.${NOCOLOR} checking if ${ADDRESS} has role 4"

CHECK_DATA=$(cast call $TURBO_AUTHORITY "doesUserHaveRole(address,uint8)" $ADDRESS 4 --rpc-url $RPC_URL)
DECODED_RESPONSE=$(cast --abi-decode 'doesUserHaveRole(address,uint8) returns (bool)' $CHECK_DATA)

if [ $DECODED_RESPONSE = false ] 
then 
echo "Response: ${RED} $DECODED_RESPONSE ${NOCOLOR}"

echo '\nImpersonating Turbo Timelock \a'
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hardhat_impersonateAccount\",\"params\":[\"$TURBO_TIMELOCK\"],\"id\":67}" $RPC_URL

echo "\n\nseeding Turbo Timelock"
curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266\", \"to\": \"$TURBO_TIMELOCK\", \"value\": \"0x56BC75E2D63100000\"}],\"id\":67}" http://127.0.0.1:8545/

echo "\n \nGranting role 4 to ${ADDRESS}, transaction sent using the turbo timelock."
AUTHORIZATION_DATA=$(cast calldata "setUserRole(address,uint8,bool)" $ADDRESS 4 true)

curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$TURBO_TIMELOCK\", \"to\": \"$TURBO_AUTHORITY\", \"data\": \"$AUTHORIZATION_DATA\"}],\"id\":67}" $RPC_URL

echo "\n \nChecking if $ADDRESS has role 4"

CHECK_DATA=$(cast call $TURBO_AUTHORITY "doesUserHaveRole(address,uint8)" $ADDRESS 4 --rpc-url  $RPC_URL)
DECODED_RESPONSE=$(cast --abi-decode 'doesUserHaveRole(address,uint8) returns (bool)' $CHECK_DATA)
fi 

if [ $DECODED_RESPONSE = false ] 
then
echo "Response: ${RED} $DECODED_RESPONSE"
echo "Run script again there was an error."
else
echo "Response: ${GREEN} $DECODED_RESPONSE"
echo "${GREEN}You now can use $ADDRESS to create safes"
fi

echo "${YELLOW}=======================================${NOCOLOR}"



