// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HerkeseAcikNFT} from "../src/HerkeseAcikNFT.sol";

contract DeployHerkeseAcikNFT is Script {
    function run() external returns (HerkeseAcikNFT nft) {
        vm.startBroadcast();
        nft = new HerkeseAcikNFT(0.01 ether, "");
        vm.stopBroadcast();
    }
}
