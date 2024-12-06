// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "structs/Packed.sol";
import "forge-std/Test.sol";

contract MappingsTest is Test {
    using Packed for Packed.Store2;
    using Packed for Packed.Store4;
    using Packed for Packed.Store8;
    using Packed for Packed.Store16;
    using Packed for Packed.Store32;

    Packed.Store2 store2;
    Packed.Store4 store4;
    Packed.Store8 store8;
    Packed.Store16 store16;
    Packed.Store32 store32;

    /* --------------------------------------------------------------------------- */
    /* Store2 (2 uint128 values)                                                   */
    /* --------------------------------------------------------------------------- */
    function test_Store2() public {
        // small values
        store2.pack(1, 0);
        store2.pack(2, 1);
        assertEq(store2.unpack(0), 1);
        assertEq(store2.unpack(1), 2);

        // reset function
        store2.reset();
        assertEq(store2.unpack(0), 0);
        assertEq(store2.unpack(1), 0);

        // reset(index) function
        store2.pack(1, 0);
        store2.pack(2, 1);
        store2.reset(0);
        assertEq(store2.unpack(0), 0);
        assertEq(store2.unpack(1), 2);
        store2.reset(1);
        assertEq(store2.unpack(1), 0);

        // largest allowed value
        store2.pack(type(uint128).max, 0);
        store2.pack(99999, 1);
        assertEq(store2.unpack(0), type(uint128).max);
        assertEq(store2.unpack(1), 99999);
        store2.reset();
    }

    function testFail_Store2_IndexOutOfBounds() public {
        // index out of bounds
        store2.pack(1, 2);
    }

    function testFail_Store2_ValueTooLarge() public {
        // too large value
        store2.pack(type(uint128).max + 1, 0);
    }

    /* --------------------------------------------------------------------------- */
    /* Store4 (4 uint64 values)                                                    */
    /* --------------------------------------------------------------------------- */
    function testStore4() public {
        // small values
        for (uint64 i = 0; i < 4; i++) {
            store4.pack(i + 1, i);
            assertEq(store4.unpack(i), i + 1);
        }

        // reset function
        store4.reset();
        for (uint64 i = 0; i < 4; i++) {
            assertEq(store4.unpack(i), 0);
        }

        // reset(index) function
        for (uint64 i = 0; i < 4; i++) {
            store4.pack(i + 1, i);
            assertEq(store4.unpack(i), i + 1);
            store4.reset(i);
            assertEq(store4.unpack(i), 0);
        }

        // largest allowed value
        for (uint64 i = 0; i < 4; i++) {
            store4.pack(type(uint64).max, i);
            assertEq(store4.unpack(i), type(uint64).max);
        }

        store4.reset();
    }

    function testFail_Store4_IndexOutOfBounds() public {
        // index out of bounds
        store4.pack(1, 4);
    }

    function testFail_Store4_ValueTooLarge() public {
        // too large value
        store4.pack(type(uint64).max + 1, 0);
    }

    /* --------------------------------------------------------------------------- */
    /* Store8 (8 uint32 values)                                                    */
    /* --------------------------------------------------------------------------- */
    function testStore8() public {
        // small values
        for (uint32 i = 0; i < 8; i++) {
            store8.pack(i + 1, i);
            assertEq(store8.unpack(i), i + 1);
        }

        // reset function
        store8.reset();
        for (uint32 i = 0; i < 8; i++) {
            assertEq(store8.unpack(i), 0);
        }

        // reset(index) function
        for (uint32 i = 0; i < 8; i++) {
            store8.pack(i + 1, i);
            assertEq(store8.unpack(i), i + 1);
            store8.reset(i);
            assertEq(store8.unpack(i), 0);
        }

        // largest allowed value
        for (uint32 i = 0; i < 8; i++) {
            store8.pack(type(uint32).max, i);
            assertEq(store8.unpack(i), type(uint32).max);
        }

        store8.reset();
    }

    function testFail_Store8_IndexOutOfBounds() public {
        // index out of bounds
        store8.pack(1, 8);
    }

    function testFail_Store8_ValueTooLarge() public {
        // too large value
        store8.pack(type(uint32).max + 1, 0);
    }

    /* --------------------------------------------------------------------------- */
    /* Store16 (16 uint16 values)                                                  */
    /* --------------------------------------------------------------------------- */
    function test_Store16() public {
        // small values
        for (uint16 i = 0; i < 16; i++) {
            store16.pack(i + 1, i);
            assertEq(store16.unpack(i), i + 1);
        }

        // reset function
        store16.reset();
        for (uint16 i = 0; i < 16; i++) {
            assertEq(store16.unpack(i), 0);
        }

        // reset(index) function
        for (uint16 i = 0; i < 16; i++) {
            store16.pack(i + 1, i);
            assertEq(store16.unpack(i), i + 1);
            store16.reset(i);
            assertEq(store16.unpack(i), 0);
        }

        // largest allowed value
        for (uint16 i = 0; i < 16; i++) {
            store16.pack(type(uint16).max, i);
            assertEq(store16.unpack(i), type(uint16).max);
        }

        store16.reset();
    }

    function testFail_Store16_IndexOutOfBounds() public {
        // index out of bounds
        store16.pack(1, 16);
    }

    function testFail_Store16_ValueTooLarge() public {
        // too large value
        store16.pack(type(uint16).max + 1, 0);
    }

    /* --------------------------------------------------------------------------- */
    /* Store32 (32 uint8 values)                                                   */
    /* --------------------------------------------------------------------------- */
    function test_Store32() public {
        // small values
        for (uint8 i = 0; i < 32; i++) {
            store32.pack(i + 1, i);
            assertEq(store32.unpack(i), i + 1);
        }

        // reset function
        store32.reset();
        for (uint8 i = 0; i < 32; i++) {
            assertEq(store32.unpack(i), 0);
        }

        // reset(index) function
        for (uint8 i = 0; i < 32; i++) {
            store32.pack(i + 1, i);
            assertEq(store32.unpack(i), i + 1);
            store32.reset(i);
            assertEq(store32.unpack(i), 0);
        }

        // largest allowed value
        for (uint8 i = 0; i < 32; i++) {
            store32.pack(type(uint8).max, i);
            assertEq(store32.unpack(i), type(uint8).max);
        }

        store32.reset();
    }

    function testFail_Store32_IndexOutOfBounds() public {
        // index out of bounds
        store32.pack(1, 32);
    }

    function testFail_Store32_ValueTooLarge() public {
        // too large value
        store32.pack(type(uint8).max + 1, 0);
    }
}
