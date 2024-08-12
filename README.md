Day 3 Homework

TransferUSDC.sol contract does not send messages, only Token.
When the recipient is an EOA, the CCIP router contract on the destination chain handles the token transfer directly, as EOAs cannot implement the ccipReceive function. The router contract checks if the recipient is an EOA and, if so, transfers the tokens directly to the recipient's address.

Not sure why the HW is asking for the gas consumption of ccipReceive function since we were testing using an EOA as the recipient. Added the Send and Receive contracts to run the SendReceive.t.sol test for the gas usages intead, but the "MessageExecuted(bytes32, uint64, address, bytes32)" did not match the vm logs for some reason. Took the minimum gas usage of [PASS] test_SendReceiveMin() (gas: 85779) instead. 

Following the https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit guide measure the gas consumption of the ccipReceive function. Once you have the number, increase it by 10% and provide as gasLimit parameter of the transferUsdc function instead of the currently hard-coded 500.000 
