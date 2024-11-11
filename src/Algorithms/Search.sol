// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Search {
    function bidirectionalSearch(uint256[] memory arr, uint256 key) internal pure returns (int256) {
        unchecked {
            uint256 len = arr.length;
            uint256 h = len / 2;
            uint256 revi;

            for (uint256 i = 0; i <= h; ++i) {
                if (arr[i] == key) {
                    return int256(i);
                }
                revi = len - i - 1;
                if (arr[revi] == key) {
                    return int256(revi);
                }
            }

            return -1;
        }
    }

    function bidirectionalSearch(address[] memory arr, address key) internal pure returns (int256) {
        uint256 len = arr.length;
        uint256 h = len / 2;
        uint256 revi;

        for (uint256 i = 0; i <= h; ++i) {
            if (arr[i] == key) {
                return int256(i);
            }
            revi = len - i - 1;
            if (arr[revi] == key) {
                return int256(revi);
            }
        }

        return -1;
    }
}
