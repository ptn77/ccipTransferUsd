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

Output to search for ccipReceive function:
forge test -vvv
[⠰] Compiling...
[⠰] Compiling 1 files with Solc 0.8.20
[⠔] Solc 0.8.20 finished in 8.16s
Compiler run successful!

Ran 3 tests for test/SendReceive.t.sol:SenderReceiverTest
[PASS] test_SendReceiveAverage() (gas: 206469)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120

[PASS] test_SendReceiveMax() (gas: 215804)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120

[PASS] test_SendReceiveMin() (gas: 196896)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120

Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 8.48ms (5.95ms CPU time)

Logs:
  source Fork Chain ID: 11155111
  source Fork Chain Selector: 16015286601757825753
  Deployed TransferUSDC.sol to source Fork:  0x2e234DAe75C793f67A35089C9d99245E1C58470b
  Deployed Sender.sol to source Fork:  0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
  Balance of link in sender contract address: 0x2e234DAe75C793f67A35089C9d99245E1C58470b 3000000000000000000
  Balance of link in this address: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 3000000000000000000
  Link address on source chain: 0x779877A7B0D9E8603169DdbD7836e478b4624789
  usdcToken address on source chain: 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
  Router address on source chain: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
  Balance of link on source chain TransferUSDC contract address: 0x2e234DAe75C793f67A35089C9d99245E1C58470b 6000000000000000000
  Select destination Fork Chain ID: 421614
  Bob balance before transfer:  0
  Deployed Receiver.sol to destination Fork:  0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9
  Set allowlistSourceChain on Receiver contract for source chain selector: 16015286601757825753
  Set allowlistSender on destination Receiver contract for Sender contract Address: 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
  Source Fork Chain ID: 11155111
  Balance of usdc token on source chain in this address: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 1000000000000000000
  Balance of usdc token on source chain in TransferUSDC contract address: 0x2e234DAe75C793f67A35089C9d99245E1C58470b 0

 │   │   │   ├─ [5053] Receiver::ccipReceive(Any2EVMMessage({ messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, data: 0x0000000000000000000000000000000000000000000000000000000000000064, destTokenAmounts: [] }))
    │   │   │   │   ├─ emit MessageReceived(messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], sender: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], iterationsInput: 100, iterationsDone: 0, result: 100)
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ emit MessageExecuted(messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], offRamp: 0x1c71f141b4630EBE52d6aF4894812960abE207eB, calldataHash: 0x36287bd18eeff683d6c6dd10bbfc2fe1fb74886908e3abbc2198a87d51ea4c82)
    │   │   │   └─ ← [Return] true, 0x, 5190**`
    │   │   └─ ← [Stop] 
    │   ├─ [0] VM::stopPrank()
    │   │   └─ ← [Return] 
    │   └─ ← [Stop] 
    ├─ [0] VM::activeFork() [staticcall]
    │   └─ ← [Return] 1
    ├─ [0] console::log("Destination Fork Chain ID:", 421614 [4.216e5]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::getRecordedLogs()
    │   └─ ← [Return] [([0x2fdca6724503823c2fdee314a2357f6789760842e990f94aa8dc21d16ac41ff7, 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, 0x000000000000000000000000000000000000000000000000de41ba4fc9d91ad9], 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064, 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9), ([0x9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6], 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3000000000000000000000000000000000000000000000000de41ba4fc9d91ad90000000000000000000000001c71f141b4630ebe52d6af4894812960abe207eb36287bd18eeff683d6c6dd10bbfc2fe1fb74886908e3abbc2198a87d51ea4c82, 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165)]
    ├─ [0] console::log("MessageExecuted hex string: ", "66fc433818f9956bf6b327ae2d0d8440581bfd18385f78515ffa527d3ce6c218") [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("2fdca6724503823c2fdee314a2357f6789760842e990f94aa8dc21d16ac41ff7") [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6") [staticcall]
    │   └─ ← [Stop] 
  