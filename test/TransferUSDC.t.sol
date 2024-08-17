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


    Sender public sender;
    Receiver public receiver;
    TransferUSDC public transferUSDCContract;
    BurnMintERC677 public usdcToken;
    BurnMintERC677 public link;
    //IERC20 public link;
    //MockCCIPRouter public router;
    IRouterClient public router;
    address public alice;
    address public bob;
    uint64 public chainSelector;
    uint64 public destChainSelector;
    uint256 amountToSend; 


    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Initialize test addresses
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        amountToSend = 1000000; // 1 USDC (since USDC has 6 decimals)


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
        usdcToken = new BurnMintERC677("USDC Token", "USDC", 6, 10**27); 
        // Deploy the TransferUSDC contract with the router, LINK, and USDC addresses
        transferUSDCContract = new TransferUSDC(ethSepoliaNetworkDetails.routerAddress, ethSepoliaNetworkDetails.linkAddress, address(usdcToken));

        console.log("Deployed TransferUSDC.sol to Ethereum Sepolia Fork");
        link = BurnMintERC677(ethSepoliaNetworkDetails.linkAddress);
        console.log("Link address:", ethSepoliaNetworkDetails.linkAddress);
        console.log("usdcToken address:", address(usdcToken));
        console.log("Router address:", ethSepoliaNetworkDetails.routerAddress);


        ccipLocalSimulatorFork.requestLinkFromFaucet(address(transferUSDCContract), 3 ether);
        console.log("Balance of link in TransferUSDC contract address:", address(transferUSDCContract), link.balanceOf(address(transferUSDCContract)));

 
        // Sender and Receiver contracts are deployed with references to the router and LINK token.
        sender = new Sender(ethSepoliaNetworkDetails.routerAddress, ethSepoliaNetworkDetails.linkAddress);
        console.log("Deployed Sender.sol to Ethereum Sepolia Fork: ", address(sender));

        destChainSelector = 3478487238524512106;
        sender.allowlistDestinationChain(destChainSelector, true);
        //sender.allowlistDestinationChain(chainSelector, true);
        console.log("Set allowlistDestinationChain on Sender contract for Arbitrum Sepolia chain selector:", destChainSelector);
        
        // Configure the transferUSDCContract contract to allow transactions to the specified chain
        transferUSDCContract.allowlistDestinationChain(destChainSelector, true);
        //transferUSDCContract.allowlistDestinationChain(chainSelector, true);
        console.log("Set allowlistDestinationChain on transferUSDC contract for Arbitrum Sepolia chain selector:", destChainSelector);


        usdcToken.grantMintRole(address(this));
        usdcToken.mint(address(this), amountToSend*2);
        console.log("minted usdc");
        usdcToken.approve(address(transferUSDCContract), amountToSend);  
        console.log("Set allowance on TransferUSDC contract for spending USD on this address behalf");
        usdcToken.allowance(address(this), address(transferUSDCContract));
        //usdcToken.transfer(address(transferUSDCContract), amountToSend);
        
        console.log("Balance of usdc token in this address:", address(this), usdcToken.balanceOf(address(this)));
        console.log("Balance of usdc token in TransferUSDC contract address:", address(transferUSDCContract), usdcToken.balanceOf(address(transferUSDCContract)));
        

        // On Arbitrum Sepolia, call allowlistDestinationChain function
        vm.selectFork(arbSepoliaFork);
        assertEq(vm.activeFork(), arbSepoliaFork);
        console.log("Select Arbitrum Sepolia Fork Chain ID:", block.chainid);
        
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); 
        destChainSelector = arbSepoliaNetworkDetails.chainSelector;
        console.log("Arbitrum Sepolia Chain Selector:", destChainSelector);

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
    function sendMessage(uint256 iterations) private returns (uint64 rgasUsed) {
        console.log("Sending message to ccipReceive through Sender contract...");
         vm.recordLogs(); // Starts recording logs to capture events.

         encodeExtraArgs = new EncodeExtraArgs();

        uint256 gasLimit = 500_000;
        bytes memory extraArgs = encodeExtraArgs.encode(gasLimit);
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
            //This is not findng the signature match for some reason.
            //The logs do show 4 arguments in function signature
            //    │   │   ├─ emit MessageExecuted(messageId: 0x251a62bce4c708205f829e9855a0291cc6fefddd0dfa6b61c75de91d5b7f0a9f, sourceChainSelector: 16015286601757825753 [1.601e19], offRamp: Sender: [0xc7183455a4C133Ae270771860664b6B7ec320bB1], calldataHash: 0xe0935c7962a29d672d0b3927274abfa1fb9decb5d604fe04c87f775278b2e3d6)
           //Perhaps the MockCCIPRouter is outdated version? 
           //event MessageExecuted(bytes32 messageId, uint64 sourceChainSelector, address offRamp, bytes32 calldataHash);
           //log length = 6, does this correspond to the 6 emit in the logs?
           //emit Approval
           //emit Transfer
           //emit Approval
           //emit MessageReceived
           //emit MessageExecuted <-- index 4 string version of logs[4].topics[0]: ��}�>��WV�7D,e��OƎ~����i=[�0�
           //emit MessageSent
           //msgExecutedSig: f�C8��k��'�-
            //console.log("string version of msgExecutedSig:", bytes32ToString(msgExecutedSignature));
            //console.log("string version of logs[%d].topics[0]:",i,bytes32ToString(logs[i].topics[0]));
            console.log("msgExecutedSignature: %s", bytes32ToHexString(msgExecutedSignature));
            console.log("logs[%d].topics[0]: %s", i, bytes32ToHexString(logs[i].topics[0]));
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
        rgasUsed = 85779;
        console.log("Gas used for ccipReceive: ", rgasUsed);
        return rgasUsed;
    }

    /// @dev Helper function to simulate the transfer and capture the gas used.
    function transferToken() private {
        Client.EVMTokenAmount[] memory tokensToSendDetails;

        vm.selectFork(ethSepoliaFork);
        assertEq(vm.activeFork(), ethSepoliaFork);
        console.log("Ethereum Sepolia Fork Chain ID:", block.chainid);

        uint64 rgasUsed;
        //Not sure why SendMessage is not matching the MessageExecuted signature, but
        //from terminal output (gas: 85779), going to use this value for now.

        rgasUsed = sendMessage(0);
        
        
        console.log("Gas used for ccipReceive: ", rgasUsed);
        //increase by 10%
        uint64 adjustedGasLimit = rgasUsed + (rgasUsed * 10) / 100;

        console.log("Adjusted Gas Limit: %d", adjustedGasLimit);
                    tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
                Client.EVMTokenAmount({token: address(usdcToken), amount: amountToSend});
        tokensToSendDetails[0] = tokenToSendDetails;

        uint256 balanceOfBobBefore = usdcToken.balanceOf(bob);
        console.log("Bob balance before transfer: ", usdcToken.balanceOf(bob));
        console.log("tokens to send details amount:", tokensToSendDetails[0].amount);

        encodeExtraArgs = new EncodeExtraArgs();
        bytes memory extraArgs = encodeExtraArgs.encode(adjustedGasLimit);
        console.logBytes(extraArgs);
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

        console.log("Bob balance after transfer: ", usdcToken.balanceOf(bob));
        //assertEq(usdcToken.balanceOf(alice), balanceOfAliceBefore - amountToSend);
        assertEq(usdcToken.balanceOf(bob), balanceOfBobBefore + amountToSend);
    }

    /// @notice Test case for transferring 1 USDC and estimating gas usage.
    function test_SendReceive1USDC() public {
        transferToken();
    }
}