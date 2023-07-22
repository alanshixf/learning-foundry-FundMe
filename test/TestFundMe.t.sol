// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract TestFundMe is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 SEND_VALUE = 0.1 ether;
    uint256 START_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BALANCE);
    }

    function testDemo() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithowEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        console.log(USER, fundedAmount);

        assertEq(fundedAmount, SEND_VALUE);
    }

    function testFunder() public funded {
        address funderAddress = fundMe.getFunder(0);
        assertEq(funderAddress, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberofFunders = 12;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            hoax(address(i), START_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 index = 0;
        console.log(
            "funder index: %d; funder address: %s; funded: %d gwei",
            index,
            fundMe.getFunder(index),
            fundMe.getAddressToAmountFunded(fundMe.getFunder(index)) / 1e9
        );
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
    function testWithdrawWithMultipleFundersCheaper() public funded {
        uint160 numberofFunders = 12;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            hoax(address(i), START_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        // uint256 index = 0;
        // console.log(
        //     "funder index: %d; funder address: %s; funded: %d gwei",
        //     index,
        //     fundMe.getFunder(index),
        //     fundMe.getAddressToAmountFunded(fundMe.getFunder(index)) / 1e9
        // );
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdrawCheaper();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
