// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OwnableMultisigNonce} from "../src/OwnableMultisigNonce.sol";

contract OwnableMultisigTest is Test {
    OwnableMultisigNonce public multisig;
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
        multisig = new OwnableMultisigNonce(owner, signers);
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

    /**
     * blockNonce
     */
    function test_blockNonce() public {
        multisig.blockNonce(multisig.nonces(owner));
        assertEq(multisig.isBlocked(), true);
    }

    function testFail_blockNonce_invalidCaller() public {
        vm.startPrank(address(0x06));
        multisig.blockNonce(multisig.nonces(address(0x06)));
        vm.stopPrank();
    }

    /**
     * unblockNonce
     */
    function test_unblockNonce() public {
        multisig.blockNonce(multisig.nonces(owner));
        multisig.unblockNonce(multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.unblockNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(signers[1]);
        multisig.unblockNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        // vm.startPrank(signers[2]);
        // multisig.unblockNonce(multisig.nonces(signers[2]));
        // vm.stopPrank();
        assertEq(multisig.isBlocked(), false);
    }

    function testFail_unblockNonce_invalidCaller() public {
        multisig.blockNonce(multisig.nonces(owner));
        vm.startPrank(address(0x06));
        multisig.unblockNonce(multisig.nonces(address(0x06)));
        vm.stopPrank();
    }

    /**
     * transferOwnership
     */
    function testFail_transferOwnershipNonce_replayAttack() public {
        uint256 nonce = multisig.nonces(owner);
        multisig.transferOwnershipNonce(newOwner, nonce);
        multisig.transferOwnershipNonce(newOwner, nonce);
    }

    /**
     * abortTransferOwnership
     */
    function testFail_abortTransferOwnershipNonce_replayAttack() public {
        multisig.transferOwnershipNonce(newOwner, multisig.nonces(owner));
        uint256 nonce = multisig.nonces(owner);
        multisig.abortTransferOwnershipNonce(nonce);
        multisig.abortTransferOwnershipNonce(nonce);
    }

    /**
     * confirmTransferOwnership
     */
    function testFail_confirmTransferOwnershipNonce_replayAttack() public {
        uint256 nonce = multisig.nonces(signers[0]);
        multisig.transferOwnershipNonce(newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferOwnershipNonce(nonce);
        multisig.confirmTransferOwnershipNonce(nonce);
        vm.stopPrank();
    }

    /**
     * acceptOwnership
     */
    function testFail_acceptOwnership_replayAttack() public {
        multisig.transferOwnershipNonce(newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferOwnershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(signers[1]);
        multisig.confirmTransferOwnershipNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        vm.startPrank(signers[2]);
        multisig.confirmTransferOwnershipNonce(multisig.nonces(signers[2]));
        vm.stopPrank();
        vm.startPrank(newOwner);
        uint256 nonce = multisig.nonces(newOwner);
        multisig.acceptOwnershipNonce(nonce);
        multisig.acceptOwnershipNonce(nonce);
        vm.stopPrank();
    }

    /**
     * transferSignershipNonce
     */
    function test_transferSignershipNonce_owner() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        assertEq(multisig.pendingSigner(), newOwner);
    }

    function test_transferSignershipNonce_ownerChangeInProgress() public {
        multisig.transferOwnershipNonce(newOwner, multisig.nonces(owner));
        multisig.transferSignershipNonce(signers[0], address(0x06), multisig.nonces(owner));
    }

    function test_transferSignershipNonce_signer() public {
        vm.prank(signers[1]);
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(signers[1]));
        assertEq(multisig.pendingSigner(), newOwner);
    }

    function testFail_transferSignershipNonce_0x0() public {
        multisig.transferSignershipNonce(signers[0], address(0x0), multisig.nonces(owner));
    }

    function testFail_transferSignershipNonce_0x1() public {
        multisig.transferSignershipNonce(signers[0], address(0x1), multisig.nonces(owner));
    }

    function testFail_transferSignershipNonce_invalidCaller() public {
        vm.startPrank(newOwner);
        multisig.transferSignershipNonce(signers[0], address(0x06), multisig.nonces(newOwner));
        vm.stopPrank();
    }

    function testFail_transferSignershipNonce_signerChangeInProgress() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        multisig.transferSignershipNonce(signers[1], address(0x06), multisig.nonces(owner));
    }

    /**
     * abortTransferSignership
     */
    function test_abortTransferSignership() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(signers[1]);
        multisig.abortTransferSignershipNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        vm.startPrank(signers[2]);
        multisig.abortTransferSignershipNonce(multisig.nonces(signers[2]));
        vm.stopPrank();
        vm.startPrank(signers[3]);
        multisig.abortTransferSignershipNonce(multisig.nonces(signers[3]));
        vm.stopPrank();
        assertEq(multisig.pendingSigner(), address(0x1));
    }

    function testFail_abortTransferSignership_invalidCaller() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(newOwner);
        multisig.abortTransferSignershipNonce(multisig.nonces(owner));
        vm.stopPrank();
    }

    function testFail_abortTransferSignership_notProposed() public {
        multisig.abortTransferSignershipNonce(multisig.nonces(owner));
    }

    /**
     * confirmTransferSignership
     */
    function test_confirmTransferSignership() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        assertEq(multisig.changeSignerBitmap(), 7);
    }

    function test_confirmTransferSignership_ownerChangeInProgress() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        multisig.transferOwnershipNonce(newOwner, multisig.nonces(owner));
        multisig.confirmTransferSignershipNonce(multisig.nonces(owner));
    }

    function testFail_confirmTransferSignership_invalidCaller() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(newOwner);
        multisig.confirmTransferSignershipNonce(multisig.nonces(newOwner));
        vm.stopPrank();
    }

    function testFail_confirmTransferSignership_notProposed() public {
        multisig.confirmTransferSignershipNonce(multisig.nonces(owner));
    }

    /**
     * acceptSignership
     */
    function test_acceptSignership() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(signers[1]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        vm.startPrank(newOwner);
        multisig.acceptSignershipNonce(multisig.nonces(newOwner));
        vm.stopPrank();
        assertEq(multisig.signers()[0], newOwner);
    }

    function test_acceptSignership_whileMaliciousOwnershipTransfer() public {
        vm.startPrank(signers[0]); // signer 0 is malicious
        multisig.transferOwnershipNonce(address(0x6), multisig.nonces(signers[0]));
        vm.stopPrank();
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        multisig.confirmTransferOwnershipNonce(multisig.nonces(owner));
        vm.startPrank(signers[1]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        vm.startPrank(signers[2]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[2]));
        vm.stopPrank();
        vm.startPrank(signers[3]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[3]));
        vm.stopPrank();
        vm.startPrank(newOwner);
        multisig.acceptSignershipNonce(multisig.nonces(newOwner));
        vm.stopPrank();

        assertEq(multisig.signers()[0], newOwner);
        assertEq(multisig.changeSignerBitmap(), 1);
        assertEq(multisig.changeOwnerBitmap(), 1);
    }

    function testFail_acceptSignership_notEnoughSigners() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(newOwner);
        multisig.acceptSignershipNonce(multisig.nonces(newOwner));
        vm.stopPrank();
    }

    function testFail_acceptSignership_wrongCaller() public {
        multisig.transferSignershipNonce(signers[0], newOwner, multisig.nonces(owner));
        vm.startPrank(signers[0]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[0]));
        vm.stopPrank();
        vm.startPrank(signers[1]);
        multisig.confirmTransferSignershipNonce(multisig.nonces(signers[1]));
        vm.stopPrank();
        vm.startPrank(address(0x06));
        multisig.acceptSignershipNonce(multisig.nonces(address(0x06)));
        vm.stopPrank();
    }

    function testFail_acceptSignership_notProposed() public {
        multisig.acceptSignershipNonce(multisig.nonces(owner));
    }
}
