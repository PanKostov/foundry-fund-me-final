// SPDC_License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we arew on a local anvil, deploy mocks
    // otherwise, garb the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            //Sepolia chainid
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            //ETH Mainnet chainid
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 300) {
            activeNetworkConfig = getZkSyncSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return sepoliaConfig;
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF // ETH / USD
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        uint8 DECIMALS = 8;
        int256 INITIAL_PRICE = 2000e8;

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
