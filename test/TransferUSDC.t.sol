// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TransferUSDC} from "../src/TransferUSDC.sol";

/// @title A test suite for TransferUSDC contract to estimate token transfers and gas usage.
contract TransferUSDCTest is Test {
    using SafeERC20 for IERC20;

    TransferUSDC public sender;
    BurnMintERC677 public usdcToken;
    BurnMintERC677 public link;
    MockCCIPRouter public router;
    uint64 public chainSelector = 16015286601757825753;
    address public alice;
    address public bob;

    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Initialize test addresses
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy the mock router and mock tokens (LINK and USDC)
        router = new MockCCIPRouter();
        link = new BurnMintERC677("ChainLink Token", "LINK", 18, 10**27);
        usdcToken = new BurnMintERC677("USDC Token", "USDC", 6, 10**15); // Deploy with initial supply

        // Assign initial supply of USDC to Alice
        usdcToken.transfer(alice, usdcToken.totalSupply());

        // Deploy the TransferUSDC contract with the router, LINK, and USDC addresses
        sender = new TransferUSDC(address(router), address(link), address(usdcToken));

        // Configure the sender contract to allow transactions to the specified chain
        sender.allowlistDestinationChain(chainSelector, true);
    }

    /// @dev Helper function to prepare the token transfer scenario.
    function prepareScenario() 
        public
        returns (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) 
    {
        vm.startPrank(alice);

        amountToSend = 1000000; // 1 USDC (since USDC has 6 decimals)
        usdcToken.approve(address(sender), amountToSend); // Alice approves TransferUSDC to spend 1 USDC

        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
            Client.EVMTokenAmount({token: address(usdcToken), amount: amountToSend});
        tokensToSendDetails[0] = tokenToSendDetails;

        vm.stopPrank();
    }

    /// @dev Helper function to simulate the transfer and capture the gas used.
    function transferToken() private {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = prepareScenario();

        vm.recordLogs();

        uint64 initialGasLimit = 500000;

        // Transfer USDC using the sender contract
        sender.transferUsdc(
            chainSelector,
            bob,
            tokensToSendDetails[0].amount,
            initialGasLimit
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256("MsgExecuted(bool,bytes,uint256)");
        uint256 gasUsed;
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (, , gasUsed) = abi.decode(
                    logs[i].data,
                    (bool, bytes, uint256)
                );
                console.log(
                    "Gas used for MsgExecuted: %d",
                    gasUsed
                );
            }
        }

        uint64 adjustedGasLimit = uint64((gasUsed * 110) / 100);
        console.log("Adjusted Gas Limit: %d", adjustedGasLimit);

        // Re-run the transfer with the adjusted gas limit
        sender.transferUsdc(
            chainSelector,
            bob,
            tokensToSendDetails[0].amount,
            adjustedGasLimit
        );

        // Verify the balances after the transfer
        uint256 balanceOfAliceBefore = usdcToken.balanceOf(alice);
        uint256 balanceOfBobBefore = usdcToken.balanceOf(bob);

        assertEq(usdcToken.balanceOf(alice), balanceOfAliceBefore - amountToSend);
        assertEq(usdcToken.balanceOf(bob), balanceOfBobBefore + amountToSend);
    }

    /// @notice Test case for transferring 1 USDC and estimating gas usage.
    function test_SendReceive1USDC() public {
        transferToken();
    }
}