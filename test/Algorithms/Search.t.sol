// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "structs/Mappings.sol";
import "forge-std/Test.sol";

contract SearchTest is Test {
    using Search for uint256[];

    uint256[] private arr = [1, 2, 3, 4, 5, 6, 1000 , 300, 66];

    function setUp() public {}

    function test_bidirectionalSearch() public view {
        // found
        assertEq(arr.bidirectionalSearch(1), 0);
        assertEq(arr.bidirectionalSearch(2), 1);
        assertEq(arr.bidirectionalSearch(3), 2);
        assertEq(arr.bidirectionalSearch(4), 3);
        assertEq(arr.bidirectionalSearch(5), 4);
        assertEq(arr.bidirectionalSearch(6), 5);
        assertEq(arr.bidirectionalSearch(1000), 6);
        assertEq(arr.bidirectionalSearch(300), 7);
        assertEq(arr.bidirectionalSearch(66), 8);

        // not found
        assertEq(arr.bidirectionalSearch(0), -1);
        assertEq(arr.bidirectionalSearch(7), -1);
        assertEq(arr.bidirectionalSearch(100), -1);
        assertEq(arr.bidirectionalSearch(10000), -1);
    }
}