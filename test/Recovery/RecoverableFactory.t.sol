// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RecoverableFactory} from "recoverable/RecoverableFactory.sol";

contract RecoverableFactoryTest is Test {
    address[4] signers = [address(0x4), address(0x5), address(0x6), address(0x7)];
    address owner = address(0x3);

    address recoverableOwner = address(this);
    address recoverableBackup = address(0x2);
    uint256 fee = 0.025 ether;
    RecoverableFactory public recoverableFactory;

    function setUp() public {
        recoverableFactory = new RecoverableFactory(owner, signers, fee);
    }

    function test_constructor() public view {
        address[4] memory _signers = recoverableFactory.signers();

        assertEq(owner, recoverableFactory.owner());
        assertEq(signers[0], _signers[0]);
        assertEq(signers[1], _signers[1]);
        assertEq(signers[2], _signers[2]);
        assertEq(signers[3], _signers[3]);
        assertEq(fee, recoverableFactory.fee());
    }

    function test_receive() public {
        (bool success,) = address(recoverableFactory).call{value: 100}("");
        assertTrue(success, "Call to receive function failed");
        assertEq(address(recoverableFactory).balance, 100);
    }

    function test_fallback() public {
        (bool success,) = address(recoverableFactory).call{value: 100}("0x1234");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(recoverableFactory).balance, 100);
    }

    function test_setFee() public {
        uint256 newFee = 0.05 ether;
        vm.startPrank(owner);
        recoverableFactory.setFee(newFee, recoverableFactory.nonces(owner));
        assertEq(newFee, recoverableFactory.fee());
    }

    function testFail_setFee_notOwner() public {
        uint256 newFee = 0.05 ether;
        vm.startPrank(signers[0]);
        recoverableFactory.setFee(newFee, recoverableFactory.nonces(signers[0]));
        vm.stopPrank();
    }

    function testFail_setFee_blocked() public {
        vm.startPrank(owner);
        recoverableFactory.blockNonce(recoverableFactory.nonces(owner));
        recoverableFactory.setFee(0.05 ether, recoverableFactory.nonces(owner));
        vm.stopPrank();
    }

    function test_createRecovery() public {
        (bool success,) = address(recoverableFactory).call{value: 1 ether}("");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(recoverableFactory).balance, 1 ether);

        vm.startPrank(recoverableOwner);
        address recovery = recoverableFactory.createRecovery{value: recoverableFactory.fee()}(
            recoverableBackup, recoverableFactory.nonces(recoverableOwner)
        );
        vm.stopPrank();

        assertEq(recovery, recoverableFactory.recoveryAddress(recoverableOwner));
        assertEq(
            recoverableFactory.recoveryAddress(recoverableOwner),
            recoverableFactory.recoveryAddresses()[recoverableFactory.recoveryAddresses().length - 1]
        );
    }
}
