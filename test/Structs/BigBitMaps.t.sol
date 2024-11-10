// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "structs/BigBitMaps.sol";
import "forge-std/Test.sol";

contract BigBitMapsTest is Test {
    using BigBitMaps for BigBitMaps.BigBitMap;

    BigBitMaps.BigBitMap public bm;
    BigBitMaps.BigBitMap public bm2;

    function setUp() public {
        bm.setLength(1);
        bm2.setLength(5);
    }

    function test_setLength() public {
        bm.setLength(2);
        assertEq(bm.length(), 2);
        bm2.set(257);
        bm2.setLength(1);
        assertEq(bm2.length(), 1);
        assertEq(bm2._data[1], 0);
    }

    function test_set_unset_get() public {
        bm.set(0);
        assertTrue(bm.get(0));
        bm.unset(0);
        assertFalse(bm.get(0));
        bm.set(1);
        assertTrue(bm.get(1));
        bm.unset(1);
        assertFalse(bm.get(1));
        bm.set(200);
        assertTrue(bm.get(200));
        bm.unset(200);
        assertFalse(bm.get(200));

        bm2.set(0);
        assertTrue(bm2.get(0));
        bm2.unset(0);
        assertFalse(bm2.get(0));
        bm2.set(266);
        assertTrue(bm2.get(266));
        bm2.unset(266);
        assertFalse(bm2.get(266));
        bm2.set(512);
        assertTrue(bm2.get(512));
        bm2.unset(512);
        assertFalse(bm2.get(512));
    }

    function testFail_set_IndexOutOfBounds() public {
        bm.set(257);
    }

    function testFail_unset_IndexOutOfBounds() public {
        bm.unset(257);
    }

    function testFail_get_IndexOutOfBounds() public view {
        bm.get(257);
    }

    function test_setAll() public {
        bm2.setAll();
        assertEq(bm2.count(), bm2.length() * 256);
    }

    function test_unsetAll() public {
        bm2.setAll();
        bm2.unsetAll();
        assertEq(bm.count(), 0);
    }

    function test_setTo() public {
        bm.setTo(0, true);
        assertTrue(bm.get(0));
        bm.setTo(0, false);
        assertFalse(bm.get(0));
        bm.setTo(1, true);
        assertTrue(bm.get(1));
        bm.setTo(1, false);
        assertFalse(bm.get(1));
        bm.setTo(200, true);
        assertTrue(bm.get(200));
        bm.setTo(200, false);
        assertFalse(bm.get(200));
    }

    function test_count() public {
        assertEq(bm2.count(), 0);
        bm2.set(0);
        assertEq(bm2.count(), 1);
        bm2.set(500);
        assertEq(bm2.count(), 2);
        bm2.set(1000);
        assertEq(bm2.count(), 3);
        bm2.setAll();
        assertEq(bm2.count(), bm2.length() * 256);
    }
}
