// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title TwoUnequalOwnable
 * @dev Contract module which provides two owners access control mechanism,
 *      where owner has more power than backup, but backup can block owner.
 */
contract TwoUnequalOwnable is Context {
    address internal immutable _owner;
    address internal _backup;

    error Unauthorized(address account);
    error InvalidAddress();

    modifier onlyOwner() {
        address sender = _msgSender();
        if (sender != owner()) {
            revert Unauthorized(sender);
        }
        _;
    }

    modifier onlyBackup() {
        address sender = _msgSender();
        if (sender != backup()) {
            revert Unauthorized(sender);
        }
        _;
    }

    modifier onlyOwners() {
        address sender = _msgSender();
        if (sender != owner() && sender != backup()) {
            revert Unauthorized(sender);
        }
        _;
    }

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address initialBackup) payable {
        _owner = initialOwner;
        assembly {
            sstore(_backup.slot, initialBackup)
        }
    }

    /* ********************************************************************** */
    /* Getters                                                                */
    /* ********************************************************************** */
    function owner() public view returns (address a) {
        a = _owner;
    }

    function backup() public view returns (address a) {
        assembly {
            a := sload(_backup.slot)
        }
    }

    /* ********************************************************************** */
    /* Owner functions                                                        */
    /* ********************************************************************** */
    function changeBackup(address newBackup) external onlyOwner {
        if (newBackup == address(0)) {
            revert InvalidAddress();
        }

        assembly {
            sstore(_backup.slot, newBackup)
        }
    }
}
