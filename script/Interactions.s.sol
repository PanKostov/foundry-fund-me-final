// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundTheFundMeConract is ZkSyncChainChecker, Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundTheFundMeContract(address mostRecentDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundTheFundMeContract(mostRecentlyDeployed);
    }
}

contract WithdrawFromFundMeContract is Script {
    uint256 constant WITHDRAW_VALUE = 0.01 ether;

    function withdrawFromFundMeContract(address mostRecentDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdrawed from FundMe");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFromFundMeContract(mostRecentlyDeployed);
    }
}
