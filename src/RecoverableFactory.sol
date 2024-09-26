// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableMultisigNonce} from "./OwnableMultisigNonce.sol";
import {Recoverable} from "./Recoverable.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract RecoverableFactory is OwnableMultisigNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 private _fee;
    address[] private _recoveries;
    mapping(address => address) private _recoveryMap;
    uint256 private _amount;
    uint256 private _withdrawBitmap;
    uint256 private _abortWithdrawBitmap;
    uint256 private _withdrawAllBitmap;
    uint256 private _abortWithdrawAllBitmap;

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event RecoveryCreated(address indexed owner, address indexed backup, address recovery);
    event WithdrawalProposed(uint256 amount);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error InsufficientFee();
    error InvalidAddress(address);
    error RecoveryExists(address owner, address recovery);

    error WithdrawalNotProposed();
    error WithdrawalInProgress();

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
        assembly {
            sstore(_fee.slot, initialFee)
            sstore(_withdrawBitmap.slot, 1)
            sstore(_abortWithdrawBitmap.slot, 1)
            sstore(_withdrawAllBitmap.slot, 1)
            sstore(_abortWithdrawAllBitmap.slot, 1)
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
            revert InvalidAddress();
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

    /* ********************************************************************** */
    /* Withdraw Functions                                                     */
    /* ********************************************************************** */
    function amount() public view returns (uint256 a) {
        a = _amount;
    }

    function proposeWithdraw(uint256 amount, uint256 nonce) external onlyOwner {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        if (withdrawAllBitmap() != 1) {
            revert WithdrawalInProgress();
        }
        uint256 bm = withdrawBitmap();
        if (bm != 1) {
            revert WithdrawalInProgress();
        }

        assembly {
            sstore(_withdrawBitmap.slot, or(bm, shl(add(i, 1), 1)))
            sstore(_amount.slot, amount)
        }

        emit WithdrawalProposed(amount);

        _useCheckedNonce(sender, nonce);
    }

    function confirmWithdraw(uint256 nonce) external {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        if (withdrawAllBitmap() != 1) {
            revert WithdrawalInProgress();
        }
        uint256 bm = withdrawBitmap();
        if (bm != 1) {
            revert WithdrawalInProgress();
        }

        assembly {
            sstore(_withdrawBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }

        _useCheckedNonce(sender, nonce);
    }

    function withdraw(uint256 nonce) external onlyOwner {
        if (_bitmapSigned(withdrawBitmap(), 3) == false) {
            revert NotEnoughSignatures();
        }

        payable(owner()).transfer(amount());

        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_amount.slot, 0)
        }

        _useCheckedNonce(owner(), nonce);
    }

    function abortWithdraw(uint256 nonce) external onlyOwner {
        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_amount.slot, 0)
        }

        _useCheckedNonce(owner(), nonce);
    }

    function withdrawBitmap() public view returns (uint256 w) {
        assembly {
            w := sload(_withdrawalBitmap.slot)
        }
    }

    function abortWithdrawBitmap() public view returns (uint256 a) {
        assembly {
            a := sload(_abortWithdrawalBitmap.slot)
        }
    }

    /* ********************************************************************** */
    /* Withdraw All Functions                                                 */
    /* ********************************************************************** */
    function proposeWithdrawAll(uint256 nonce) external onlyOwner {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        if (withdrawBitmap() != 1) {
            revert WithdrawalInProgress();
        }
        uint256 bm = withdrawAllBitmap();
        if (bm != 1) {
            revert WithdrawalInProgress();
        }

        assembly {
            sstore(_withdrawAllBitmap.slot, or(bm, shl(add(i, 1), 1)))
            sstore(_amount.slot, amount)
        }

        emit WithdrawalProposed(amount);

        _useCheckedNonce(sender, nonce);
    }

    function confirmWithdrawAll(uint256 nonce) external {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        if (withdrawBitmap() != 1) {
            revert WithdrawalInProgress();
        }
        uint256 bm = withdrawAllBitmap();
        if (bm != 1) {
            revert WithdrawalInProgress();
        }

        assembly {
            sstore(_withdrawAllBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }

        _useCheckedNonce(sender, nonce);
    }

    function withdrawAll(uint256 nonce) external onlyOwner {
        if (_bitmapSigned(withdrawAllBitmap(), 3) == false) {
            revert NotEnoughSignatures();
        }

        payable(owner()).transfer(address(this).balance);

        assembly {
            sstore(_withdrawAllBitmap.slot, 1)
        }

        _useCheckedNonce(owner(), nonce);
    }

    function abortWithdrawAll(uint256 nonce) external onlyOwner {
        assembly {
            sstore(_withdrawAllBitmap.slot, 1)
        }

        _useCheckedNonce(owner(), nonce);
    }

    function withdrawAllBitmap() public view returns (uint256 w) {
        assembly {
            w := sload(_withdrawalAllBitmap.slot)
        }
    }

    function abortWithdrawAllBitmap() public view returns (uint256 a) {
        assembly {
            a := sload(_abortWithdrawalAllBitmap.slot)
        }
    }
}
