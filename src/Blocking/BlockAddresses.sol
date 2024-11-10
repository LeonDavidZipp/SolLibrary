// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title BlockAddresses
/// @notice A contract that keeps a blacklist of blocked addresses
contract BlockAddresses {
    mapping(address addr => bool) private _blockedAddresses;

    event BlockedAddress(address addr);
    event UnblockedAddress(address addr);

    function _isAddressBlocked(address addr) internal view returns (bool) {
        return _blockedAddresses[addr];
    }

    function _blockAddress(address addr) internal {
        _blockedAddresses[addr] = true;
        emit BlockedAddress(addr);
    }

    function _unblockAddress(address addr) internal {
        _blockedAddresses[addr] = false;
        emit UnblockedAddress(addr);
    }
}
