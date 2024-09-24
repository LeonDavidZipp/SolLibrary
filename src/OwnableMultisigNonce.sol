// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { OwnableMultisig } from "./OwnableMultisig.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title Multisig
 * @dev Contract module which provides multisig access control mechanism.
 * 1 owner and 4 signers are required to sign important transactions.
 * The initial owner is specified at deployment time in the constructor for `Ownable`.
 * The initial signers are specified at deployment time as well.
 * This module is used through inheritance. It will make available all functions from parent (Ownable2Step & Ownable).
 *
 * General flow:
 * Owner change:
 * 1. The owner or any signer proposes a new owner.
 * 2. At least 4 confirmations from any signers including the owner are required.
 * 3. The new owner accepts the proposal.
 *
 * Signer change:
 * 1. The owner or any signer proposes a new signer.
 * 2. At least 3 confirmations from any signers including the owner are required.
 * 3. The new signer accepts the proposal.
 *
 * Blocking:
 * 1. Any signer including the owner can block the contract.
 * 2. To unblock the contract, at least 4 confirmations from any signers including the owner are required.
 * 3. As the last of 4 signers confirms unblocking, the contract is unblocked.
 */
contract OwnableMultisigNonce is OwnableMultisig, Nonces {
    address private _owner; // owner of contract
    bool private _isBlocked; // flag to block everything until set to false again
    uint8 private _unblockBitmap; // bitmap for the unblock transaction
    address private _pendingOwner; // the address of the pending owner
    uint8 private _changeOwnerBitmap; // bitmap for the change owner transaction
    uint8 private _abortChangeOwnerBitmap; // bitmap for the abort change owner transaction
    uint8 private _changeSignerBitmap; // bitmap for the change signer transaction
    uint8 private _abortChangeSignerBitmap; // bitmap for the abort change signer transaction
    uint8 private _replacedSignerIndex; // the index of the replaced signer
    address private _pendingSigner; // the address of the pending signer
    address[4] private _signers; // An array of addresses required to sign important transactions.

    constructor(
        address initialOwner,
        address[4] memory initialSigners
    )
        payable
        OwnableMultisig(initialOwner, initialSigners)
        validAddress(initialOwner)
        validAddress(initialSigners[0])
        validAddress(initialSigners[1])
        validAddress(initialSigners[2])
        validAddress(initialSigners[3])
    {
        _signers = initialSigners;
        _pendingOwner = address(0x1);
        _pendingSigner = address(0x1);
        _changeOwnerBitmap = 1; // for gas saving
        _changeSignerBitmap = 1; // for gas saving
        _isBlocked = false;
        _unblockBitmap = 1;
    }

    /**
     * proposes a new owner change transaction by the owner.
     * @param newOwner: the address of the new owner
     */
    function transferOwnershipNonce(address newOwner, uint256 nonce) external {
        transferOwnership(newOwner);
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * aborts the owner change transaction.
     * everyone who previously voted for the change must call this function.
     */
    function abortTransferOwnershipNonce(uint256 nonce) external {
        abortTransferOwnership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * confirms the owner change transaction for the given caller if it is signer.
     */
    function confirmTransferOwnershipNonce(uint256 nonce) external virtual {
        confirmTransferOwnership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     * the bitmap is reset to 1.
     */
    function acceptOwnershipNonce(uint256 nonce) external {
        acceptOwnership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * proposes a new signer change transaction.
     * @param newSigner: the address of the new signer
     */
    function transferSignershipNonce(
        address oldSigner,
        address newSigner,
        uint256 nonce
    ) external {
        transferSignership(oldSigner, newSigner);
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * aborts the signer change transaction.
     */
    function abortTransferSignershipNonce(uint256 nonce) external {
        abortTransferSignership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * confirms the signer change transaction for the given caller if it is signer.
     */
    function confirmTransferSignershipNonce(uint256 nonce) external {
        confirmTransferSignership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * @dev The new signer accepts the signership transfer.
     * The bitmap is reset to 1.
     */
    function acceptSignershipNonce(uint256 nonce) external {
        acceptSignership();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * blocks the contract from executing frequent transactions until unblocked.
     */
    function blockNonce(uint256 nonce) external {
        _block();
        _useCheckedNonce(_msgSender(), nonce);
    }

    /**
     * unblocks the contract from executing any transactions.
     */
    function unblockNonce(uint256 nonce) external {
        _unblock();
        _useCheckedNonce(_msgSender(), nonce);
    }
}
