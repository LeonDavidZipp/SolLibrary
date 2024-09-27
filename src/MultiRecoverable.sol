// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {MultisigWalletNonce} from "./MultisigWalletNonce.sol";
// import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

// contract MultiRecoverable is MultisigWalletNonce {
//     /* ********************************************************************** */
//     /* State Variables                                                        */
//     /* ********************************************************************** */

//     uint256 private _fee; // 0.025 ether for now
//     mapping(address => address) private _recoveryMap;

//     /* ********************************************************************** */
//     /* Events                                                                 */
//     /* ********************************************************************** */

//     /* ********************************************************************** */
//     /* Errors                                                                 */
//     /* ********************************************************************** */

//     /* ********************************************************************** */
//     /* Fallback Functions                                                     */
//     /* ********************************************************************** */
//     receive() external payable {}

//     fallback() external payable {}

//     /* ********************************************************************** */
//     /* Constructor                                                            */
//     /* ********************************************************************** */
//     constructor(address initialOwner, address[4] memory initialSigners, uint256 fee_)
//         payable
//         MultisigWalletNonce(initialOwner, initialSigners)
//     {
//         assembly {
//             sstore(_fee.slot, fee_)
//         }
//     }

//     /* ********************************************************************** */
//     /* Account Functions                                                      */
//     /* ********************************************************************** */
//     function register(address initialBackup, IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory signature)
//         external payable
//     {
//         if (msg.value < fee()) {
//             revert InsufficientFee();
//         }
//         if (initialBackup == address(0)) {
//             revert InvalidAddress(initialBackup);
//         }

//         sender = _msgSender();
//         // if
//     }

//     /* ********************************************************************** */
//     /* Permit Functions                                                       */
//     /* ********************************************************************** */

//     /* ********************************************************************** */
//     /* Recovery Functions                                                     */
//     /* ********************************************************************** */
//     function transferToBackup(IAllowanceTransfer.AllowanceTransferDetails[] calldata transferDetails)
//         external
//         // onlyBackup
//     {
//         _PERMIT_2.transferFrom(transferDetails);

//         emit FundsTransferred(_msgSender(), backup());
//     }

//     /* ********************************************************************** */
//     /* Fee Functions                                                          */
//     /* ********************************************************************** */
//     function fee() public view returns (uint256) {
//         return _fee;
//     }

//     function setFee(uint256 fee_) external onlyOwner {
//         assembly {
//             sstore(_fee.slot, fee_)
//         }
//     }
// }
