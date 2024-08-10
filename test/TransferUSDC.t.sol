// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Importing necessary components from the Chainlink and Forge Standard libraries for testing.
import {Test, console, Vm} from "forge-std/Test.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {TransferUSDC} from "../src/TransferUSDC.sol";


/// @title A test suite for TransferUSDC Test contracts to estimate ccipReceive gas usage.
contract TransferUSDCTest is Test {
    using SafeERC20 for IERC20;

    // Declaration of contracts and variables used in the tests.
    TransferUSDC public sender;
    BurnMintERC677 public link;  // Updated to BurnMintERC677
    MockCCIPRouter public router; // Mock router to simulate the network environment

    uint64 public chainSelector = 16015286601757825753; // A specific chain selector for identifying the chain
    address public usdc = 0x5425890298aed601595a70AB815c96711a31Bc65; // USDC token address on Avalanche Fuji

    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Mock router to simulate the network environment.
        router = new MockCCIPRouter();

        // Deploy the BurnMintERC677 token, which will be used as the LINK token.
        link = new BurnMintERC677("Chainlink Token", "LINK", 18);

        // Sender contract is deployed with references to the router, LINK token, and USDC token.
        sender = new TransferUSDC(address(router), address(link), usdc);

        // Configuring allowlist settings for testing cross-chain interactions.
        sender.allowlistDestinationChain(chainSelector, true);
    }

    /// @dev Helper function to simulate sending a message and capture the gas used.
    function sendMessage() private {
        vm.recordLogs(); // Starts recording logs to capture events.

        // Predefined gas limit for the transaction, will be adjusted after measurement.
        uint64 initialGasLimit = 500000;

        // Transfer 1 USDC (1 * 10^6 = 1000000)
        uint256 usdcAmount = 1000000;

        sender.transferUsdc(
            chainSelector,
            address(this),
            usdcAmount,
            initialGasLimit
        );

        // Fetches recorded logs to check for specific events and their outcomes.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MsgExecuted(bool,bytes,uint256)"
        );

        uint256 gasUsed;
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (, , gasUsed) = abi.decode(
                    logs[i].data,
                    (bool, bytes, uint256)
                );
                console.log(
                    "Gas used for transferring 1 USDC: %d",
                    gasUsed
                );
            }
        }

        // Increase gas by 10%
        uint64 adjustedGasLimit = uint64((gasUsed * 110) / 100);

        console.log("Adjusted Gas Limit: %d", adjustedGasLimit);

        // Re-run transferUsdc with adjusted gas limit
        sender.transferUsdc(
            chainSelector,
            address(this),
            usdcAmount,
            adjustedGasLimit
        );
    }

    /// @notice Test case for transferring 1 USDC.
    function test_SendReceive1USDC() public {
        sendMessage();
    }
}
