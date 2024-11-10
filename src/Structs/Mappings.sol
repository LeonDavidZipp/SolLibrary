// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Algorithms/Search.sol";

library Mappings {
    using Search for uint256[];

    /* -------------------------------------------------------------------------- */
    /* Uint to Uint Maps                                                          */
    /* -------------------------------------------------------------------------- */
    struct UintUintMap {
        mapping(uint256 key => uint256 val) _items;
        uint256[] _keys;
        mapping(uint256 key => bool) _keyExists;
    }

    function set(UintUintMap storage map, uint256 key, uint256 value) internal {
        map._items[key] = value;
        if (!map._keyExists[key]) {
            map._keyExists[key] = true;
            map._keys.push(key);
        }
    }

    function get(UintUintMap storage map, uint256 key) internal view returns (uint256) {
        return map._items[key];
    }

    function unset(UintUintMap storage map, uint256 key) internal {
        if (map._keyExists[key]) {
            delete map._items[key];
            delete map._keyExists[key];
            map._keys[uint256(map._keys.bidirectionalSearch(key))] = map._keys[map._keys.length - 1];
            map._keys.pop();
        }
    }
}
