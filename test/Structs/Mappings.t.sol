// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "structs/Mappings.sol";
import "forge-std/Test.sol";

contract MappingsTest is Test {
    using Mappings for Mappings.UintUintMap;

    Mappings.UintUintMap private map;

    function setUp() public {}

    function test_set_get() public {
        map.set(0, 1);
        assertEq(map.get(0), 1);
        map.set(1, 2);
        assertEq(map.get(1), 2);
        map.set(200, 300);
        assertEq(map.get(200), 300);
    }
}
