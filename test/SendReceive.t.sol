// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Importing necessary components from the Chainlink and Forge Standard libraries for testing.
import {Test, console, Vm} from "forge-std/Test.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Sender} from "../src/Sender.sol";
import {Receiver} from "../src/Receiver.sol";
import {EncodeExtraArgs} from "../script/EncodeExtraArgs.s.sol";

/// @title A test suite for Sender and Receiver contracts to estimate ccipReceive gas usage.
contract SenderReceiverTest is Test {
    // Declaration of contracts and variables used in the tests.
    Sender public sender;
    Receiver public receiver;
    BurnMintERC677 public link;
    MockCCIPRouter public router;
    EncodeExtraArgs encodeExtraArgs;
    // A specific chain selector for identifying the chain.
    uint64 public chainSelector = 16015286601757825753;

    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Mock router and LINK token contracts are deployed to simulate the network environment.
        router = new MockCCIPRouter();
        link = new BurnMintERC677("ChainLink Token", "LINK", 18, 10 ** 27);
        // Sender and Receiver contracts are deployed with references to the router and LINK token.
        sender = new Sender(address(router), address(link));
        receiver = new Receiver(address(router));
        // Configuring allowlist settings for testing cross-chain interactions.
        sender.allowlistDestinationChain(chainSelector, true);
        receiver.allowlistSourceChain(chainSelector, true);
        receiver.allowlistSender(address(sender), true);
    }

    function bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /// @dev Helper function to simulate sending a message from Sender to Receiver.
    /// @param iterations The variable to simulate varying loads in the message.
    function sendMessage(uint256 iterations) private {
         encodeExtraArgs = new EncodeExtraArgs();

        uint256 gasLimit = 500_000;
        bytes memory extraArgs = encodeExtraArgs.encode(gasLimit);
        console.logBytes(extraArgs);
        //assertEq(extraArgs, hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40"); // value taken from https://cll-devrel.gitbook.io/ccip-masterclass-3/ccip-masterclass/exercise-xnft#step-3-on-ethereum-sepolia-call-enablechain-function
        assertEq(extraArgs, hex"97a657c9000000000000000000000000000000000000000000000000000000000007a120");
        vm.recordLogs(); // Starts recording logs to capture events.
        sender.sendMessagePayLINK(
            chainSelector,
            address(receiver),
            iterations,
            extraArgs                //400000 // A predefined gas limit for the transaction.
        );
        // Fetches recorded logs to check for specific events and their outcomes.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MessageExecuted(bytes32, uint64, address, bytes32)"
        );

        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (bytes32 messageId, , , bytes32 result) = abi.decode(
                    logs[i].data,
                    (bytes32, uint64, address, bytes32)
                );
                console.log(
                    "MessageExecuted event: messageId=%s, result=%s",
                    bytes32ToString(messageId),
                    bytes32ToString(result)
                );
            }
        }
    }

    /// @notice Test case for the minimum number of iterations.
    function test_SendReceiveMin() public {
        sendMessage(0);
    }

    /// @notice Test case for an average number of iterations.
    function test_SendReceiveAverage() public {
        sendMessage(50);
    }

    /// @notice Test case for the maximum number of iterations.
    function test_SendReceiveMax() public {
        sendMessage(99);
    }
}
