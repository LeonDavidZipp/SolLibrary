// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Blockable
/// @notice A contract that can be blocked
contract Blockable {
    bool private _blocked;

    event Blocked();
    event Unblocked();

    function blocked() public view returns (bool) {
        return _blocked;
    }

    function _block() internal {
        _blocked = true;
        emit Blocked();
    }

    function _unblock() internal {
        _blocked = false;
        emit Unblocked();
    }
}
