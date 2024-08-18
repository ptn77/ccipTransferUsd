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

Ran 1 test for test/TransferUSDC.t.sol:TransferUSDCTest
[FAIL. Reason: revert: ERC20: insufficient allowance] test_SendReceive1USDC() (gas: 730585)
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
  Error: a == b not satisfied [uint]
        Left: 0
       Right: 100
  Sending message to ccipReceive through Sender contract to estimate gas...
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  Destination Fork Chain ID: 421614
  MessageExecuted hex string:  66fc433818f9956bf6b327ae2d0d8440581bfd18385f78515ffa527d3ce6c218
  2fdca6724503823c2fdee314a2357f6789760842e990f94aa8dc21d16ac41ff7
  9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6
  Gas used for ccipReceive:  398601
  Gas used for ccipReceive:  398601
  source Fork Chain ID: 11155111
  Adjusted Gas Limit: 438461
  tokens to send details amount: 100
  0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd
  source Fork Chain ID: 11155111

Traces:
  [730585] TransferUSDCTest::test_SendReceive1USDC()
    ├─ [0] VM::selectFork(0)
    │   └─ ← [Return] 
    ├─ [0] VM::activeFork() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("Source Fork Chain ID:", 11155111 [1.115e7]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::startPrank(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496])
    │   └─ ← [Return] 
    ├─ [29513] 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05::drip(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496])
    │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], value: 1000000000000000000 [1e18])
    │   └─ ← [Stop] 
    ├─ [627] 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05::balanceOf(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 1000000000000000000 [1e18]
    ├─ [0] console::log("Balance of usdc token on source chain in this address:", TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 1000000000000000000 [1e18]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [2627] 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05::balanceOf(TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("Balance of usdc token on source chain in TransferUSDC contract address:", TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0) [staticcall]
    │   └─ ← [Stop] 
    ├─ [2756] 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05::allowance(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   └─ ← [Return] 0
    ├─ emit log(val: "Error: a == b not satisfied [uint]")
    ├─ emit log_named_uint(key: "      Left", val: 0)
    ├─ emit log_named_uint(key: "     Right", val: 100)
    ├─ [0] VM::store(VM: [0x7109709ECfa91a80626fF3989D68f67F5b1DD12D], 0x6661696c65640000000000000000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000000000000000000000000001)
    │   └─ ← [Return] 
    ├─ [0] console::log("Sending message to ccipReceive through Sender contract to estimate gas...") [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::recordLogs()
    │   └─ ← [Return] 
    ├─ [59911] → new EncodeExtraArgs@0xc7183455a4C133Ae270771860664b6B7ec320bB1
    │   └─ ← [Return] 299 bytes of code
    ├─ [729] EncodeExtraArgs::encode(500000 [5e5]) [staticcall]
    │   └─ ← [Return] 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
    ├─ [0] console::log(0x97a657c9000000000000000000000000000000000000000000000000000000000007a120) [staticcall]
    │   └─ ← [Stop] 
    ├─ [171419] Sender::sendMessagePayLINK(3478487238524512106 [3.478e18], Receiver: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 100, 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120)
    │   ├─ [28126] 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59::getFee(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9, data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120 })) [staticcall]
    │   │   ├─ [19426] 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e::getFee(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9, data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120 })) [staticcall]
    │   │   │   ├─ [5528] 0x9EF7D57a4ea30b9e37794E55b0C75F2A70275dCc::getTokenAndGasPrices(0x779877A7B0D9E8603169DdbD7836e478b4624789, 3478487238524512106 [3.478e18]) [staticcall]
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000008ee789a88bddac000000000000000000000000000000000000000000000000000000005d13722048
    │   │   │   └─ ← [Return] 47002373895621225 [4.7e16]
    │   │   └─ ← [Return] 47002373895621225 [4.7e16]
    │   ├─ [27931] 0x779877A7B0D9E8603169DdbD7836e478b4624789::transferFrom(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 47002373895621225 [4.7e16])
    │   │   ├─ emit Transfer(from: TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], to: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 47002373895621225 [4.7e16])
    │   │   ├─ emit Approval(owner: TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 764112083593632 [7.641e14])
    │   │   └─ ← [Return] true
    │   ├─ [24589] 0x779877A7B0D9E8603169DdbD7836e478b4624789::approve(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, 47002373895621225 [4.7e16])
    │   │   ├─ emit Approval(owner: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], spender: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, value: 47002373895621225 [4.7e16])
    │   │   └─ ← [Return] true
    │   ├─ [78301] 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59::ccipSend(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9, data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120 }))
    │   │   ├─ [7457] 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991::isCursed() [staticcall]
    │   │   │   ├─ [2395] 0x27Da8735d8d1402cEc072C234759fbbB4dABBC4A::isCursed()
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   ├─ [6926] 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e::getFee(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9, data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120 })) [staticcall]
    │   │   │   ├─ [1528] 0x9EF7D57a4ea30b9e37794E55b0C75F2A70275dCc::getTokenAndGasPrices(0x779877A7B0D9E8603169DdbD7836e478b4624789, 3478487238524512106 [3.478e18]) [staticcall]
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000008ee789a88bddac000000000000000000000000000000000000000000000000000000005d13722048
    │   │   │   └─ ← [Return] 47002373895621225 [4.7e16]
    │   │   ├─ [10831] 0x779877A7B0D9E8603169DdbD7836e478b4624789::transferFrom(Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e, 47002373895621225 [4.7e16])
    │   │   │   ├─ emit Transfer(from: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], to: 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e, value: 47002373895621225 [4.7e16])
    │   │   │   ├─ emit Approval(owner: Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], spender: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, value: 0)
    │   │   │   └─ ← [Return] true
    │   │   ├─ [42825] 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e::forwardFromRouter(3478487238524512106 [3.478e18], (0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9, 0x0000000000000000000000000000000000000000000000000000000000000064, [], 0x779877A7B0D9E8603169DdbD7836e478b4624789, 0x97a657c9000000000000000000000000000000000000000000000000000000000007a120), 47002373895621225 [4.7e16], Sender: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a])
    │   │   │   ├─ [957] 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991::isCursed() [staticcall]
    │   │   │   │   ├─ [395] 0x27Da8735d8d1402cEc072C234759fbbB4dABBC4A::isCursed()
    │   │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   │   ├─ emit CCIPSendRequested(message: EVM2EVMMessage({ sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, receiver: 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9, sequenceNumber: 196314 [1.963e5], gasLimit: 500000 [5e5], strict: false, nonce: 1, feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, feeTokenAmount: 47002373895621225 [4.7e16], data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], sourceTokenData: [], messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3 }))
    │   │   │   └─ ← [Return] 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3
    │   │   └─ ← [Return] 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3
    │   ├─ emit MessageSent(messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, destinationChainSelector: 3478487238524512106 [3.478e18], receiver: Receiver: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], iterations: 100, feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, fees: 47002373895621225 [4.7e16])
    │   └─ ← [Return] 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3
    ├─ [111137] CCIPLocalSimulatorFork::switchChainAndRouteMessage(1)
    │   ├─ [0] VM::getRecordedLogs()
    │   │   └─ ← [Return] [([0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a], 0x00000000000000000000000000000000000000000000000000a6fc68f7a60a69, 0x779877A7B0D9E8603169DdbD7836e478b4624789), ([0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, 0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a], 0x0000000000000000000000000000000000000000000000000002b6f4b54fa9a0, 0x779877A7B0D9E8603169DdbD7836e478b4624789), ([0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 0x0000000000000000000000000bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59], 0x00000000000000000000000000000000000000000000000000a6fc68f7a60a69, 0x779877A7B0D9E8603169DdbD7836e478b4624789), ([0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 0x000000000000000000000000e4dd3b16e09c016402585a8adfdb4a18f772a07e], 0x00000000000000000000000000000000000000000000000000a6fc68f7a60a69, 0x779877A7B0D9E8603169DdbD7836e478b4624789), ([0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, 0x0000000000000000000000000bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59], 0x0000000000000000000000000000000000000000000000000000000000000000, 0x779877A7B0D9E8603169DdbD7836e478b4624789), ([0xd0c3c799bf9e2639de44391e7f524d229b2b55f5b1ea94b2bf7da42f7243dddd], 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000de41ba4fc9d91ad9000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a9000000000000000000000000000000000000000000000000000000000002feda000000000000000000000000000000000000000000000000000000000007a12000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000779877a7b0d9e8603169ddbd7836e478b462478900000000000000000000000000000000000000000000000000a6fc68f7a60a6900000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002006a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf30000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000, 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e), ([0xeea8a479f07983d1364c4330c9bf3442a1cd421b79b16909bcc1867188ea676b, 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, 0x000000000000000000000000000000000000000000000000304611b6affba76a], 0x0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a90000000000000000000000000000000000000000000000000000000000000064000000000000000000000000779877a7b0d9e8603169ddbd7836e478b462478900000000000000000000000000000000000000000000000000a6fc68f7a60a69, 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a)]
    │   ├─ [0] VM::selectFork(1)
    │   │   └─ ← [Return] 
    │   ├─ [0] VM::activeFork() [staticcall]
    │   │   └─ ← [Return] 1
    │   ├─ [1435] Register::getNetworkDetails(421614 [4.216e5]) [staticcall]
    │   │   └─ ← [Return] NetworkDetails({ chainSelector: 3478487238524512106 [3.478e18], routerAddress: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165, linkAddress: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E, wrappedNativeAddress: 0xE591bf0A0CF924A0674d7792db046B23CEbF5f34, ccipBnMAddress: 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D, ccipLnMAddress: 0x139E99f0ab4084E14e6bb7DacA289a91a2d92927 })
    │   ├─ [19216] 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165::getOffRamps() [staticcall]
    │   │   └─ ← [Return] [OffRamp({ sourceChainSelector: 9284632837123596123 [9.284e18], offRamp: 0x262e16C8D42aa07bE13e58F81e7D9F62F6DE2830 }), OffRamp({ sourceChainSelector: 16015286601757825753 [1.601e19], offRamp: 0x1c71f141b4630EBE52d6aF4894812960abE207eB }), OffRamp({ sourceChainSelector: 8871595565390010547 [8.871e18], offRamp: 0x935C26F9a9122E5F9a27f2d3803e74c75B94f5a3 }), OffRamp({ sourceChainSelector: 14767482510784806043 [1.476e19], offRamp: 0xcab0EF91Bee323d1A617c0a027eE753aFd6997E4 }), OffRamp({ sourceChainSelector: 5224473277236331295 [5.224e18], offRamp: 0xfD404A89e1d195F0c65be1A9042C77745197659e }), OffRamp({ sourceChainSelector: 10344971235874465080 [1.034e19], offRamp: 0xc1982985720B959E66c19b64F783361Eb9B60F26 })]
    │   ├─ [0] VM::startPrank(0x1c71f141b4630EBE52d6aF4894812960abE207eB)
    │   │   └─ ← [Return] 
    │   ├─ [36231] 0x1c71f141b4630EBE52d6aF4894812960abE207eB::executeSingleMessage(EVM2EVMMessage({ sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, receiver: 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9, sequenceNumber: 196314 [1.963e5], gasLimit: 500000 [5e5], strict: false, nonce: 1, feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, feeTokenAmount: 47002373895621225 [4.7e16], data: 0x0000000000000000000000000000000000000000000000000000000000000064, tokenAmounts: [], sourceTokenData: [], messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3 }), [])
    │   │   ├─ [427] Receiver::supportsInterface(0x01ffc9a700000000000000000000000000000000000000000000000000000000) [staticcall]
    │   │   │   └─ ← [Return] true
    │   │   ├─ [427] Receiver::supportsInterface(0xffffffff00000000000000000000000000000000000000000000000000000000) [staticcall]
    │   │   │   └─ ← [Return] false
    │   │   ├─ [389] Receiver::supportsInterface(0x85572ffb00000000000000000000000000000000000000000000000000000000) [staticcall]
    │   │   │   └─ ← [Return] true
    │   │   ├─ [23037] 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165::routeMessage(Any2EVMMessage({ messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, data: 0x0000000000000000000000000000000000000000000000000000000000000064, destTokenAmounts: [] }), 5000, 500000 [5e5], Receiver: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9])
    │   │   │   ├─ [7457] 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2::isCursed() [staticcall]
    │   │   │   │   ├─ [2395] 0xbcBDf0aDEDC9a33ED5338Bdb4B6F7CE664DC2e8B::isCursed()
    │   │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
  `**  │   │   │   ├─ [5053] Receiver::ccipReceive(Any2EVMMessage({ messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, data: 0x0000000000000000000000000000000000000000000000000000000000000064, destTokenAmounts: [] }))
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
    ├─ [0] console::log("Gas used for ccipReceive: ", 398601 [3.986e5]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("Gas used for ccipReceive: ", 398601 [3.986e5]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::selectFork(0)
    │   └─ ← [Return] 
    ├─ [0] VM::activeFork() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("source Fork Chain ID:", 11155111 [1.115e7]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("Adjusted Gas Limit: %d", 438461 [4.384e5]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("tokens to send details amount:", 100) [staticcall]
    │   └─ ← [Stop] 
    ├─ [59911] → new EncodeExtraArgs@0xa0Cb889707d426A7A386870A03bc70d1b0697598
    │   └─ ← [Return] 299 bytes of code
    ├─ [729] EncodeExtraArgs::encode(438461 [4.384e5]) [staticcall]
    │   └─ ← [Return] 0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd
    ├─ [0] console::log(0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::selectFork(0)
    │   └─ ← [Return] 
    ├─ [0] VM::activeFork() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("source Fork Chain ID:", 11155111 [1.115e7]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [49089] TransferUSDC::transferUsdc(3478487238524512106 [3.478e18], bob: [0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e], 100, 0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd)
    │   ├─ [17634] 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59::getFee(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e, data: 0x, tokenAmounts: [EVMTokenAmount({ token: 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05, amount: 100 })], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd })) [staticcall]
    │   │   ├─ [13095] 0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e::getFee(3478487238524512106 [3.478e18], EVM2AnyMessage({ receiver: 0x0000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e, data: 0x, tokenAmounts: [EVMTokenAmount({ token: 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05, amount: 100 })], feeToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, extraArgs: 0x97a657c9000000000000000000000000000000000000000000000000000000000006b0bd })) [staticcall]
    │   │   │   ├─ [1528] 0x9EF7D57a4ea30b9e37794E55b0C75F2A70275dCc::getTokenAndGasPrices(0x779877A7B0D9E8603169DdbD7836e478b4624789, 3478487238524512106 [3.478e18]) [staticcall]
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000008ee789a88bddac000000000000000000000000000000000000000000000000000000005d13722048
    │   │   │   └─ ← [Return] 46874065079452724 [4.687e16]
    │   │   └─ ← [Return] 46874065079452724 [4.687e16]
    │   ├─ [488] 0x779877A7B0D9E8603169DdbD7836e478b4624789::balanceOf(TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   │   └─ ← [Return] 6000000000000000000 [6e18]
    │   ├─ [24589] 0x779877A7B0D9E8603169DdbD7836e478b4624789::approve(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, 46874065079452724 [4.687e16])
    │   │   ├─ emit Approval(owner: TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], spender: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, value: 46874065079452724 [4.687e16])
    │   │   └─ ← [Return] true
    │   ├─ [880] 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05::transferFrom(TransferUSDCTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], TransferUSDC: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100)
    │   │   └─ ← [Revert] revert: ERC20: insufficient allowance
    │   └─ ← [Revert] revert: ERC20: insufficient allowance
    └─ ← [Revert] revert: ERC20: insufficient allowance

Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 8.64s (4.27s CPU time)

Ran 2 test suites in 9.01s (8.65s CPU time): 3 tests passed, 1 failed, 0 skipped (4 total tests)

Failing tests:
Encountered 1 failing test in test/TransferUSDC.t.sol:TransferUSDCTest
[FAIL. Reason: revert: ERC20: insufficient allowance] test_SendReceive1USDC() (gas: 730585)

Encountered a total of 1 failing tests, 3 tests succeeded