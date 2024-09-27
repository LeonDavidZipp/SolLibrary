// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultisigWalletNonce} from "../src//MultisigWalletNonce.sol";
import {OwnableMultisig} from "../src/OwnableMultisig.sol";

contract MultisigWalletNonceTest is Test {
    MultisigWalletNonce wallet;
    address public owner = address(this);
    address[4] public signers = [address(0x3), address(0x4), address(0x5), address(0x6)];
    address public newOwner = address(0x7);

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        wallet = new MultisigWalletNonce(owner, signers);
    }

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    function test_constructor() public view {
        address[4] memory _signers = wallet.signers();

        assertEq(wallet.owner(), owner);
        assertEq(_signers[0], signers[0]);
        assertEq(_signers[1], signers[1]);
        assertEq(_signers[2], signers[2]);
        assertEq(_signers[3], signers[3]);
    }

    /* ********************************************************************** */
    /* Fallback Functions                                                     */
    /* ********************************************************************** */
    function test_receive() public {
        (bool success,) = address(wallet).call{value: 100}("");
        assertTrue(success, "Call to receive function failed");
        assertEq(address(wallet).balance, 100);
    }

    function test_fallback() public {
        (bool success,) = address(wallet).call{value: 100}("0x1234");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(wallet).balance, 100);
    }

    /* ********************************************************************** */
    /* Withdraw Functions                                                     */
    /* ********************************************************************** */
    function test_proposeWithdraw() public {
        vm.expectEmit();
        emit MultisigWalletNonce.WithdrawalProposed(100);

        wallet.proposeWithdraw(100, 0);

        assertEq(wallet.amount(), 100);
    }

    function testFail_proposeWithdraw_alreadyProposed() public {
        wallet.proposeWithdraw(100, wallet.nonces(owner));
        wallet.proposeWithdraw(100, wallet.nonces(owner));
    }

    function testFail_proposeWithdraw_invalidCaller() public {
        vm.startPrank(address(0x111));
        wallet.proposeWithdraw(100, wallet.nonces(address(0x111)));
        vm.stopPrank();
    }

    function testFail_proposeWithdraw_notOwnerButSigner() public {
        vm.startPrank(signers[0]);
        wallet.proposeWithdraw(100, wallet.nonces(signers[0]));
        vm.stopPrank();
    }

    // tested in below tests
    function test_confirmWithdraw() public {}

    function testFail_confirmWithdraw_owner() public {
        wallet.proposeWithdraw(100, 0);
        wallet.confirmWithdraw(wallet.nonces(owner));
    }

    function testFail_confirmWithdraw_invalidCaller() public {
        wallet.proposeWithdraw(100, 0);
        vm.startPrank(address(0x111));
        wallet.confirmWithdraw(wallet.nonces(address(0x111)));
        vm.stopPrank();
    }

    function test_withdraw() public {
        (bool success,) = address(wallet).call{value: 1000}("");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(wallet).balance, 1000);

        wallet.proposeWithdraw(100, wallet.nonces(owner));
        assertEq(wallet.amount(), 100);

        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.startPrank(signers[1]);
        wallet.confirmWithdraw(wallet.nonces(signers[1]));
        vm.stopPrank();

        vm.expectEmit();
        emit MultisigWalletNonce.Withdrawal(100);

        wallet.withdraw(wallet.nonces(owner));
        assertEq(address(wallet).balance, 900);
    }

    function test_withdraw_allSigned() public {
        (bool success,) = address(wallet).call{value: 1000}("");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(wallet).balance, 1000);

        wallet.proposeWithdraw(100, wallet.nonces(owner));
        assertEq(wallet.amount(), 100);

        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.startPrank(signers[1]);
        wallet.confirmWithdraw(wallet.nonces(signers[1]));
        vm.startPrank(signers[2]);
        wallet.confirmWithdraw(wallet.nonces(signers[2]));
        vm.startPrank(signers[3]);
        wallet.confirmWithdraw(wallet.nonces(signers[3]));
        vm.stopPrank();

        vm.expectEmit();
        emit MultisigWalletNonce.Withdrawal(100);

        wallet.withdraw(wallet.nonces(owner));
        assertEq(address(wallet).balance, 900);
    }

    function testFail_withdraw_notEnoughSigned() public {
        (bool success,) = address(wallet).call{value: 1000}("");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(wallet).balance, 1000);

        wallet.proposeWithdraw(100, wallet.nonces(owner));
        assertEq(wallet.amount(), 100);

        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.stopPrank();

        wallet.withdraw(wallet.nonces(owner));
    }

    function testFail_withdraw_insufficientBalance() public {
        wallet.proposeWithdraw(10000, wallet.nonces(owner));
        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.startPrank(signers[1]);
        wallet.confirmWithdraw(wallet.nonces(signers[1]));
        vm.startPrank(signers[2]);
        wallet.confirmWithdraw(wallet.nonces(signers[2]));
        vm.startPrank(signers[3]);
        wallet.confirmWithdraw(wallet.nonces(signers[3]));
        vm.stopPrank();

        wallet.withdraw(wallet.nonces(owner));
    }

    function testFail_withdraw_notProposed() public {
        wallet.proposeWithdraw(10000, wallet.nonces(owner));
        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.startPrank(signers[1]);
        wallet.confirmWithdraw(wallet.nonces(signers[1]));
        vm.startPrank(signers[2]);
        wallet.confirmWithdraw(wallet.nonces(signers[2]));
        vm.startPrank(signers[3]);
        wallet.confirmWithdraw(wallet.nonces(signers[3]));
        vm.stopPrank();

        wallet.withdraw(wallet.nonces(owner));
    }

    function testFail_withdraw_invalidNonce() public {
        wallet.proposeWithdraw(10000, wallet.nonces(owner));
        vm.startPrank(signers[0]);
        wallet.confirmWithdraw(wallet.nonces(signers[0]));
        vm.startPrank(signers[1]);
        wallet.confirmWithdraw(wallet.nonces(signers[1]));
        vm.startPrank(signers[2]);
        wallet.confirmWithdraw(wallet.nonces(signers[2]));
        vm.startPrank(signers[3]);
        wallet.confirmWithdraw(wallet.nonces(signers[3]));
        vm.stopPrank();

        wallet.withdraw(wallet.nonces(owner) + 1);
    }
}
