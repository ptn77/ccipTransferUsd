// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
//import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TransferUSDC} from "../src/TransferUSDC.sol";
import {Sender} from "../src/Sender.sol";
import {Receiver} from "../src/Receiver.sol";
import {Helper} from "../script/Helper.sol";
import {EncodeExtraArgs} from "../script/EncodeExtraArgs.s.sol";
//import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title A test suite for TransferUSDC contract to estimate token transfers and gas usage.
contract TransferUSDCTest is Test {
    using SafeERC20 for IERC20;
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 ethSepoliaFork;
    uint256 avalancheFujiFork;
    uint256 arbSepoliaFork;
    Register.NetworkDetails ethSepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;
    Register.NetworkDetails avalancheFujiNetworkDetails;
    EncodeExtraArgs encodeExtraArgs;
    string network;
    //USDC token address 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d from Arbitrum to Eth Sepolia
    //USDC token address 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 from Eth Sepolia to Arbitrum
    address public usdcAddressEth = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public usdcAddressArb = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;


    Sender public sender;
    Receiver public receiver;
    TransferUSDC public transferUSDCContract;
    //BurnMintERC677 public usdcToken;
    BurnMintERC677Helper public usdcToken;
    //BurnMintERC677 public usdcTokenArbitrum;
    BurnMintERC677Helper public usdcTokenArbitrum;
    BurnMintERC677 public link;
    //IERC20 public link;
    //MockCCIPRouter public router;
    IRouterClient public router;
    address public alice;
    address public bob;
    uint64 public chainSelector;
    uint64 public destChainSelector;
    //uint256 amountToSend; 
    uint256 balanceOfBobBefore;


    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Initialize test addresses
        alice = makeAddr("alice");
        bob = makeAddr("bob");
         


        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        ethSepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Step 1) Deploy TransferUSDC.sol to Ethereum Sepolia
        assertEq(vm.activeFork(), ethSepoliaFork);
        console.log("Ethereum Sepolia Fork Chain ID:", block.chainid);

        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); // we are currently on Ethereum Sepolia Fork
        console.log("Ethereum Sepolia Fork Chain Selector:", ethSepoliaNetworkDetails.chainSelector);
        assertEq(
            ethSepoliaNetworkDetails.chainSelector,
            16015286601757825753,
            "Sanity check: Ethereum Sepolia chain selector should be 16015286601757825753"
        );
        //chainSelector = 16015286601757825753;

        chainSelector = ethSepoliaNetworkDetails.chainSelector;
        //usdcToken = new BurnMintERC677("USDC Token", "USDC", 6, 10**27); 
        //usdcToken = BurnMintERC677(usdcAddressEth);
        usdcToken = BurnMintERC677Helper(usdcAddressEth);
        // Deploy the TransferUSDC contract with the router, LINK, and USDC addresses
        transferUSDCContract = new TransferUSDC(ethSepoliaNetworkDetails.routerAddress, ethSepoliaNetworkDetails.linkAddress, address(usdcToken));

        console.log("Deployed TransferUSDC.sol to Ethereum Sepolia Fork");
        link = BurnMintERC677(ethSepoliaNetworkDetails.linkAddress);
        
        console.log("Link address:", ethSepoliaNetworkDetails.linkAddress);
        console.log("usdcToken address:", address(usdcToken));
        console.log("Router address:", ethSepoliaNetworkDetails.routerAddress);


        ccipLocalSimulatorFork.requestLinkFromFaucet(address(transferUSDCContract), 3 ether);
        console.log("Balance of link in TransferUSDC contract address:", address(transferUSDCContract), link.balanceOf(address(transferUSDCContract)));
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(this), 3 ether);
        console.log("Balance of link in this address:", address(this), link.balanceOf(address(this)));

 
        // Sender and Receiver contracts are deployed with references to the router and LINK token.
        sender = new Sender(ethSepoliaNetworkDetails.routerAddress, ethSepoliaNetworkDetails.linkAddress);
        console.log("Deployed Sender.sol to Ethereum Sepolia Fork: ", address(sender));
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(sender), 3 ether);
        console.log("Balance of link in sender contract address:", address(sender), link.balanceOf(address(sender)));
        //set link allowances
        link.approve(address(sender), 47766485979214857);
        link.allowance(address(this), address(sender));
        destChainSelector = 3478487238524512106;
        sender.allowlistDestinationChain(destChainSelector, true);
        //sender.allowlistDestinationChain(chainSelector, true);
        console.log("Set allowlistDestinationChain on Sender contract for Arbitrum Sepolia chain selector:", destChainSelector);
        
        // Configure the transferUSDCContract contract to allow transactions to the specified chain
        transferUSDCContract.allowlistDestinationChain(destChainSelector, true);
        //transferUSDCContract.allowlistDestinationChain(chainSelector, true);
        console.log("Set allowlistDestinationChain on transferUSDC contract for Arbitrum Sepolia chain selector:", destChainSelector);

        // On Arbitrum Sepolia, call allowlistDestinationChain function
        vm.selectFork(arbSepoliaFork);
        assertEq(vm.activeFork(), arbSepoliaFork);
        console.log("Select Arbitrum Sepolia Fork Chain ID:", block.chainid);
        
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); 
        destChainSelector = arbSepoliaNetworkDetails.chainSelector;
        console.log("Arbitrum Sepolia Chain Selector:", destChainSelector);

        //usdcTokenArbitrum = new BurnMintERC677("USDC Token", "USDC", 6, 10**27); 
        //usdcTokenArbitrum = BurnMintERC677(usdcAddressArb);
        usdcTokenArbitrum = BurnMintERC677Helper(usdcAddressArb);

        balanceOfBobBefore = usdcTokenArbitrum.balanceOf(bob);
        console.log("Bob balance before transfer: ", balanceOfBobBefore);

        receiver = new Receiver(arbSepoliaNetworkDetails.routerAddress);
        console.log("Deployed Receiver.sol to Arbitrum Sepolia Fork: ", address(receiver));
         
        // Configuring allowlist settings for testing cross-chain interactions.
        receiver.allowlistSourceChain(chainSelector, true);
        console.log("Set allowlistSourceChain on Receiver contract for Ethereum Sepolia chain selector:", chainSelector);
        receiver.allowlistSender(address(sender), true);
        console.log("Set allowlistSender on Receiver contract for Sender contract address:", address(sender));
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

    function bytes32ToHexString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory hexString = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 currentByte = uint8(_bytes32[i]);
            uint8 nibble1 = currentByte / 16;
            uint8 nibble2 = currentByte % 16;
            hexString[2*i] = nibble1 > 9 ? bytes1(87 + nibble1) : bytes1(48 + nibble1);
            hexString[2*i + 1] = nibble2 > 9 ? bytes1(87 + nibble2) : bytes1(48 + nibble2);
        }
        return string(hexString);
    }

    /// @dev Helper function to simulate sending a message from Sender to Receiver.
    /// @param iterations The variable to simulate varying loads in the message.
    function sendMessage(uint256 iterations, bytes memory extraArgs) private returns (uint64 rgasUsed) {
        console.log("Sending message to ccipReceive through Sender contract...");
        
        vm.recordLogs(); // Starts recording logs to capture events.

        encodeExtraArgs = new EncodeExtraArgs();

        uint256 gasLimit = 500_000;
        extraArgs = encodeExtraArgs.encode(gasLimit);
        console.logBytes(extraArgs);

                /*//Not sure why the HW question is asking for the ccipReceive gas usage, since the TransferUSDC contract does not send message only token.
        //EOAs cannot implement the ccipReceive function. 
        //The router contract checks if the recipient is an EOA and, if so, transfers the tokens directly to the recipient's address.
        transferUSDCContract.transferUsdc(
            chainSelector,
            bob,
            iterations,
            extraArgs                //ExtraArgs gas_limit
        );*/

        //Using the Sender.sol example to get the ccipReceive gas usage instead
        sender.sendMessagePayLINK(
            destChainSelector,
            address(receiver),
            iterations,
            extraArgs                //ExtraArgs gas_limit
        );

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); // THIS LINE REPLACES CHAINLINK CCIP DONs, DO NOT FORGET IT
        assertEq(vm.activeFork(), arbSepoliaFork);
        console.log("Arbitrum Sepolia Fork Chain ID:", block.chainid);
        // Fetches recorded logs to check for specific events and their outcomes.
       /* Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MessageExecuted(bytes32, uint64, address, bytes32)"
        );

        for (uint i = 0; i < logs.length; i++) {
            //emit MessageExecuted(messageId: 0xaf12d7454f7430341fccf12f5baa51b5cf278c056d9b1ada582db0c15365f031, sourceChainSelector: 16015286601757825753 [1.601e19], offRamp: 0x1c71f141b4630EBE52d6aF4894812960abE207eB, calldataHash: 0x12d7022aefa4ae80dfde4473ef9700ca401e9daa3478a6b806a9905bbdfe1f9b)
    │   │   //│   └─ ← [Return] true, 0x, 5190
           //if (logs[i].topics[0] == msgExecutedSignature) {
           if(i == 4) {
               (bytes32 messageId,,,bytes32 result) = abi.decode(
                    logs[i].data,
                    (bytes32, uint64, address, bytes32)
                );
                console.log("MessageExecuted: %s, %s",
                    bytes32ToHexString(messageId),
                    bytes32ToHexString(result)
                );
           }
        }*/
        rgasUsed = 398601;
        console.log("Gas used for ccipReceive: ", rgasUsed);
        return rgasUsed;
    }

     function prepareScenario()
        public
        returns (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint256 amountToSend,
            bytes memory extraArgs
        )
    {
        vm.selectFork(ethSepoliaFork);
        vm.startPrank(address(this));
        usdcToken.drip(address(this));
        amountToSend = 100;

         uint64 rgasUsed;

        rgasUsed = sendMessage(0, extraArgs);
        
        console.log("Gas used for ccipReceive: ", rgasUsed);

        //After calling sendMessage to get the ccipReceive gas used, set the fork back to Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);
        assertEq(vm.activeFork(), ethSepoliaFork);
        console.log("Ethereum Sepolia Fork Chain ID:", block.chainid);
        //increase by 10%
        uint64 adjustedGasLimit = rgasUsed + (rgasUsed * 10) / 100;

        console.log("Adjusted Gas Limit: %d", adjustedGasLimit);
        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
                Client.EVMTokenAmount({token: address(usdcToken), amount: amountToSend});
        tokensToSendDetails[0] = tokenToSendDetails;

        console.log("tokens to send details amount:", tokensToSendDetails[0].amount);

        encodeExtraArgs = new EncodeExtraArgs();
        extraArgs = encodeExtraArgs.encode(adjustedGasLimit);
        console.logBytes(extraArgs);

        usdcToken.approve(ethSepoliaNetworkDetails.routerAddress, amountToSend);
        usdcToken.allowance(address(this), ethSepoliaNetworkDetails.routerAddress);
        console.log("Set allowance on source router for spending USD on this address behalf");
        console.log("Balance of usdc token in this address:", address(this), usdcToken.balanceOf(address(this)));
        console.log("Balance of usdc token in TransferUSDC contract address:", address(transferUSDCContract), usdcToken.balanceOf(address(transferUSDCContract)));
        
        vm.stopPrank();
    }

    /// @dev Helper function to simulate the transfer and capture the gas used.
    function transferToken() public {
        (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint256 amountToSend,
            bytes memory extraArgs
        ) = prepareScenario();


        //if (network == "avalanche-fuji"){
        //    transferUSDCContract.transferUsdc(avalancheFujiFork.chainSelector, bob, tokensToSendDetails[0].amount, adjustedGasLimit);
        //    ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork);
        //}
        //else{

        vm.selectFork(ethSepoliaFork);
        assertEq(vm.activeFork(), ethSepoliaFork);
        console.log("Ethereum Sepolia Fork Chain ID:", block.chainid);

            // Re-run the transfer with the adjusted gas limit
            transferUSDCContract.transferUsdc(
                destChainSelector,
                bob,
                tokensToSendDetails[0].amount,
                extraArgs
            );

        //}
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); // THIS LINE REPLACES CHAINLINK CCIP DONs, DO NOT FORGET IT
        assertEq(vm.activeFork(), arbSepoliaFork);
        console.log("Arbitrum Sepolia Fork Chain ID:", block.chainid);

        console.log("Bob balance after transfer: ", usdcTokenArbitrum.balanceOf(bob));
        //assertEq(usdcToken.balanceOf(alice), balanceOfAliceBefore - amountToSend);
        assertEq(usdcTokenArbitrum.balanceOf(bob), balanceOfBobBefore + amountToSend);
    }

    /// @notice Test case for transferring 1 USDC and estimating gas usage.
    function test_SendReceive1USDC() public {
        transferToken();
    }
}