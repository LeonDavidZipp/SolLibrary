// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Mappings {
    /// This library inncludes many mappings from different types to other types
    /// All maps have:
    /// - _items:       the actual mapping component
    /// - _keys:        an iterable array storing every single key stored in the map
    /// - _keyExists:   another mapping allowing for fast lookup if a key exists

    /* -------------------------------------------------------------------------- */
    /* Errors                                                                     */
    /* -------------------------------------------------------------------------- */
    error KeyNotExisting();

    /* -------------------------------------------------------------------------- */
    /* Uint to Uint Map(s)                                                        */
    /* -------------------------------------------------------------------------- */
    struct UintUintMap {
        mapping(uint256 key => uint256 value) _items;
        uint256[] _keys;
        mapping(uint256 key => uint256) _keyExists;
    }

    function set(UintUintMap storage map, uint256 key, uint256 value) internal {
        map._items[key] = value;
        if (map._keyExists[key] == 0) {
            if (map._keys.length == 0 || map._keys[0] != key) {
                map._keyExists[key] = map._keys.length;
                map._keys.push(key);
            }
        }
    }

    function get(UintUintMap storage map, uint256 key) internal view returns (uint256) {
        if (map._keyExists[key] != 0 || (map._keys.length > 0 && map._keys[0] == key)) {
            return map._items[key];
        } else {
            revert KeyNotExisting();
        }
    }

    function unset(UintUintMap storage map, uint256 key) internal {
        if (map._keyExists[key] != 0 || (map._keys.length > 0 && map._keys[0] == key)) {
            delete map._items[key];
            delete map._keyExists[key];
            map._keys[map._keyExists[key]] = map._keys[map._keys.length - 1];
            map._keys.pop();
        }
    }

    /* -------------------------------------------------------------------------- */
    /* Address to Bool Map(s)                                                     */
    /* -------------------------------------------------------------------------- */
    struct AddressBoolMap {
        mapping(address key => bool value) _items;
        address[] _keys;
        mapping(address key => bool) _keyExists;
    }

    // function set(AddressBoolMap storage map, address key, bool value) internal {
    //     map._items[key] = value;
    //     if (!map._keyExists[key]) {
    //         map._keyExists[key] = true;
    //         map._keys.push(key);
    //     }
    // }

    // function get(UintUintMap storage map, address key) internal view returns (uint256) {
    //     if (map._keyExists[key]) {
    //         return map._items[key];
    //     } else {
    //         revert KeyNotExisting();
    //     }
    // }

    // function unset(UintUintMap storage map, address key) internal {
    //     delete map._items[key];
    // }
}
