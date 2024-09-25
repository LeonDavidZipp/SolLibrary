// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableMultisigNonce} from "./OwnableMultisigNonce.sol";
import {Recoverable} from "./Recoverable.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

contract RecoverableFactory is OwnableMultisigNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 private _fee;
    uint256 private _gasLimit;
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
    error InvalidAddress();
    error RecoveryExists(address owner, address recovery);

    /* ********************************************************************** */
    /* Fallback Functions                                                     */
    /* ********************************************************************** */
    receive() external payable {}

    fallback() external payable {}

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address[4] memory initialSigners, uint256 initialFee, uint256 initialGasLimit)
        payable
        OwnableMultisigNonce(initialOwner, initialSigners)
    {
        _fee = initialFee;
        _gasLimit = initialGasLimit;
    }

    /* ********************************************************************** */
    /* Recovery Functions                                                     */
    /* ********************************************************************** */
    function createRecovery(
        address initialOwner,
        address initialBackup,
        IAllowanceTransfer.PermitBatch calldata permitBatch,
        bytes calldata signature,
        uint256 nonce
    ) external payable {
        if (msg.value < fee()) {
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

        Recoverable recovery = new Recoverable(initialOwner, initialBackup, permitBatch, signature);

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

    function setFee(uint256 newFee) external onlyOwner {
        assembly {
            sstore(_fee.slot, newFee)
        }
    }

    /* ********************************************************************** */
    /* Withdraw Functions                                                     */
    /* ********************************************************************** */
    function withdrawBalance(address to) external onlyOwner {
        payable(to).transfer(address(this).balance - gasLimit());
    }

    function gasLimit() public view returns (uint256 g) {
        assembly {
            g := sload(_gasLimit.slot)
        }
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        assembly {
            sstore(_gasLimit.slot, newGasLimit)
        }
    }
}
