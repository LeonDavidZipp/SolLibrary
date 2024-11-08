// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library BitMaps {
    struct BitMap {
        uint256 _data;
    }

    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        return bitmap._data & (1 << index) != 0;
    }

    function setTo(BitMap storage bitmap, uint256 index, bool value) internal{
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap._data |= (1 << index);
    }

    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap._data &= ~(1 << index);
    }

    function count(BitMap storage bitmap) internal view returns (uint256 c) {
        uint256 data = bitmap._data;
        unchecked {
            for (uint256 i = 0; i < 256; ++i) {
                c += data & 1;
                data >>= 1;
            }
        }
        return c;
    }

    function checkWhetherNBitsFrom0Set(BitMap storage bitmap, uint256 n) internal view returns (bool) {
        return (bitmap._data == (2 ** n) - 1);
    }
}
