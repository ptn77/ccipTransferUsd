// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {TransferUSDC} from "../src/TransferUSDC.sol";
import {Sender} from "../src/Sender.sol";
import {Receiver} from "../src/Receiver.sol";
import {EncodeExtraArgs} from "../script/EncodeExtraArgs.s.sol";
//import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
//import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
//import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import {Helper} from "../script/Helper.sol";
//import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title A test suite for TransferUSDC contract to estimate token transfers and gas usage.
contract TransferUSDCTest is Test {
    //using SafeERC20 for IERC20;
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 sourceFork;
    uint256 detinationFork;
    Register.NetworkDetails sourceNetworkDetails;
    Register.NetworkDetails destinationNetworkDetails;
 
    EncodeExtraArgs encodeExtraArgs;

    //USDC token address 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d from Arbitrum. This has 1  	CCIP-BnM token??
    //USDC Token contract https://sepolia-explorer.arbitrum.io/address/0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d
    //USDC token address 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 from Eth Sepolia FiatTokenProxy
    //Confirmed there is USDC controct on Eth Sepolia https://sepolia.etherscan.io/address/0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
    address constant ccipBnMEthereumSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMArbitrumSepolia =
        0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant ccipBnMAvalancheFuji =
        0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address constant usdcEthereumSepolia = 
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant usdcArbitrumSepolia =
        0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; //??Not sure if this is correct
    Sender public sender;
    Receiver public receiver;
    TransferUSDC public transferUSDCContract;
    BurnMintERC677Helper public sourceToken;
    BurnMintERC677Helper public destToken;
    BurnMintERC677 public link;
    //IERC20 public link;
    //MockCCIPRouter public router;
    //IRouterClient public router;
    address public alice;
    address public bob;
    uint64 public sourceChainSelector;
    uint64 public destChainSelector;
    //uint256 amountToSend; 
    uint256 balanceOfBobBefore;

    // Function to return address based on name
    function getAddressByName(string memory name) public pure returns (address) {
        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("ccipBnMEthereumSepolia"))) {
            return ccipBnMEthereumSepolia;
        } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("ccipBnMArbitrumSepolia"))) {
            return ccipBnMArbitrumSepolia;
        } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("ccipBnMAvalancheFuji"))) {
            return ccipBnMAvalancheFuji;
        } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("usdcEthereumSepolia"))) {
            return usdcEthereumSepolia;
        } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("usdcArbitrumSepolia"))) {
            return usdcArbitrumSepolia;
        } else {
            revert("Invalid name");
        }
    }

    /// @dev Sets up the testing environment by deploying necessary contracts and configuring their states.
    function setUp() public {
        // Initialize test addresses
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        string memory SOURCE_NETWORK = vm.envString("SOURCE_NETWORK");
        string memory DEST_NETWORK = vm.envString("DEST_NETWORK");

        string memory SOURCE_RPC_URL = vm.envString(SOURCE_NETWORK);
        string memory DESTINATION_RPC_URL = vm.envString(DEST_NETWORK);
        sourceFork = vm.createSelectFork(SOURCE_RPC_URL);
        detinationFork = vm.createFork(DESTINATION_RPC_URL);

        string memory tokenSourceAddressName = vm.envString("TOKEN_SOURCE_ADDRESS");
        string memory tokenDestinationAddressName = vm.envString("TOKEN_DESTINATION_ADDRESS");
        address tokenSourceAddress = getAddressByName(tokenSourceAddressName);
        address tokenDestinationAddress = getAddressByName(tokenDestinationAddressName);
        
        sourceChainSelector = uint64(vm.envUint("CHAIN_SOURCE_ID"));
        destChainSelector = uint64(vm.envUint("CHAIN_DESTINATION_ID"));

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Step 1) Deploy TransferUSDC.sol to Ethereum Sepolia
        assertEq(vm.activeFork(), sourceFork);
        console.log("source Fork Chain ID:", block.chainid);

        sourceNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); // we are currently on Ethereum Sepolia Fork
        console.log("source Fork Chain Selector:", sourceNetworkDetails.chainSelector);
        /*assertEq(
            sourceNetworkDetails.chainSelector,
            16015286601757825753,
            "Sanity check: Source chain selector should be 16015286601757825753"
        );*/

        assertEq(sourceNetworkDetails.chainSelector, sourceChainSelector);
  
        //usdcToken = new BurnMintERC677("USDC Token", "USDC", 6, 10**27); 
        //usdcToken = BurnMintERC677(usdcEthereumSepolia);

        //using the predefined USDC address from forked chain for Eth Sepolia instead of deploying new token contract
        //using the BurnMintERC677Helper for the Drip function
        //usdcToken = BurnMintERC677Helper(usdcEthereumSepolia);
        sourceToken = BurnMintERC677Helper(tokenSourceAddress); //We are using the BnM CCIP-BnM for USDC for testing purposes due to limit on drip possibly.
      
        // Deploy the TransferUSDC contract with the router, LINK, and USDC addresses on Ethereum Sepolia
        transferUSDCContract = new TransferUSDC(sourceNetworkDetails.routerAddress, sourceNetworkDetails.linkAddress, address(sourceToken));

        console.log("Deployed TransferUSDC.sol to source Fork: ", address(transferUSDCContract));

        link = BurnMintERC677(sourceNetworkDetails.linkAddress);

        // Sender and Receiver contracts are deployed with references to the router and LINK token.
        //Sender will be on Ethereum Sepolia
        sender = new Sender(sourceNetworkDetails.routerAddress, sourceNetworkDetails.linkAddress);
        console.log("Deployed Sender.sol to source Fork: ", address(sender));

        //Since there is a requestLinkFromFaucet method on the ccipLocalSimulatorFort, we can send LINK to the sender contract and TransferUSDC contract address 
        //This link may be used for the TransferUSDC contract to pay fees when sending USDC Tokens?
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(transferUSDCContract), 3 ether);
        console.log("Balance of link in sender contract address:", address(transferUSDCContract), link.balanceOf(address(transferUSDCContract)));

        //The sender contract will approve the router to spend 47766485979214857 LINK on the sender contract's behalf. No need to do that here
        //but do we need to approve for the Sender contract on ETH Sepolia to spend LINK on this address' behalf for fees and gas to call Sender's sendMessagePayLINK method
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(this), 3 ether);
        console.log("Balance of link in this address:", address(this), link.balanceOf(address(this)));

        link.approve(address(sender), 47766485979214857);

        assertEq(link.allowance(address(this), address(sender)), 47766485979214857, "Sanity check: Link allowance should be 47766485979214857");

        // We should only need to set the sender.allowlistDestinationChain(sourceChainSelector, true);
        sender.allowlistDestinationChain(destChainSelector, true);

        console.log("Link address on source chain:", sourceNetworkDetails.linkAddress);
        console.log("usdcToken address on source chain:", address(sourceToken));
        console.log("Router address on source chain:", sourceNetworkDetails.routerAddress);
        
        //Request LINK for transferUSDCContract on Ethereum Sepolia
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(transferUSDCContract), 3 ether);
        console.log("Balance of link on source chain TransferUSDC contract address:", address(transferUSDCContract), link.balanceOf(address(transferUSDCContract)));
        //Do we need LINK in our current "this" address? Comment out for now
        //ccipLocalSimulatorFork.requestLinkFromFaucet(address(this), 3 ether);
        //console.log("Balance of link on ethereum sepolia in this address:", address(this), link.balanceOf(address(this)));
        
        //We should not need to set the allowance for the router on eth sepolia since the TransferUSDC contract will approve the router
        //console.log("Set allowance on ethereum sepolia router %s for spending USDC = %d.", sourceNetworkDetails.routerAddress, amountToSend);
        //Drip some USDC for the TransferUSDC contract? or for this address and set approve for the TransferUSDC contract to spend on "this" address behalf 
        //in prepareScenario() function 
        //sourceToken.approve(sourceNetworkDetails.routerAddress, amountToSend);
        //sourceToken.allowance(address(this), sourceNetworkDetails.routerAddress);
        
        // Configure the transferUSDCContract contract to allow transactions to be sent to destination chain
        transferUSDCContract.allowlistDestinationChain(destChainSelector, true);

        // On Arbitrum Sepolia, call allowlistDestinationChain function
        vm.selectFork(detinationFork);
        assertEq(vm.activeFork(), detinationFork);
        console.log("Select destination Fork Chain ID:", block.chainid);
        
        destinationNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); 
        assertEq(destinationNetworkDetails.chainSelector, destChainSelector); //Sanity check: Arbitrum Sepolia chain selector should be (uint64 = 3478487238524512106;)

        //destToken = new BurnMintERC677("USDC Token", "USDC", 6, 10**27); 
        //destToken = BurnMintERC677(usdcArbitrumSepolia);
        //destToken = BurnMintERC677Helper(usdcArbitrumSepolia);
        destToken = BurnMintERC677Helper(tokenDestinationAddress); //We are using the ccipBnM in place of USDC address for testing due to possible limit on drip for USDC.
     
        balanceOfBobBefore = destToken.balanceOf(bob);
        console.log("Bob balance before transfer: ", balanceOfBobBefore);

        receiver = new Receiver(destinationNetworkDetails.routerAddress);
        console.log("Deployed Receiver.sol to destination Fork: ", address(receiver));
         
        // Configuring allowlist settings for testing cross-chain interactions.
        //allow ethereum sepolia chain selector on receiver contract
        receiver.allowlistSourceChain(sourceChainSelector, true);
        console.log("Set allowlistSourceChain on Receiver contract for source chain selector:", sourceChainSelector);
        //allow source chain sender contract to send to receiver on destination chain
        receiver.allowlistSender(address(sender), true);
        console.log("Set allowlistSender on destination Receiver contract for Sender contract Address:", address(sender));
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
        console.log("Sending message to ccipReceive through Sender contract to estimate gas...");
        
        vm.recordLogs(); // Starts recording logs to capture events.

        encodeExtraArgs = new EncodeExtraArgs();

        uint256 gasLimit = 500_000;
        extraArgs = encodeExtraArgs.encode(gasLimit);
        console.logBytes(extraArgs);

        //Not sure why the HW question is asking for the ccipReceive gas usage, since the TransferUSDC contract does not send message, only token.
        //Perhaps, there is a ccipReceive function in the Token pool contract??
        //EOAs cannot implement the ccipReceive function. 
        //The router contract checks if the recipient is an EOA and, if so, transfers the tokens directly to the recipient's address.
        //when sending 0, we get 5cf04449 which is CannotSendZeroTokens() from https://openchain.xyz/signatures?query=0x5cf04449
        /*transferUSDCContract.transferUsdc(
            destChainSelector,
            bob,
            1,
            extraArgs                //ExtraArgs gas_limit
        );*/

        //Using the Sender.sol example to get the ccipReceive gas usage instead
        sender.sendMessagePayLINK(
            destChainSelector,
            address(receiver),
            iterations,
            extraArgs                //ExtraArgs gas_limit
        );

        ccipLocalSimulatorFork.switchChainAndRouteMessage(detinationFork); // THIS LINE REPLACES CHAINLINK CCIP DONs, DO NOT FORGET IT
        assertEq(vm.activeFork(), detinationFork);
        console.log("Destination Fork Chain ID:", block.chainid);
        // Fetches recorded logs to check for specific events and their outcomes.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MessageExecuted(bytes32, uint64, address, bytes32)"
        );
        console.log("MessageExecuted hex string: ", bytes32ToHexString(msgExecutedSignature));
        for (uint i = 0; i < logs.length; i++) {
            /*//emit MessageExecuted(messageId: 0xaf12d7454f7430341fccf12f5baa51b5cf278c056d9b1ada582db0c15365f031, sourceChainSelector: 16015286601757825753 [1.601e19], offRamp: 0x1c71f141b4630EBE52d6aF4894812960abE207eB, calldataHash: 0x12d7022aefa4ae80dfde4473ef9700ca401e9daa3478a6b806a9905bbdfe1f9b)
            //│   └─ ← [Return] true, 0x, 5190 */
            console.log(bytes32ToHexString(logs[i].topics[0]));
            if (logs[i].topics[0] == msgExecutedSignature) {
            //if(i == 4) {
            (bytes32 messageId,,,bytes32 result) = abi.decode(
                    logs[i].data,
                    (bytes32, uint64, address, bytes32)
                );
                console.log("MessageExecuted: %s, %s",
                    bytes32ToHexString(messageId),
                    bytes32ToHexString(result)
                );
            }
        }
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
        
        vm.selectFork(sourceFork);
        assertEq(vm.activeFork(), sourceFork);
        console.log("Source Fork Chain ID:", block.chainid);

        vm.startPrank(address(this));
        sourceToken.drip(address(this));
        amountToSend = 100;

        console.log("Balance of usdc token on source chain in this address:", address(this), sourceToken.balanceOf(address(this)));
        console.log("Balance of usdc token on source chain in TransferUSDC contract address:", address(transferUSDCContract), sourceToken.balanceOf(address(transferUSDCContract)));
        //Approve the allowance for the transferUSDC contract to spend usdc tokens on "this" address' behalf
        //Comment this out to cause error to view log in console and get the ccipReceive gas usage
        sourceToken.approve(address(transferUSDCContract), amountToSend);
        assertEq(sourceToken.allowance(address(this), address(transferUSDCContract)), amountToSend);

         uint64 rgasUsed;
        rgasUsed = sendMessage(amountToSend, extraArgs);
        
        console.log("Gas used for ccipReceive: ", rgasUsed);

        //After calling sendMessage to get the ccipReceive gas used, set the fork back to Ethereum Sepolia
        vm.selectFork(sourceFork);
        assertEq(vm.activeFork(), sourceFork);
        console.log("source Fork Chain ID:", block.chainid);
        //increase by 10%
        uint64 adjustedGasLimit = rgasUsed + (rgasUsed * 10) / 100;

        console.log("Adjusted Gas Limit: %d", adjustedGasLimit);
        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
                Client.EVMTokenAmount({token: address(sourceToken), amount: amountToSend});
        tokensToSendDetails[0] = tokenToSendDetails;

        console.log("tokens to send details amount:", tokensToSendDetails[0].amount);

        encodeExtraArgs = new EncodeExtraArgs();
        extraArgs = encodeExtraArgs.encode(adjustedGasLimit);
        console.logBytes(extraArgs);

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
        //    ccipLocalSimulatorFork.switchChainAndRouteMessage(sourceFork);
        //}
        //else{

        vm.selectFork(sourceFork);
        assertEq(vm.activeFork(), sourceFork);
        console.log("source Fork Chain ID:", block.chainid);

            // Re-run the transfer with the adjusted gas limit
            transferUSDCContract.transferUsdc(
                destChainSelector,
                bob,
                tokensToSendDetails[0].amount,
                extraArgs
            );

        //}
        ccipLocalSimulatorFork.switchChainAndRouteMessage(detinationFork); // THIS LINE REPLACES CHAINLINK CCIP DONs, DO NOT FORGET IT
        assertEq(vm.activeFork(), detinationFork);
        console.log("Desstination Fork Chain ID:", block.chainid);

        console.log("Bob balance in dest chain after transfer: ", destToken.balanceOf(bob));
        assertEq(destToken.balanceOf(bob), balanceOfBobBefore + amountToSend);
    }

    /// @notice Test case for transferring 1 USDC and estimating gas usage.
    function test_SendReceive1USDC() public {
        transferToken();
    }
}