// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TwoUnequalOwnable} from "ownership/TwoUnequalOwnable.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

/**
 * @title Recoverable
 * simple smart contract allowing a user to register his main wallet and another wallet as a recovery wallet
 * user than has to give smart contract permissions to transfer funds from his main wallet to his recovery wallet
 */
contract Recoverable is TwoUnequalOwnable {
    IAllowanceTransfer internal immutable _PERMIT_2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    event FundsTransferred(address indexed account, address indexed backup);

    constructor(address initialOwner, address initialBackup) TwoUnequalOwnable(initialOwner, initialBackup) {}

    /// @notice Allows the owner to add token permits to the contract using permit2
    /// @param permitBatch The permit batch to add
    /// @param signature The signature of the permit
    function addTokenPermits(IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature)
        external
        onlyOwner
    {
        _PERMIT_2.permit(owner(), permitBatch, signature);
    }

    // function addTokenPermits(address[] calldata tokens)
    //     external
    //     onlyOwner
    // {
    //     _PERMIT_2.permit(owner(), permitBatch, signature);
    // }

    function transferToBackup(IAllowanceTransfer.AllowanceTransferDetails[] calldata transferDetails)
        external
        onlyBackup
    {
        _PERMIT_2.transferFrom(transferDetails);

        emit FundsTransferred(_msgSender(), backup());
    }
}
