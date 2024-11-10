// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "structs/BitMaps.sol";
import "forge-std/Test.sol";

contract BitMapsTest is Test {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap public bm;
    BitMaps.BitMap public bm2;

    receive() external payable {}

    fallback() external payable {}

    function setUp() public {
        bm = BitMaps.BitMap(0);
        bm2 = BitMaps.BitMap(0);
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
    }

    function test_setAll() public {
        bm.setAll();
        assertTrue(bm.count() == 256);
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(256));
    }

    function test_unsetAll() public {
        bm.setAll();
        bm.unsetAll();
        assertTrue(bm.count() == 0);
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(0));

        bm.set(0);
        bm.unsetAll();
        assertTrue(bm.count() == 0);
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(0));
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
        assertEq(bm.count(), 0);
        bm.set(0);
        assertEq(bm.count(), 1);
        bm.set(1);
        assertEq(bm.count(), 2);
        bm.set(200);
        assertEq(bm.count(), 3);
        bm.unset(0);
        assertEq(bm.count(), 2);
        bm.unset(1);
        assertEq(bm.count(), 1);
        bm.unset(200);
        assertEq(bm.count(), 0);
    }

    function test_checkWhetherAllNBitsFrom0Set() public {
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(0));
        bm.set(0);
        assertFalse(bm.checkWhetherAllNBitsFrom0Set(0));
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(1));
        bm.set(1);
        assertFalse(bm.checkWhetherAllNBitsFrom0Set(1));
        assertTrue(bm.checkWhetherAllNBitsFrom0Set(2));
        bm.set(200);
        assertFalse(bm.checkWhetherAllNBitsFrom0Set(2));
        assertFalse(bm.checkWhetherAllNBitsFrom0Set(200));

        assertTrue(bm2.checkWhetherAllNBitsFrom0Set(0));
        bm2.set(0);
        assertTrue(bm2.checkWhetherAllNBitsFrom0Set(1));
        bm2.set(1);
        assertTrue(bm2.checkWhetherAllNBitsFrom0Set(2));
        bm2.set(2);
        assertFalse(bm2.checkWhetherAllNBitsFrom0Set(2));
        bm2.set(3);
        assertFalse(bm2.checkWhetherAllNBitsFrom0Set(2));
    }
}
