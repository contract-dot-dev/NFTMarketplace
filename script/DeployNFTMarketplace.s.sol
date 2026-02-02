// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployNFTMarketplace is Script {
    NFTMarketplace public marketplace;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        marketplace = new NFTMarketplace();

        console.log("NFTMarketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
    }
}
