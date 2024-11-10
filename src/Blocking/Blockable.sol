// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Blockable
/// @notice A contract that can be blocked
contract Blockable {
    bool private _blockd;

    event Blocked();
    event Unblocked();

    function _blocked() internal view returns (bool) {
        return _blockd;
    }

    function _block() internal {
        _blockd = true;
        emit Blocked();
    }

    function _unblock() internal {
        _blockd = false;
        emit Unblocked();
    }
}
