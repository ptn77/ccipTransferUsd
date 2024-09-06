Day 3 Homework

Needed in .env file to run the TransferUSDC.t.sol test:
SOURCE_NETWORK = "ETHEREUM_SEPOLIA_RPC_URL"
DEST_NETWORK = "ARBITRUM_SEPOLIA_RPC_URL"
TOKEN_SOURCE_ADDRESS = "ccipBnMEthereumSepolia"
TOKEN_DESTINATION_ADDRESS = "ccipBnMArbitrumSepolia"
CHAIN_SOURCE_ID = 16015286601757825753
CHAIN_DESTINATION_ID = 3478487238524512106

Then run: forge test -vvv

TransferUSDC.sol contract does not send messages, only Token.
When the recipient is an EOA, the CCIP router contract on the destination chain handles the token transfer directly, as EOAs cannot implement the ccipReceive function. The router contract checks if the recipient is an EOA and, if so, transfers the tokens directly to the recipient's address.

Not sure why the HW is asking for the gas consumption of ccipReceive function since we were testing using an EOA as the recipient. Added the Send and Receive contracts with ExtraArgs gas_limit set to 500_000 to run the SendReceive.t.sol test for the gas usages instead. The "MessageExecuted(bytes32,uint64,address,bytes32)" match the vm logs when space removed in param list. The minimum gas usage of [PASS] test_SendReceiveMin() (gas: 266188)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  MessageExecuted event: messageId=5ee0f5a3b2c5908c9e70f892738571852b33e9c1694d8bfbbb0986acd18c5e28,result=217a714167eeb29633867facc69b83fa4664e73ee5098437ead57b94d95f803f

Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 13.62ms (10.32ms CPU time)

Ran 1 test for test/TransferUSDC.t.sol:TransferUSDCTest
[PASS] test_SendReceive1USDC() (gas: 988325)

Using https://openchain.xyz/signatures?query=0x9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6, we get:
MessageExecuted(bytes32,uint64,address,bytes32)
event MessageExecuted(bytes32 messageId, uint64 sourceChainSelector, address offRamp, bytes32 calldataHash);

ccipReceive(Any2EVMMessage({ messageId: 0x6a65840544e41ecc70d200eddc9258bbe29232b202d154595d93fc1d43601bf3, sourceChainSelector: 16015286601757825753 [1.601e19], sender: 0x000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a, data: 0x0000000000000000000000000000000000000000000000000000000000000064, destTokenAmounts: [] }))
Token contract of the USDC on Eth Sepolia and Arb Sepolia forks for testing TransferUSDC:
    address constant usdcEthereumSepolia = 
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant usdcArbitrumSepolia =
        0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; //??Not sure if this is correct
Token Pool Contract and ccipReceive (Is this correct for USDC tokens?)

In this process:

The token pool contract on the destination chain will typically have a ccipReceive function or an equivalent function that processes the message received via CCIP. This function handles the minting of new tokens on the destination chain based on the information passed from the source chain.
The ccipReceive function or its equivalent ensures that the cross-chain transfer is completed correctly and that the recipient receives the minted tokens.

Following the https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit guide measure the gas consumption of the ccipReceive function. Once you have the number, increase it by 10% and provide as gasLimit parameter of the transferUsdc function instead of the currently hard-coded 500.000 

Output to search for ccipReceive function:
forge test -vvv
[⠊] Compiling...
[⠆] Compiling 1 files with Solc 0.8.20
[⠰] Solc 0.8.20 finished in 4.32s
Compiler run successful!

Ran 3 tests for test/SendReceive.t.sol:SenderReceiverTest
[PASS] test_SendReceiveAverage() (gas: 275761)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  MessageExecuted event: messageId=598e882e33ea46d5141fd942f5abb45426fc867f9033d923e150c571fa25d3df,result=505bd5ee8afd1a0fc837f0c76dd900746fdc14882e6003fa320453c519b58642

[PASS] test_SendReceiveMax() (gas: 285036)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  MessageExecuted event: messageId=f5bdb0529ec5704ea2677e1bdff0b13a5b79564e297559f97cec7c6dd1785d1f,result=ddcd39482148d8d58d1feb0824e63113847941edc5f600d67f36f997be4deaa8

[PASS] test_SendReceiveMin() (gas: 266188)
Logs:
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  MessageExecuted event: messageId=5ee0f5a3b2c5908c9e70f892738571852b33e9c1694d8bfbbb0986acd18c5e28,result=217a714167eeb29633867facc69b83fa4664e73ee5098437ead57b94d95f803f

Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 9.03ms (8.38ms CPU time)

