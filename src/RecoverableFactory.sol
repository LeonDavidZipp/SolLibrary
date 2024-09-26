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
    uint256 private _gasLimit;
    address[] private _recoveries;
    mapping(address => address) private _recoveryMap;
    uint256 private _withdrawBitmap;
    uint256 private _abortWithdrawBitmap;
    uint256 private _withdrawAllBitmap;
    uint256 private _abortWithdrawAllBitmap;

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event RecoveryCreated(address indexed owner, address indexed backup, address recovery);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error InsufficientFee();
    error InvalidAddress(address);
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
        assembly {
            sstore(_fee.slot, initialFee)
            sstore(_gasLimit.slot, initialGasLimit)
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
    function proposeWithdraw(uint256 nonce) external onlyOwner {
        address sender = _msgSender();

        if (withdrawAllBitmap() != 1) {
            revert SignerChangeInProgress();
        }
    }
    
    function proposeWithdrawAll(uint256 nonce) external onlyOwner {
        payable(owner()).transfer(address(this).balance - gasLimit());
    }

    function confirmWithdraw(uint256 nonce) external onlySigner {
        address sender = _msgSender();
        uint256 i = _signerIndex(sender);
        if (i > 4) {
            revert UnauthorizedAccount(sender);
        }
        if (changeSignerBitmap() != 1) {
            revert SignerChangeInProgress();
        }
    }

    function abortWithdraw(uint256 nonce) external onlyOwner {

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

    /* ********************************************************************** */
    /* Gas Limit Functions                                                    */
    /* ********************************************************************** */
    function gasLimit() public view returns (uint256 g) {
        assembly {
            g := sload(_gasLimit.slot)
        }
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner notBlocked {
        assembly {
            sstore(_gasLimit.slot, newGasLimit)
        }
    }
}
