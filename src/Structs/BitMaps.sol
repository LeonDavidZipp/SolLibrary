// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library BitMaps {
    struct BitMap {
        uint256 _data;
    }

    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        return bitmap._data & (1 << index) != 0;
    }

    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap._data |= (1 << index);
    }

    function setAll(BitMap storage bitmap) internal {
        bitmap._data = type(uint256).max;
    }

    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap._data &= ~(1 << index);
    }

    function unsetAll(BitMap storage bitmap) internal {
        bitmap._data = 0;
    }

    function count(BitMap storage bitmap) internal view returns (uint256 c) {
        uint256 data = bitmap._data;
        unchecked {
            for (uint256 i = 0; i < 256; ++i) {
                c += data & 1;
                data >>= 1;
            }
        }
    }

    function checkWhetherAllNBitsFrom0Set(BitMap storage bitmap, uint256 n) internal view returns (bool b) {
        if (n < 256) {
            b = bitmap._data == (2 ** n) - 1;
        } else {
            b = bitmap._data == type(uint256).max;
        }
    }
}
