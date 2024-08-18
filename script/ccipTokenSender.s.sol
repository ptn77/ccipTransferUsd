// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Sender} from "../src/Sender.sol";
//import {Helper} from "./Helper.sol";

contract DeployCCIPTokenSender is Script {
    address constant linkAvalancheFuji =
        0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant routerAvalancheFuji =
        0xF694E193200268f9a4868e4Aa017A0118C9a8177;
        
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address fujiLink = linkAvalancheFuji;    //0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
        address fujiRouter = routerAvalancheFuji; //This is old router?0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;

        Sender sender = new Sender(
            fujiLink,
            fujiRouter
        );

        console.log(
            "Sender deployed to ",
            address(sender)
        );

        vm.stopBroadcast();
    }
}