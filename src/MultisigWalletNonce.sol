// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableMultisigNonce} from "./OwnableMultisigNonce.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Test, console} from "forge-std/Test.sol";

contract MultisigWalletNonce is OwnableMultisigNonce, ReentrancyGuard {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 internal _amount;
    uint256 internal _withdrawBitmap;
    uint256 internal _abortWithdrawBitmap;
    uint256 internal _withdrawAllBitmap;
    uint256 internal _abortWithdrawAllBitmap;

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event WithdrawalProposed(uint256 amount);
    event Withdrawal(uint256 amount);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error WithdrawalNotProposed();
    error WithdrawalInProgress();
    error WithdrawalFailed();

    /* ********************************************************************** */
    /* Fallback Functions                                                     */
    /* ********************************************************************** */
    receive() external payable {}

    fallback() external payable {}

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address[4] memory initialSigners)
        payable
        OwnableMultisigNonce(initialOwner, initialSigners)
    {
        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_abortWithdrawBitmap.slot, 1)
            sstore(_withdrawAllBitmap.slot, 1)
            sstore(_abortWithdrawAllBitmap.slot, 1)
        }
    }

    /* ********************************************************************** */
    /* Withdraw Functions                                                     */
    /* ********************************************************************** */
    /**
     * @dev Returns the amount of the proposed withdrawal.
     */
    function amount() public view returns (uint256 a) {
        a = _amount;
    }

    /**
     * @dev Propose a withdrawal of `amount_` wei.
     * @param amount_ The amount of wei to withdraw. If amount_ is type(uint256).max, the entire balance will be withdrawn.
     * @param nonce The nonce to use.
     */
    function proposeWithdraw(uint256 amount_, uint256 nonce) external onlyOwner {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }

        uint256 bm = withdrawBitmap();
        if (bm != 1) {
            revert WithdrawalInProgress();
        }

        assembly {
            sstore(_withdrawBitmap.slot, or(bm, shl(add(i, 1), 1)))
            sstore(_amount.slot, amount_)
        }

        emit WithdrawalProposed(amount_);

        _useCheckedNonce(sender, nonce);
    }

    function confirmWithdraw(uint256 nonce) external {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        } else if (i == 0) {
            revert UnauthorizedAccount(sender);
        }

        assembly {
            let bm := sload(_withdrawBitmap.slot)
            sstore(_withdrawBitmap.slot, or(bm, shl(add(i, 1), 1)))
        }

        _useCheckedNonce(sender, nonce);
    }

    function withdraw(uint256 nonce) external onlyOwner nonReentrant {
        if (_bitmapSigned(withdrawBitmap(), 3) == false) {
            revert NotEnoughSignatures();
        }

        uint256 amount_ = amount();
        address sender = _msgSender();

        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_amount.slot, 0)
        }

        (bool sent, ) = sender.call{value: amount_ == type(uint256).max ? address(this).balance : amount_}("");
        if (sent == false) {
            revert WithdrawalFailed();
        }

        emit Withdrawal(amount_);

        _useCheckedNonce(sender, nonce);
    }

    function abortWithdraw(uint256 nonce) external onlyOwner {
        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_amount.slot, 0)
        }

        _useCheckedNonce(_msgSender(), nonce);
    }

    function withdrawBitmap() internal view returns (uint256 w) {
        assembly {
            w := sload(_withdrawBitmap.slot)
        }
    }
}
