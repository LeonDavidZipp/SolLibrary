// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TwoUnequalOwnable} from "./TwoUnequalOwnable.sol";
// import {IAllowanceTransfer} from "@Permit2/src/interfaces/IAllowanceTransfer.sol";
import {IAllowanceTransfer} from "../lib/permit2/src/interfaces/IAllowanceTransfer.sol";

/**
 * @title Recoverable
 * simple smart contract allowing a user to register his main wallet and another wallet as a recovery wallet
 * user than has to give smart contract permissions to transfer funds from his main wallet to his recovery wallet
 */
contract Recovery is TwoUnequalOwnable {
    IAllowanceTransfer private constant _PERMIT_2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    event FundsTransferred(address indexed account, address indexed backup);

    constructor(
        address initialOwner,
        address initialBackup,
        IAllowanceTransfer.PermitBatch memory permitBatch,
        bytes memory signature
    ) TwoUnequalOwnable(initialOwner, initialBackup) {
        _PERMIT_2.permit(initialOwner, permitBatch, signature);
    }

    function addTokenPermits(IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature)
        external
        onlyOwner
    {
        _PERMIT_2.permit(owner(), permitBatch, signature);
    }

    function transferToBackup(IAllowanceTransfer.AllowanceTransferDetails[] calldata transferDetails)
        external
        onlyBackup
    {
        _PERMIT_2.transferFrom(transferDetails);

        address sender = _msgSender();
        emit FundsTransferred(sender, backup());
    }
}
