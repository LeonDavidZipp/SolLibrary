// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableMultisigNonce} from "./OwnableMultisigNonce.sol";

contract MultisigWalletNonce is OwnableMultisigNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    uint256 internal _fee;
    address[] internal _recoveries;
    mapping(address => address) internal _recoveryMap;
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
    function amount() public view returns (uint256 a) {
        a = _amount;
    }

    function proposeWithdraw(uint256 amount_, uint256 nonce) external onlyOwner {
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

        uint256 amount_ = amount();
        address sender = _msgSender();

        payable(sender).transfer(amount_);

        assembly {
            sstore(_withdrawBitmap.slot, 1)
            sstore(_amount.slot, 0)
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

    function withdrawBitmap() public view returns (uint256 w) {
        assembly {
            w := sload(_withdrawBitmap.slot)
        }
    }

    function abortWithdrawBitmap() public view returns (uint256 a) {
        assembly {
            a := sload(_abortWithdrawBitmap.slot)
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
        }

        emit WithdrawalProposed(address(this).balance);

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

        uint256 amount_ = address(this).balance;

        payable(_msgSender()).transfer(amount_);

        assembly {
            sstore(_withdrawAllBitmap.slot, 1)
        }

        emit Withdrawal(amount_);

        _useCheckedNonce(_msgSender(), nonce);
    }

    function abortWithdrawAll(uint256 nonce) external onlyOwner {
        assembly {
            sstore(_withdrawAllBitmap.slot, 1)
        }

        _useCheckedNonce(_msgSender(), nonce);
    }

    function withdrawAllBitmap() public view returns (uint256 w) {
        assembly {
            w := sload(_withdrawAllBitmap.slot)
        }
    }

    function abortWithdrawAllBitmap() public view returns (uint256 a) {
        assembly {
            a := sload(_abortWithdrawAllBitmap.slot)
        }
    }
}
