// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library BitMaps {
    struct BitMap {
        mapping(uint256 index => uint256) _data;
        uint256 len; // amount of uint256 in _data
    }

    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 dataIndex = index / 256;
        if (dataIndex >= bitmap.len) {
            return false;
        }
        uint256 bitIndex = index % 256;
        return bitmap._data[dataIndex] & (1 << bitIndex) != 0;
    }

    function setTo(BitMap storage bitmap, uint256 index, bool value) internal{
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 dataIndex = index / 256;
        uint256 bitIndex = index % 256;
        bitmap._data[dataIndex] |= (1 << bitIndex);
    }

    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 dataIndex = index / 256;
        uint256 bitIndex = index % 256;
        bitmap._data[dataIndex] &= ~(1 << bitIndex);
    }

    function unsetAll(BitMap storage bitmap) internal {
        unchecked {
            for (uint256 i = 0; i < bitmap.len; ++i) {
                bitmap._data[i] = 0;
            }
        }
    }

    function count(BitMap storage bitmap) internal view returns (uint256 c) {
        unchecked {
            for (uint256 i = 0; i < bitmap.len; ++i) {
                uint256 data = bitmap._data[i];
                for (uint256 j = 0; j < 256; ++j) {
                    c += data & 1;
                    data >>= 1;
                }
            }
        }
    }
}
