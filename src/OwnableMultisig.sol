// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title Multisig
 * @dev Contract module which provides multisig access control mechanism.
 * 1 owner and 4 signers are required to sign important transactions.
 * The initial owner is specified at deployment time in the constructor for `Ownable`.
 * The initial signers are specified at deployment time as well.
 * This module is used through inheritance. It will make available all functions from parent (Ownable2Step & Ownable).
 * As many functions as possible are public, to force nonce protection in the derived contracts.
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
contract OwnableMultisig is Context {
    address private _owner; // owner of contract
    address private _pendingOwner; // the address of the pending owner
    bool private _isBlocked; // flag to block everything until set to false again
    uint256 private _unblockBitmap; // bitmap for the unblock transaction
    uint256 private _changeOwnerBitmap; // bitmap for the change owner transaction
    uint256 private _abortChangeOwnerBitmap; // bitmap for the abort change owner transaction
    uint256 private _changeSignerBitmap; // bitmap for the change signer transaction
    uint256 private _abortChangeSignerBitmap; // bitmap for the abort change signer transaction
    uint256 private _replacedSignerIndex; // the index of the replaced signer
    address private _pendingSigner; // the address of the pending signer
    address[4] private _signers; // An array of addresses required to sign important transactions.

    event OwnerChangeProposed(address indexed by, address indexed newOwner);
    event OwnerChangeConfirmed(address indexed by);
    event OwnerChangeRetracted(address indexed by);
    event OwnerChangeAborted();
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event SignerChangeProposed(address indexed by, address indexed replacedSigner, address indexed newSigner);
    event SignerChangeConfirmed(address indexed by);
    event SignerChangeRetracted(address indexed by);
    event SignerChangeAborted();
    event SignerChanged(address indexed replacedSigner, address indexed newSigner);
    event ContractBlocked(address indexed by);
    event ContractUnblockConfirmed(address indexed by);
    event ContractUnblocked();

    error UnauthorizedAccount(address account);
    error InvalidOwner(address owner);
    error InvalidOwnerCount();
    error OwnerChangeNotProposed();
    error OwnerChangeInProgress();
    error SignerChangeNotProposed();
    error SignerChangeInProgress();
    error NotEnoughSignatures();
    error Blocked();
    error NotBlocked();
    error AlreadyBlocked();

    modifier onlyOwner() {
        address sender = _msgSender();
        if (sender != owner()) {
            revert UnauthorizedAccount(sender);
        }
        _;
    }

    modifier notBlocked() {
        if (isBlocked()) {
            revert Blocked();
        }
        _;
    }

    modifier validAddress(address account) {
        if (account == address(0)) {
            revert InvalidOwner(account);
        }
        if (account == address(0x1)) {
            revert InvalidOwner(account);
        }
        _;
    }

    constructor(address initialOwner, address[4] memory initialSigners)
        payable
        validAddress(initialOwner)
        validAddress(initialSigners[0])
        validAddress(initialSigners[1])
        validAddress(initialSigners[2])
        validAddress(initialSigners[3])
    {
        _owner = initialOwner;
        _signers = initialSigners;
        _pendingOwner = address(0x1);
        _pendingSigner = address(0x1);
        _changeOwnerBitmap = 1; // for gas saving
        _abortChangeOwnerBitmap = 1; // for gas saving
        _changeSignerBitmap = 1; // for gas saving
        _abortChangeSignerBitmap = 1; // for gas saving
        _isBlocked = false;
        _unblockBitmap = 1;
    }

    /**
     * getters
     */
    function owner() public view returns (address a) {
        assembly {
            a := sload(_owner.slot)
        }
    }

    function changeOwnerBitmap() public view returns (uint256 i) {
        assembly {
            i := sload(_changeOwnerBitmap.slot)
        }
    }

    function abortChangeOwnerBitmap() public view returns (uint256 i) {
        assembly {
            i := sload(_abortChangeOwnerBitmap.slot)
        }
    }

    function changeSignerBitmap() public view returns (uint256 i) {
        assembly {
            i := sload(_changeSignerBitmap.slot)
        }
    }

    function abortChangeSignerBitmap() public view returns (uint256 i) {
        assembly {
            i := sload(_abortChangeSignerBitmap.slot)
        }
    }

    function replacedSignerIndex() internal view returns (uint256 i) {
        assembly {
            i := sload(_replacedSignerIndex.slot)
        }
    }

    function replacedSigner() public view returns (address s) {
        assembly {
            let i := sload(_replacedSignerIndex.slot)
            if gt(i, 3) { revert(0, 0) }
            s := sload(add(_signers.slot, i))
        }
    }

    function pendingOwner() public view returns (address a) {
        assembly {
            a := sload(_pendingOwner.slot)
        }
    }

    function pendingSigner() public view returns (address a) {
        assembly {
            a := sload(_pendingSigner.slot)
        }
    }

    function signers() public view returns (address[4] memory) {
        return _signers;
    }

    function isBlocked() public view returns (bool b) {
        assembly {
            b := sload(_isBlocked.slot)
        }
    }

    function unblockBitmap() internal view returns (uint256 i) {
        assembly {
            i := sload(_unblockBitmap.slot)
        }
    }

    /**
     * proposes a new owner change transaction by the owner.
     * @param newOwner: the address of the new owner
     * visibility public because of parent contract.
     */
    function transferOwnership(address newOwner) internal virtual validAddress(newOwner) {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        uint256 bm = changeOwnerBitmap();
        if (bm != 1) {
            revert OwnerChangeInProgress();
        }

        assembly {
            sstore(_pendingOwner.slot, newOwner)
            sstore(_changeOwnerBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }

        emit OwnerChangeProposed(sender, newOwner);
    }

    /**
     * aborts the owner change transaction.
     * Needs 3 votes to abort the transaction.
     */
    function abortTransferOwnership() internal virtual {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        if (changeOwnerBitmap() == 1) {
            revert OwnerChangeNotProposed();
        }

        uint256 bm;
        assembly {
            bm := sload(_abortChangeOwnerBitmap.slot)
            bm := or(bm, shl(add(i, 1), 1))
        }
        emit OwnerChangeRetracted(sender);

        if (_bitmapSigned(bm, 3)) {
            assembly {
                sstore(_pendingOwner.slot, 1)
                sstore(_changeOwnerBitmap.slot, 1)
                sstore(_abortChangeOwnerBitmap.slot, 1)
            }
            emit OwnerChangeAborted();
        } else {
            assembly {
                sstore(_abortChangeOwnerBitmap.slot, bm)
            }
        }
    }

    /**
     * confirms the owner change transaction for the given caller if it is signer.
     */
    function confirmTransferOwnership() internal virtual {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        uint256 bm = changeOwnerBitmap();
        if (bm <= 1) {
            revert OwnerChangeNotProposed();
        }

        assembly {
            sstore(_changeOwnerBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }
        emit OwnerChangeConfirmed(sender);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     * the bitmap is reset to 1.
     * visibility public because of parent contract.
     */
    function acceptOwnership() internal virtual {
        address sender = _msgSender();
        address newOwner = pendingOwner();
        if (newOwner != sender) {
            revert UnauthorizedAccount(sender);
        }
        if (_bitmapSigned(changeOwnerBitmap(), 3) == false) {
            revert NotEnoughSignatures();
        }

        address oldOwner;
        assembly {
            oldOwner := sload(_owner.slot)
            sstore(_owner.slot, newOwner)
            sstore(_pendingOwner.slot, 1)
            sstore(_changeOwnerBitmap.slot, 1)
            sstore(_changeSignerBitmap.slot, 1)
        }
        emit OwnerChanged(oldOwner, sender);
    }

    /**
     * proposes a new signer change transaction.
     * @param newSigner: the address of the new signer
     */
    function transferSignership(address oldSigner, address newSigner)
        internal
        virtual
        validAddress(oldSigner)
        validAddress(newSigner)
    {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        if (changeSignerBitmap() != 1) {
            revert SignerChangeInProgress();
        }

        uint256 iS = _signerIndex(oldSigner);
        if (iS == 0) {
            revert UnauthorizedAccount(oldSigner);
        }
        assembly {
            sstore(_replacedSignerIndex.slot, sub(iS, 1))
            sstore(_pendingSigner.slot, newSigner)
            let bm := sload(_changeSignerBitmap.slot)
            sstore(_changeSignerBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }
        emit SignerChangeProposed(sender, oldSigner, newSigner);
    }

    /**
     * aborts the signer change transaction.
     * Needs 3 votes to abort the transaction.
     */
    function abortTransferSignership() internal virtual {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        if (changeSignerBitmap() == 1) {
            revert SignerChangeNotProposed();
        }

        uint256 bm;
        assembly {
            bm := sload(_abortChangeSignerBitmap.slot)
            bm := or(bm, shl(add(i, 1), 1))
        }
        emit SignerChangeRetracted(sender);

        if (_bitmapSigned(bm, 3)) {
            assembly {
                sstore(_replacedSignerIndex.slot, 5)
                sstore(_pendingSigner.slot, 1)
                sstore(_changeSignerBitmap.slot, 1)
                sstore(_abortChangeSignerBitmap.slot, 1)
            }
            emit SignerChangeAborted();
        } else {
            assembly {
                sstore(_abortChangeSignerBitmap.slot, bm)
            }
        }
    }

    /**
     * confirms the signer change transaction for the given caller if it is signer.
     */
    function confirmTransferSignership() internal virtual {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        uint256 bm = changeSignerBitmap();
        if (bm <= 1) {
            revert SignerChangeNotProposed();
        }

        assembly {
            sstore(_changeSignerBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }
        emit SignerChangeConfirmed(sender);
    }

    /**
     * @dev The new signer accepts the signership transfer.
     * The bitmap is reset to 1.
     */
    function acceptSignership() internal virtual {
        address sender = _msgSender();
        if (sender != pendingSigner()) {
            revert UnauthorizedAccount(sender);
        }
        if (_bitmapSigned(changeSignerBitmap(), 3) == false) {
            revert NotEnoughSignatures();
        }

        uint256 i = replacedSignerIndex();
        address oldSigner = _signers[i];
        assembly {
            sstore(add(_signers.slot, i), sender)
            sstore(_replacedSignerIndex.slot, 5)
            sstore(_changeSignerBitmap.slot, 1)
            sstore(_changeOwnerBitmap.slot, 1)
        }
        emit SignerChanged(oldSigner, sender);
    }

    /**
     * blocks the contract from executing frequent transactions until unblocked.
     */
    function _block() internal {
        address sender = _msgSender();
        if (_signerIndex(sender) > 4) {
            revert UnauthorizedAccount(sender);
        }

        assembly {
            sstore(_isBlocked.slot, 1)
        }
        emit ContractBlocked(sender);
    }

    /**
     * unblocks the contract from executing any transactions.
     */
    function _unblock() internal {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        uint256 bm = unblockBitmap();
        if (bm == 1 && isBlocked() == false) {
            revert NotBlocked();
        }

        assembly {
            bm := or(bm, shl(add(i, 1), 1))
        }
        emit ContractUnblockConfirmed(sender);
        if (_bitmapSigned(bm, 3)) {
            assembly {
                sstore(_isBlocked.slot, 0)
                sstore(_unblockBitmap.slot, 1)
            }
            emit ContractUnblocked();
        } else {
            assembly {
                sstore(_unblockBitmap.slot, bm)
            }
        }
    }

    /**
     * @dev returns index of the signer in the signers array.
     */
    function _signerIndex(address signer) internal view returns (uint256 i) {
        address[4] storage tempSigners = _signers;
        if (signer == owner()) i = 0;
        else if (signer == tempSigners[0]) i = 1;
        else if (signer == tempSigners[1]) i = 2;
        else if (signer == tempSigners[2]) i = 3;
        else if (signer == tempSigners[3]) i = 4;
        else i = 5;
    }

    /**
     * checks whether the given bitmap is signed by enough signers.
     * @param bitmap: the bitmap to check
     * @param reqCount: the number of signers required (including owner)
     */
    function _bitmapSigned(uint256 bitmap, uint256 reqCount) internal pure returns (bool result) {
        assembly {
            let count := 0
            if and(bitmap, shl(1, 1)) { count := add(count, 1) }
            if and(bitmap, shl(2, 1)) { count := add(count, 1) }
            if and(bitmap, shl(3, 1)) { count := add(count, 1) }
            if and(bitmap, shl(4, 1)) { count := add(count, 1) }
            if and(bitmap, shl(5, 1)) { count := add(count, 1) }
            result := iszero(gt(reqCount, count))
        }
    }
}
