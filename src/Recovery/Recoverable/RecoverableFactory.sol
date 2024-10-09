// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultisigWalletNonce} from "multisig/MultisigWalletNonce.sol";
import {Recoverable} from "./Recoverable.sol";

contract RecoverableFactory is MultisigWalletNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 private _fee; // 0.025 ether for now
    address[] private _recoveries; // recovery contracts
    mapping(address => address) private _recoveryMap; // owner => recovery contract

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event RecoveryCreated(address indexed owner, address indexed backup, address recovery);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error InsufficientFee();
    error RecoveryExists(address owner, address recovery);

    /* ********************************************************************** */
    /* Fallback Functions                                                     */
    /* ********************************************************************** */
    // receive() external payable {}

    // fallback() external payable {}

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address[4] memory initialSigners, uint256 initialFee)
        payable
        MultisigWalletNonce(initialOwner, initialSigners)
    {
        assembly {
            sstore(_fee.slot, initialFee)
        }
    }

    /* ********************************************************************** */
    /* Recovery Functions                                                     */
    /* ********************************************************************** */
    function createRecovery(address initialBackup, uint256 nonce) external payable returns (address recoveryAddr) {
        if (msg.value < fee()) {
            revert InsufficientFee();
        }

        if (initialBackup == address(0)) {
            revert InvalidAddress(initialBackup);
        }
        address owner_ = _msgSender();
        if (recoveryAddress(owner_) != address(0)) {
            revert RecoveryExists(owner_, recoveryAddress(owner_));
        }

        Recoverable recovery = new Recoverable(owner_, initialBackup);

        recoveryAddr = address(recovery);
        _recoveries.push(recoveryAddr);
        _recoveryMap[owner_] = recoveryAddr;

        emit RecoveryCreated(owner_, initialBackup, recoveryAddr);

        _useCheckedNonce(owner_, nonce);

        return recoveryAddr;
    }

    function recoveryAddresses() public view returns (address[] memory r) {
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

    function setFee(uint256 newFee, uint256 nonce) external onlyOwner notBlocked {
        assembly {
            sstore(_fee.slot, newFee)
        }

        _useCheckedNonce(owner(), nonce);
    }
}
