// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultisigWalletNonce} from "../src//MultisigWalletNonce.sol";

contract MultisigWalletNonceTest is Test {
    MultisigWalletNonce wallet;
    address public owner = address(0x2);
    address[4] public signers = [address(0x3), address(0x4), address(0x5), address(0x6)];
    address public newOwner = address(0x7);

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
        (bool success, ) = address(wallet).call{value: 100}("");
        assertTrue(success, "Call to receive function failed");
        assertEq(address(wallet).balance, 100);
    }

    function test_fallback() public {
        (bool success, ) = address(wallet).call{value: 100}("0x1234");
        assertTrue(success, "Call to fallback function failed");
        assertEq(address(wallet).balance, 100);
    }

    /* ********************************************************************** */
    /* Withdraw Functions                                                     */
    /* ********************************************************************** */

    /* ********************************************************************** */
    /* Withdraw All Functions                                                 */
    /* ********************************************************************** */


}