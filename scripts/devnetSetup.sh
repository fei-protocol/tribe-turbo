#!/usr/bin/env bash

# --------------------------------------------------------------------------------------------------
# Purpose: This script will grant turbo authority role 4 to a given address.
# Usage: sh devnetSetup.sh
# -- 
# TLDR: This script will impersonate the turbo timelock to grant a given address the turbo role 4. 
#       This will allow the given address to create safes.
#       Meant for development purposes.
# --------------------------------------------------------------------------------------------------

RPC_URL=http://127.0.0.1:8545/
TURBO_AUTHORITY=0x286c9724a0C1875233cf17A4ffE475A0BD8158dE
TURBO_TIMELOCK=0xfc083469EF154eb69FC0674cd6438530B6D92366
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

echo "${YELLOW}=======================================${NOCOLOR}"
echo "Please provide the address you want to use. If left empty a default address will be used."
read ADDRESS

if [ ${#ADDRESS} != 42 ]
then 
echo "The default address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 will be used. \n"
ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
fi

echo "Checking if ${ADDRESS} has role 4"

CHECK_DATA=$(cast call $TURBO_AUTHORITY "doesUserHaveRole(address,uint8)" $ADDRESS 4 --rpc-url $RPC_URL)
DECODED_RESPONSE=$(cast --abi-decode 'doesUserHaveRole(address,uint8) returns (bool)' $CHECK_DATA)

if [ $DECODED_RESPONSE = false ] 
then 
echo "Response: ${RED} $DECODED_RESPONSE ${NOCOLOR}"

echo '\nImpersonating Turbo Timelock \a'

curl -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hardhat_impersonateAccount\",\"params\":[\"$TURBO_TIMELOCK\"],\"id\":67}" $RPC_URL

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



