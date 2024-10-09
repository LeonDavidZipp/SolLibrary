// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultisigWalletNonce} from "multisig/MultisigWalletNonce.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

contract MultiRecoverable is MultisigWalletNonce {
    /* ********************************************************************** */
    /* State Variables                                                        */
    /* ********************************************************************** */
    IAllowanceTransfer internal immutable _PERMIT_2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    uint256 private _fee; // 0.025 ether for now
    address[] private _accounts; // registered accounts
    mapping(address => address) private _accountToBackup; // account => backup
    mapping(address => address) private _backupToAccount; // backup => account

    /* ********************************************************************** */
    /* Events                                                                 */
    /* ********************************************************************** */
    event FundsTransferred(address indexed account, address indexed backup);
    event Registered(address indexed account, address indexed backup);
    event Unregistered(address indexed account);
    event BackupChanged(address indexed account, address indexed newBackup);

    /* ********************************************************************** */
    /* Errors                                                                 */
    /* ********************************************************************** */
    error InsufficientFee();
    error AlreadyRegistered(address account);
    error NotRegistered(address account);
    error InvalidFromAccount(address account);
    error InvalidToAccount(address account);

    /* ********************************************************************** */
    /* Constructor                                                            */
    /* ********************************************************************** */
    constructor(address initialOwner, address[4] memory initialSigners, uint256 fee_)
        payable
        MultisigWalletNonce(initialOwner, initialSigners)
    {
        assembly {
            sstore(_fee.slot, fee_)
        }
    }

    /* ********************************************************************** */
    /* Account Functions                                                      */
    /* ********************************************************************** */
    function register(address initialBackup, IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature)
        external
        payable
    {
        if (msg.value < fee()) {
            revert InsufficientFee();
        }
        if (initialBackup == address(0)) {
            revert InvalidAddress(initialBackup);
        }
        address sender = _msgSender();
        if (backup(sender) != address(0)) {
            revert AlreadyRegistered(sender);
        }

        permit2().permit(sender, permitBatch, signature);

        _accounts.push(sender);
        _accountToBackup[sender] = initialBackup;
        _backupToAccount[initialBackup] = sender;

        emit Registered(sender, initialBackup);
    }

    function unregister(IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature) external {
        address sender = _msgSender();
        if (backup(sender) == address(0)) {
            revert NotRegistered(sender);
        }

        permit2().permit(sender, permitBatch, signature);

        unchecked {
            address[] storage accounts_ = _accounts;
            uint256 len = accounts_.length;
            for (uint256 i; i < len; ++i) {
                if (accounts_[i] == sender) {
                    accounts_[i] = accounts_[len - 1];
                    accounts_.pop();
                    break;
                }
            }
        }
        delete _accountToBackup[sender];
        delete _backupToAccount[backup(sender)];

        emit Unregistered(sender);
    }

    function accounts() public view returns (address[] memory) {
        return _accounts;
    }

    function account(address _backup) public view returns (address a) {
        a = _backupToAccount[_backup];
    }

    function accountCount() public view returns (uint256 c) {
        c = accounts().length;
    }

    /* ********************************************************************** */
    /* Permit Functions                                                       */
    /* ********************************************************************** */
    function updatePermits(IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature) external {
        address sender = _msgSender();
        if (backup(sender) == address(0)) {
            revert NotRegistered(sender);
        }
        permit2().permit(sender, permitBatch, signature);
    }

    function permit2() internal view returns (IAllowanceTransfer i) {
        i = _PERMIT_2;
    }

    /* ********************************************************************** */
    /* Backup Functions                                                      */
    /* ********************************************************************** */
    function backup() public view returns (address a) {
        a = _accountToBackup[_msgSender()];
    }

    function backup(address _account) public view returns (address a) {
        a = _accountToBackup[_account];
    }

    function changeBackup(address newBackup, uint256 nonce) external {
        address sender = _msgSender();
        if (backup(sender) == address(0)) {
            revert NotRegistered(sender);
        }
        if (newBackup == address(0)) {
            revert InvalidAddress(newBackup);
        }

        _accountToBackup[sender] = newBackup;

        emit BackupChanged(sender, newBackup);

        _useCheckedNonce(sender, nonce);
    }

    /* ********************************************************************** */
    /* Recovery Functions                                                     */
    /* ********************************************************************** */
    function recover(IAllowanceTransfer.AllowanceTransferDetails[] calldata transferDetails) external {
        address sender = _msgSender();
        address account_ = account(sender);
        if (account_ == address(0)) {
            revert NotRegistered(sender);
        }

        unchecked {
            uint256 len = transferDetails.length;
            for (uint256 i; i < len; ++i) {
                if (transferDetails[i].from != account_) {
                    revert InvalidFromAccount(transferDetails[i].from);
                }
                if (transferDetails[i].to != sender) {
                    revert InvalidToAccount(transferDetails[i].to);
                }
            }
        }

        permit2().transferFrom(transferDetails);

        emit FundsTransferred(account_, sender);
    }

    /* ********************************************************************** */
    /* Fee Functions                                                          */
    /* ********************************************************************** */
    function fee() public view returns (uint256) {
        return _fee;
    }

    function setFee(uint256 fee_) external onlyOwner {
        assembly {
            sstore(_fee.slot, fee_)
        }
    }
}
