// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableMultisigNonce} from "./OwnableMultisigNonce.sol";
import {Recovery} from "./Recovery.sol";

contract RecoveryFactory is OwnableMultisigNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 private _fee;
    address[] private _recoveries;
    mapping(address => address) private _recoveryMap;

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event RecoveryCreated(address indexed owner, address indexed backup, address recovery);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error InsufficientFee();

    /* ********************************************************************** */
    /* Fallback Functions                                                     */
    /* ********************************************************************** */
    receive() external payable {}

    fallback() external payable {}

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address[4] memory initialSigners, uint256 fee)
        payable
        OwnableMultisigNonce(initialOwner, initialSigners)
    {
        _fee = fee;
    }

    /* ********************************************************************** */
    /* Recovery Functions                                                     */
    /* ********************************************************************** */
    function createRecovery(
        address initialOwner,
        address initialBackup,
        Recovery.PermitBatch calldata permitBatch,
        bytes calldata signature,
        uint256 nonce
    ) external payable {
        if (msg.amount < fee()) {
            revert InsufficientFee();
        }
        if (initialOwner == address(0)) {
            revert InvalidAddress();
        }
        if (initialBackup == address(0)) {
            revert InvalidAddress();
        }
        if (recoveryAddress(initialOwner) != address(0)) {
            revert RecoveryExists(initialOwner, recoveryAddress(initialOwner));
        }

        Recovery recovery = new Recovery(initialOwner, initialBackup, permitBatch, signature);

        address newAddr = address(recovery);
        _recoveries.push(newAddr);
        _recoveryMap[initialOwner] = newAddr;

        emit RecoveryCreated(initialOwner, initialBackup, newAddr);

        _useCheckedNonce(_msgSender(), nonce);
    }

    function recoverieAddresses() public view returns (address[] memory r) {
        r = _recoveries;
    }

    function recoveryCount() public view returns (uint256 c) {
        c = _recoveries.length;
    }

    function recoveryAddress(address owner) public view returns (address r) {
        r = _recoveryMap[owner];
    }

    /* ********************************************************************** */
    /* Fee Functions                                                          */
    /* ********************************************************************** */
    function fee() public view returns (uint256 f) {
        assembly {
            f := sload(_fee.slot)
        }
    }

    function setFee(uint256 fee) external onlyOwner {
        assembly {
            sstore(_fee.slot, fee)
        }
    }

    function withdrawBalance(address payable to) external onlyOwner {
        to.transfer(address(this).balance - 21000);
    }
}
