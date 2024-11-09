// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Mappings {
    /* -------------------------------------------------------------------------- */
    /* Uint to Uint Maps                                                          */
    /* -------------------------------------------------------------------------- */
    struct UintUintMap {
        mapping(uint256 => uint256) _values;
        uint256[] _keys;
        mapping(uint256 => bool) _keyExists;
    }

    function set(UintUintMap storage map, uint256 key, uint256 value) internal {
        map._values[key] = value;
        if (!map._keyExists[key]) {
            map._keyExists[key] = true;
            map._keys.push(key);
        }
    }

    function get(UintUintMap storage map, uint256 key) internal view returns (uint256) {
        return map._values[key];
    }
}