Ran 1 test for test/TransferUSDC.t.sol:TransferUSDCTest
[PASS] test_SendReceive1USDC() (gas: 988325)
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
  Sending message to ccipReceive through Sender contract to estimate gas...
  0x97a657c9000000000000000000000000000000000000000000000000000000000007a120
  Destination Fork Chain ID: 421614
  0x9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6
  0x339ffc0865dd777ae1997258b42f979aa3352e1475d78c5ff3f74925e281a9f2
  2fdca6724503823c2fdee314a2357f6789760842e990f94aa8dc21d16ac41ff7
  0x2fdca6724503823c2fdee314a2357f6789760842e990f94aa8dc21d16ac41ff7
  9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6
  0x9b877de93ea9895756e337442c657f95a34fc68e7eb988bdfa693d5be83016b6
  MessageExecuted MessageID: 3eb103a3a574f531c48dccf302d8766dcd3cdd6ca5dfc85b6719a9a43fc04b6f
  MessageExecuted ChainSelector: 16015286601757825753
  MessageExecuted Result: 354cb9fec5e093261a361ed05c46a0af34c214a8366597bc30456207778a386f
  Gas used for ccipReceive:  266188
  Gas used for ccipReceive:  266188
  source Fork Chain ID: 11155111
  Adjusted Gas Limit: 292806
  tokens to send details amount: 100
  0x97a657c900000000000000000000000000000000000000000000000000000000000477c6
  source Fork Chain ID: 11155111
  Desstination Fork Chain ID: 421614
  Bob balance in dest chain after transfer:  100

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 10.67s (7.08s CPU time)

Ran 2 test suites in 10.69s (10.68s CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
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
  
  forge test --gas-report
[⠒] Compiling...
[⠒] Compiling 1 files with Solc 0.8.20
[⠢] Solc 0.8.20 finished in 5.05s
Compiler run successful!

Ran 3 tests for test/SendReceive.t.sol:SenderReceiverTest
[PASS] test_SendReceiveAverage() (gas: 356293)
[PASS] test_SendReceiveMax() (gas: 365568)
[PASS] test_SendReceiveMin() (gas: 346708)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 7.80ms (5.44ms CPU time)

Ran 1 test for test/TransferUSDC.t.sol:TransferUSDCTest
[PASS] test_SendReceive1USDC() (gas: 1272411)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 15.60s (11.89s CPU time)
| lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol:CCIPLocalSimulatorFork contract |                 |        |        |        |         |
|-----------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                         | Deployment Size |        |        |        |         |
| 3434353                                                                                 | 15141           |        |        |        |         |
| Function Name                                                                           | min             | avg    | median | max    | # calls |
| getNetworkDetails                                                                       | 3216            | 3216   | 3216   | 3216   | 2       |
| requestLinkFromFaucet                                                                   | 56178           | 67578  | 73278  | 73278  | 3       |
| switchChainAndRouteMessage                                                              | 150443          | 160991 | 160991 | 171540 | 2       |


| lib/chainlink-local/src/ccip/Register.sol:Register contract |                 |      |        |       |         |
|-------------------------------------------------------------|-----------------|------|--------|-------|---------|
| Deployment Cost                                             | Deployment Size |      |        |       |         |
| 0                                                           | 0               |      |        |       |         |
| Function Name                                               | min             | avg  | median | max   | # calls |
| getNetworkDetails                                           | 1435            | 7149 | 11435  | 11435 | 7       |


| script/EncodeExtraArgs.s.sol:EncodeExtraArgs contract |                 |     |        |     |         |
|-------------------------------------------------------|-----------------|-----|--------|-----|---------|
| Deployment Cost                                       | Deployment Size |     |        |     |         |
| 118027                                                | 331             |     |        |     |         |
| Function Name                                         | min             | avg | median | max | # calls |
| encode                                                | 729             | 729 | 729    | 729 | 5       |


| src/Receiver.sol:Receiver contract |                 |       |        |       |         |
|------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                    | Deployment Size |       |        |       |         |
| 616327                             | 3004            |       |        |       |         |
| Function Name                      | min             | avg   | median | max   | # calls |
| allowlistSender                    | 46420           | 46420 | 46420  | 46420 | 4       |
| allowlistSourceChain               | 46236           | 46236 | 46236  | 46236 | 4       |
| supportsInterface                  | 389             | 414   | 427    | 427   | 12      |


| src/Sender.sol:Sender contract |                 |        |        |        |         |
|--------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                | Deployment Size |        |        |        |         |
| 810496                         | 3724            |        |        |        |         |
| Function Name                  | min             | avg    | median | max    | # calls |
| allowlistDestinationChain      | 46257           | 46257  | 46257  | 46257  | 4       |
| sendMessagePayLINK             | 83785           | 113493 | 98026  | 174135 | 4       |


| src/TransferUSDC.sol:TransferUSDC contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                            | Deployment Size |        |        |        |         |
| 999185                                     | 4947            |        |        |        |         |
| Function Name                              | min             | avg    | median | max    | # calls |
| allowlistDestinationChain                  | 46213           | 46213  | 46213  | 46213  | 1       |
| transferUsdc                               | 260903          | 260903 | 260903 | 260903 | 1       |




Ran 2 test suites in 15.61s (15.60s CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)