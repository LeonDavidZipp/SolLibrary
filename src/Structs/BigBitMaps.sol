// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library BigBitMaps {
    error IndexOutOfBound(uint256 index);

    struct BigBitMap {
        mapping(uint256 index => uint256) _data;
        uint256 len; // amount of uint256 in _data
    }

    function get(BigBitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 dataIndex = index / 256;
        if (dataIndex >= bitmap.len) {
            revert IndexOutOfBound(index);
        }
        uint256 bitIndex = index % 256;
        return bitmap._data[dataIndex] & (1 << bitIndex) != 0;
    }

    function setTo(BigBitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    function set(BigBitMap storage bitmap, uint256 index) internal {
        uint256 dataIndex = index / 256;
        if (dataIndex >= bitmap.len) {
            revert IndexOutOfBound(index);
        }
        uint256 bitIndex = index % 256;
        bitmap._data[dataIndex] |= (1 << bitIndex);
    }

    function setAll(BigBitMap storage bitmap) internal {
        unchecked {
            for (uint256 i = 0; i < bitmap.len; ++i) {
                bitmap._data[i] = type(uint256).max;
            }
        }
    }

    function unset(BigBitMap storage bitmap, uint256 index) internal {
        uint256 dataIndex = index / 256;
        if (dataIndex >= bitmap.len) {
            revert IndexOutOfBound(index);
        }
        uint256 bitIndex = index % 256;
        bitmap._data[dataIndex] &= ~(1 << bitIndex);
    }

    function unsetAll(BigBitMap storage bitmap) internal {
        unchecked {
            for (uint256 i = 0; i < bitmap.len; ++i) {
                bitmap._data[i] = 0;
            }
        }
    }

    function count(BigBitMap storage bitmap) internal view returns (uint256 c) {
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

    function length(BigBitMap storage bitmap) internal view returns (uint256) {
        return bitmap.len;
    }

    function setLength(BigBitMap storage bitmap, uint256 len) internal {
        uint256 oldLen = bitmap.len;
        if (oldLen > len) {
            unchecked {
                for (uint256 i = len; i < oldLen; ++i) {
                    delete bitmap._data[i];
                }
            }
        }
        bitmap.len = len;
    }
}
