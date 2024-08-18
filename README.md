Day 3 Homework

TransferUSDC.sol contract does not send messages, only Token.
When the recipient is an EOA, the CCIP router contract on the destination chain handles the token transfer directly, as EOAs cannot implement the ccipReceive function. The router contract checks if the recipient is an EOA and, if so, transfers the tokens directly to the recipient's address.

Not sure why the HW is asking for the gas consumption of ccipReceive function since we were testing using an EOA as the recipient. Added the Send and Receive contracts with ExtraArgs gas_limit set to 500_000 to run the SendReceive.t.sol test for the gas usages intead, but the "MessageExecuted(bytes32, uint64, address, bytes32)" did not match the vm logs for some reason. Took the minimum gas usage of [PASS] test_SendReceiveMin() (gas: 186797)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120 instead. 
Still need to figure out how to get token contract of the USDC on Eth Sepolia and Arb Sepolia forks for testing TransferUSDC.

Token Pool Contract and ccipReceive (Is this correct for USDC tokens?)
In this process:

The token pool contract on the destination chain will typically have a ccipReceive function or an equivalent function that processes the message received via CCIP. This function handles the minting of new tokens on the destination chain based on the information passed from the source chain.
The ccipReceive function or its equivalent ensures that the cross-chain transfer is completed correctly and that the recipient receives the minted tokens.

Following the https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit guide measure the gas consumption of the ccipReceive function. Once you have the number, increase it by 10% and provide as gasLimit parameter of the transferUsdc function instead of the currently hard-coded 500.000 
