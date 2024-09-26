// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OwnableMultisig} from "../src/OwnableMultisigTest.sol";

contract OwnableMultisigTest is Test {
    OwnableMultisig public multisig;
    address public owner;
    address[4] public signers;

    address newOwner;

    function setUp() public {
        owner = address(this);
        signers[0] = address(0x010);
        signers[1] = address(0x02);
        signers[2] = address(0x03);
        signers[3] = address(0x04);
        newOwner = address(0x05);
        multisig = new OwnableMultisig(owner, signers);
    }

    /**
     * constructor
     */
    function test_constructor() public view {
        address[4] memory _signers = multisig.signers();
        assertEq(multisig.owner(), owner);
        assertEq(_signers[0], signers[0]);
        assertEq(_signers[1], signers[1]);
        assertEq(_signers[2], signers[2]);
        assertEq(_signers[3], signers[3]);
    }

    function testFail_constructor_invalidOwner0x0() public {
        new OwnableMultisig(address(0x0), signers);
    }

    function testFail_constructor_invalidOwner0x1() public {
        new OwnableMultisig(address(0x1), signers);
    }

    function testFail_constructor_invalidSigner0x0() public {
        address[4] memory _signers = signers;
        _signers[0] = address(0x0);
        new OwnableMultisig(owner, _signers);
    }

    function testFail_constructor_invalidSigner0x1() public {
        address[4] memory _signers = signers;
        _signers[0] = address(0x1);
        new OwnableMultisig(owner, _signers);
    }

    /**
     * transferOwnership
     */
    function test_transferOwnership_owner() public {
        multisig.transferOwnership(newOwner);
        assertEq(multisig.pendingOwner(), newOwner);
    }

    function test_transferOwnership_signer() public {
        vm.prank(signers[0]);
        multisig.transferOwnership(newOwner);
        assertEq(multisig.pendingOwner(), newOwner);
    }

    function test_transferOwnership_signerChangeInProgress() public {
        multisig.transferSignership(signers[0], newOwner);
        multisig.transferOwnership(address(0x06));
    }

    function testFail_transferOwnership_0x0() public {
        multisig.transferOwnership(address(0x0));
    }

    function testFail_transferOwnership_0x1() public {
        multisig.transferOwnership(address(0x1));
    }

    function testFail_transferOwnership_invalidCaller() public {
        vm.prank(newOwner);
        multisig.transferOwnership(address(0x06));
    }

    function testFail_transferOwnership_ownerChangeInProgress() public {
        multisig.transferOwnership(newOwner);
        multisig.transferOwnership(address(0x06));
    }

    /**
     * abortTransferOwnership
     */
    function test_abortTransferOwnership() public {
        multisig.transferOwnership(newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[1]);
        multisig.abortTransferOwnership();
        vm.prank(signers[2]);
        multisig.abortTransferOwnership();
        vm.prank(signers[3]);
        multisig.abortTransferOwnership();

        assertEq(multisig.pendingOwner(), address(0x1));
        assertEq(multisig.abortChangeOwnerBitmap(), 1);
        assertEq(multisig.changeOwnerBitmap(), 1);
    }

    function testFail_abortTransferOwnership_invalidCaller() public {
        multisig.transferOwnership(newOwner);
        vm.prank(newOwner);
        multisig.abortTransferOwnership();
    }

    function testFail_abortTransferOwnership_notProposed() public {
        multisig.abortTransferOwnership();
    }

    /**
     * confirmTransferOwnership
     */
    function test_confirmTransferOwnership() public {
        multisig.transferOwnership(newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferOwnership();
        assertEq(multisig.changeOwnerBitmap(), 7);
    }

    function test_confirmTransferOwnership_signerChangeInProgress() public {
        multisig.transferOwnership(newOwner);
        multisig.transferSignership(signers[0], newOwner);
        multisig.confirmTransferOwnership();
    }

    function testFail_confirmTransferOwnership_invalidCaller() public {
        multisig.transferOwnership(newOwner);
        vm.prank(newOwner);
        multisig.confirmTransferOwnership();
    }

    function testFail_confirmTransferOwnership_notProposed() public {
        multisig.confirmTransferOwnership();
    }

    /**
     * acceptOwnership
     */
    function test_acceptOwnership() public {
        multisig.transferOwnership(newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[1]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[2]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[3]);
        multisig.confirmTransferOwnership();
        vm.prank(newOwner);
        multisig.acceptOwnership();
        assertEq(multisig.owner(), newOwner);
    }

    function testFail_acceptOwnership_notEnoughSigners() public {
        multisig.transferOwnership(newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferOwnership();
        vm.prank(newOwner);
        multisig.acceptOwnership();
    }

    function testFail_accepOwnership_wrongCaller() public {
        multisig.transferOwnership(newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[1]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[2]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[3]);
        multisig.confirmTransferOwnership();
        vm.prank(signers[0]);
        multisig.acceptOwnership();
    }

    function testFail_acceptOwnership_notProposed() public {
        multisig.acceptOwnership();
    }

    /**
     * transferSignership
     */
    function test_transferSignership_owner() public {
        multisig.transferSignership(signers[0], newOwner);
        assertEq(multisig.pendingSigner(), newOwner);
    }

    function test_transferSignership_ownerChangeInProgress() public {
        multisig.transferOwnership(newOwner);
        multisig.transferSignership(signers[0], address(0x06));
    }

    function test_transferSignership_signer() public {
        vm.prank(signers[1]);
        multisig.transferSignership(signers[0], newOwner);
        assertEq(multisig.pendingSigner(), newOwner);
    }

    function testFail_transferSignership_0x0() public {
        multisig.transferSignership(signers[0], address(0x0));
    }

    function testFail_transferSignership_0x1() public {
        multisig.transferSignership(signers[0], address(0x1));
    }

    function testFail_transferSignership_invalidCaller() public {
        vm.prank(newOwner);
        multisig.transferSignership(signers[0], address(0x06));
    }

    function testFail_transferSignership_signerChangeInProgress() public {
        multisig.transferSignership(signers[0], newOwner);
        multisig.transferSignership(signers[1], address(0x06));
    }

    /**
     * abortTransferSignership
     */
    function test_abortTransferSignership() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferSignership();
        vm.prank(signers[1]);
        multisig.abortTransferSignership();
        vm.prank(signers[2]);
        multisig.abortTransferSignership();
        vm.prank(signers[3]);
        multisig.abortTransferSignership();
        assertEq(multisig.pendingSigner(), address(0x1));
        assertEq(multisig.abortChangeSignerBitmap(), 1);
        assertEq(multisig.changeSignerBitmap(), 1);
    }

    function testFail_abortTransferSignership_invalidCaller() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(newOwner);
        multisig.abortTransferSignership();
    }

    function testFail_abortTransferSignership_notProposed() public {
        multisig.abortTransferSignership();
    }

    /**
     * confirmTransferSignership
     */
    function test_confirmTransferSignership() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferSignership();
        assertEq(multisig.changeSignerBitmap(), 7);
    }

    function test_confirmTransferSignership_ownerChangeInProgress() public {
        multisig.transferSignership(signers[0], newOwner);
        multisig.transferOwnership(newOwner);
        multisig.confirmTransferSignership();
    }

    function testFail_confirmTransferSignership_invalidCaller() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(newOwner);
        multisig.confirmTransferSignership();
    }

    function testFail_confirmTransferSignership_notProposed() public {
        multisig.confirmTransferSignership();
    }

    /**
     * acceptSignership
     */
    function test_acceptSignership() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferSignership();
        vm.prank(signers[1]);
        multisig.confirmTransferSignership();
        vm.prank(newOwner);
        multisig.acceptSignership();
        assertEq(multisig.signers()[0], newOwner);
    }

    function test_acceptSignership_whileMaliciousOwnershipTransfer() public {
        vm.prank(signers[0]); // signer 0 is malicious
        multisig.transferOwnership(address(0x6));
        multisig.transferSignership(signers[0], newOwner);
        multisig.confirmTransferOwnership();
        vm.prank(signers[1]);
        multisig.confirmTransferSignership();
        vm.prank(signers[2]);
        multisig.confirmTransferSignership();
        vm.prank(signers[3]);
        multisig.confirmTransferSignership();
        vm.prank(newOwner);
        multisig.acceptSignership();

        assertEq(multisig.signers()[0], newOwner);
        assertEq(multisig.changeSignerBitmap(), 1);
        assertEq(multisig.changeOwnerBitmap(), 1);
    }

    function testFail_acceptSignership_notEnoughSigners() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferSignership();
        vm.prank(newOwner);
        multisig.acceptSignership();
    }

    function testFail_acceptSignership_wrongCaller() public {
        multisig.transferSignership(signers[0], newOwner);
        vm.prank(signers[0]);
        multisig.confirmTransferSignership();
        vm.prank(signers[1]);
        multisig.confirmTransferSignership();
        vm.prank(address(0x06));
        multisig.acceptSignership();
    }

    function testFail_acceptSignership_notProposed() public {
        multisig.acceptSignership();
    }

    /**
     * getters
     */
    function test__signerIndex() public view {
        assertEq(multisig._signerIndex(owner), 0);
    }

    function test__bitmapSigned() public view {
        assertEq(multisig._bitmapSigned(1, 1), false);
    }
}
