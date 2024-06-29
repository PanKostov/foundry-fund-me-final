// SPDC-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint256 constant USER_INITIAL_BALANCE = 10e18;
    uint256 constant USER2_INITIAL_BALANCE = USER_INITIAL_BALANCE * 2;
    uint256 constant USER3_INITIAL_BALANCE = USER2_INITIAL_BALANCE / 2;
    uint256 constant GAS_PRICE = 1;

    FundMe fundMe;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    modifier funded(uint256 value) {
        vm.prank(user1);
        fundMe.fund{value: value}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user1, USER_INITIAL_BALANCE);
        vm.deal(user2, USER2_INITIAL_BALANCE);
        vm.deal(user3, USER3_INITIAL_BALANCE);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundRevertsIfWeDontSendEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesDataStructures() public {
        uint256 amountToFund = 6e18;
        vm.prank(user1);
        fundMe.fund{value: amountToFund}();

        address funder = fundMe.getFunder(0);
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user1);
        assertEq(funder, user1);
        assertEq(amountFunded, amountToFund);
    }

    function testRevertIfNonOwnerCallsWithdraw() public funded(USER_INITIAL_BALANCE) {
        vm.prank(user1);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testOwnerCanWithdraw() public funded(USER_INITIAL_BALANCE) {
        address owner = fundMe.getOwner();
        uint256 initialOwnerBalance = owner.balance; // 0
        uint256 initialContractBalance = address(fundMe).balance; // 30

        vm.prank(owner);
        fundMe.withdraw();

        uint256 endOwnerBalance = owner.balance; // 30
        uint256 endContractBalance = address(fundMe).balance;

        assertEq(endContractBalance, 0);
        assertEq(endOwnerBalance, initialContractBalance + initialOwnerBalance);
    }

    function testWithdrawFromThreeFunders() public funded(USER_INITIAL_BALANCE) {
        vm.prank(user2);
        fundMe.fund{value: USER2_INITIAL_BALANCE}();
        vm.prank(user3);
        fundMe.fund{value: USER3_INITIAL_BALANCE}();

        address owner = fundMe.getOwner();
        vm.deal(owner, USER_INITIAL_BALANCE);

        uint256 initialOwnerBalance = owner.balance; // 10
        uint256 initialContractBalance = address(fundMe).balance; // 10 + 20 + 5 = 35

        vm.prank(owner);
        fundMe.withdraw();

        uint256 endOwnerBalance = owner.balance; // 45
        uint256 endContractBalance = address(fundMe).balance;

        uint256 user1AmountFunded = fundMe.getAddressToAmountFunded(user1);
        uint256 user2AmountFUnded = fundMe.getAddressToAmountFunded(user2);
        uint256 user3AmountFunded = fundMe.getAddressToAmountFunded(user3);

        assertEq(endContractBalance, 0);
        assertEq(endOwnerBalance, initialContractBalance + initialOwnerBalance);
        assertEq(user1AmountFunded + user2AmountFUnded + user3AmountFunded, 0);
    }

    function testWithdrawFromMultipleFunders() public funded(USER_INITIAL_BALANCE) {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), USER_INITIAL_BALANCE); // hoax - similar to prank
            fundMe.fund{value: USER_INITIAL_BALANCE}();
        }

        address owner = fundMe.getOwner();
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialContractBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);

        vm.prank(owner);
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("GAS USED: ", gasUsed); // 16248

        uint256 endOwnerBalance = owner.balance;
        uint256 endContractBalance = address(fundMe).balance;

        assertEq(endContractBalance, 0);
        assertEq(endOwnerBalance, initialContractBalance + initialOwnerBalance);
    }

    function testCheaperWithdrawFromMultipleFunders() public funded(USER_INITIAL_BALANCE) {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), USER_INITIAL_BALANCE); // hoax - similar to prank
            fundMe.fund{value: USER_INITIAL_BALANCE}();
        }

        address owner = fundMe.getOwner();
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialContractBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);

        vm.prank(owner);
        fundMe.cheaperWithdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("GAS CHEPAER USED: ", gasUsed); // 15061

        uint256 endOwnerBalance = owner.balance;
        uint256 endContractBalance = address(fundMe).balance;

        assertEq(endContractBalance, 0);
        assertEq(endOwnerBalance, initialContractBalance + initialOwnerBalance);
    }

    function testFundAfterWitdraw() public funded(USER_INITIAL_BALANCE) {
        address owner = fundMe.getOwner();
        vm.prank(owner);
        fundMe.cheaperWithdraw();

        vm.prank(user2);
        fundMe.fund{value: USER2_INITIAL_BALANCE}();

        address funder = fundMe.getFunder(0);
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user2);
        assertEq(funder, user2);
        assertEq(amountFunded, USER2_INITIAL_BALANCE);
    }
}
