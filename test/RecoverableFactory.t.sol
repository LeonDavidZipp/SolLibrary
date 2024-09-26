// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RecoverableFactory} from "../src/RecoverableFactory.sol";

contract RecoverableFactoryTest is Test {
    address[4] signers = [address(0x4), address(0x5), address(0x6), address(0x7)];
    address owner = address(0x3);

    address recoverableOwner = address(0x1);
    address recoverableBackup = address(0x2);
    uint256 fee = 0.025 ether;
    RecoverableFactory public recoverableFactory;

    function setUp() public {
        recoverableFactory = new RecoverableFactory(owner, signers, fee);
    }

    function test_constructor() public view {
        assertEq(fee, recoverableFactory.fee());
    }

    function test_setFee() public {
        uint256 newFee = 0.05 ether;
        vm.startPrank(owner);
        recoverableFactory.setFee(newFee, recoverableFactory.nonces(owner));
        assertEq(newFee, recoverableFactory.fee());
    }

    function testFail_setFee_notOwner() public {
        uint256 newFee = 0.05 ether;
        vm.startPrank(owner);
        recoverableFactory.setFee(newFee, recoverableFactory.nonces(owner));
        vm.stopPrank();
    }

    function testFail_setFee_blocked() public {
        vm.startPrank(signers[0]);
        recoverableFactory.blockNonce(recoverableFactory.nonces(owner));
        recoverableFactory.setFee(0.05 ether, recoverableFactory.nonces(owner));
        vm.stopPrank();
    }
}
