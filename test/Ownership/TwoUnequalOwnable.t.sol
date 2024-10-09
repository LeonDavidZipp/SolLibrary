// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TwoUnequalOwnable} from "ownership/TwoUnequalOwnable.sol";

contract CounterTest is Test {
    address owner = address(0x1);
    address backup = address(0x2);
    TwoUnequalOwnable public ownable;

    function setUp() public {
        ownable = new TwoUnequalOwnable(owner, backup);
    }

    function test_constructor() public view {
        assertEq(owner, ownable.owner());
        assertEq(backup, ownable.backup());
    }

    function test_changeBackup() public {
        vm.prank(owner);
        ownable.changeBackup(address(0x3));
        assertEq(address(0x3), ownable.backup());
    }

    function testFail_changeBackup_invalidCaller() public {
        vm.prank(address(0x3));
        ownable.changeBackup(address(0x4));
    }

    function testFail_changeBackup_invalidBackup() public {
        vm.prank(owner);
        ownable.changeBackup(address(0x0));
    }
}
