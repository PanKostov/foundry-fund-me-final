// SPDC-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundTheFundMeConract, WithdrawFromFundMeContract} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;
    address user1 = makeAddr("user1");

    uint256 constant USER_INITIAL_BALANCE = 10e18;
    uint256 constant USER2_INITIAL_BALANCE = USER_INITIAL_BALANCE * 2;
    uint256 constant USER3_INITIAL_BALANCE = USER2_INITIAL_BALANCE / 2;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user1, USER_INITIAL_BALANCE);
    }

    function testUserCanFundInteractions() public {
        FundTheFundMeConract fundTheFundMeContract = new FundTheFundMeConract();
        fundTheFundMeContract.fundTheFundMeContract(address(fundMe));

        // address funder = fundMe.getFunder(0);
        // assertEq(funder, user1);

        WithdrawFromFundMeContract withdrawFromFundMeContract = new WithdrawFromFundMeContract();
        withdrawFromFundMeContract.withdrawFromFundMeContract(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
