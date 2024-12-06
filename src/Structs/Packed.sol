// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Packed
/// @notice Library for packing and unpacking values in a single uint256 slot
library Packed {
    /// Indexing starts at 0 for all structs.
    /* --------------------------------------------------------------------------- */
    /* Errors                                                                      */
    /* --------------------------------------------------------------------------- */
    error IndexOutOfBounds(uint256 index, uint256 maxIndex);

    /* --------------------------------------------------------------------------- */
    /* Modifiers                                                                   */
    /* --------------------------------------------------------------------------- */
    modifier _validIndex(uint256 i, uint256 maxIndex) {
        if (i > maxIndex) {
            revert IndexOutOfBounds(i, maxIndex - 1);
        }
        _;
    }

    /* --------------------------------------------------------------------------- */
    /* Store2 (2 uint128 values)                                                   */
    /* --------------------------------------------------------------------------- */
    /// Store2 stores 2 uin128 values in a single uint256 slot
    struct Store2 {
        uint256 values;
    }

    /// pack stores a value in the slot at the given index; it automatically clears the slot
    /// @param self the Store struct to pack the value into
    /// @param value value to pack
    /// @param i index at which to insert the value; indexing starts at 0, MUST be less than 2
    function pack(Store2 storage self, uint128 value, uint256 i) internal _validIndex(i, 1) {
        uint256 mask = uint256(type(uint128).max) << (128 * i);
        self.values = (self.values & ~mask) | ((uint256(value) << (128 * i)));
    }

    /// unpack retrieves a value from a packed slot
    /// @param self the Store struct to unpack the value from
    /// @param i index at which to retrieve the value; indexing starts at 0, MUST be less than 2
    function unpack(Store2 storage self, uint256 i) internal view _validIndex(i, 1) returns (uint128 res) {
        uint256 mask = uint256(type(uint128).max) << (128 * i);
        res = uint128((self.values & mask) >> (128 * i));
    }

    /// reset sets the value of the Store2 to 0
    /// @param self the Store struct to reset the value from
    function reset(Store2 storage self) internal {
        delete(self.values);
    }

    /// resets the slot at the given index
    /// @param self the Store struct to reset the value from
    /// @param i index at which to reset the value; indexing starts at 0, MUST be less than 2
    function reset(Store2 storage self, uint256 i) internal _validIndex(i, 1) {
        uint256 mask = uint256(type(uint128).max) << (128 * i);
        self.values = self.values & ~mask;
    }

    /* --------------------------------------------------------------------------- */
    /* Store4 (4 uint64 values)                                                   */
    /* --------------------------------------------------------------------------- */
    /// Store4 stores 4 uint64 values in a single uint256 slot
    struct Store4 {
        uint256 values;
    }

    /// pack stores a value in the slot at the given index; it automatically clears the slot
    /// @param self the Store struct to pack the value into
    /// @param value value to pack
    /// @param i index at which to insert the value; indexing starts at 0, MUST be less than 4
    function pack(Store4 storage self, uint64 value, uint256 i) internal _validIndex(i, 3) {
        uint256 mask = uint256(type(uint64).max) << (64 * i);
        self.values = (self.values & ~mask) | ((uint256(value) << (64 * i)));
    }

    /// unpack retrieves a value from a packed slot
    /// @param self the Store struct to unpack the value from
    /// @param i index at which to retrieve the value; indexing starts at 0, MUST be less than 4
    function unpack(Store4 storage self, uint256 i) internal view _validIndex(i, 3) returns (uint64 res) {
        uint256 mask = uint256(type(uint64).max) << (64 * i);
        res = uint64((self.values & mask) >> (64 * i));
    }

    /// reset sets the value of the Store4 to 0
    /// @param self the Store struct to reset the value from
    function reset(Store4 storage self) internal {
        delete(self.values);
    }

    /// resets the slot at the given index
    /// @param self the Store struct to reset the value from
    /// @param i index at which to reset the value; indexing starts at 0, MUST be less than 4
    function reset(Store4 storage self, uint256 i) internal _validIndex(i, 3) {
        uint256 mask = uint256(type(uint64).max) << (64 * i);
        self.values = self.values & ~mask;
    }

    /* --------------------------------------------------------------------------- */
    /* Store8 (8 uint32 values)                                                   */
    /* --------------------------------------------------------------------------- */
    /// Store8 stores 8 uint32 values in a single uint256 slot
    struct Store8 {
        uint256 values;
    }

    /// pack stores a value in the slot at the given index; it automatically clears the slot
    /// @param self the Store struct to pack the value into
    /// @param value value to pack
    /// @param i index at which to insert the value; indexing starts at 0, MUST be less than 8
    function pack(Store8 storage self, uint32 value, uint256 i) internal _validIndex(i, 7) {
        uint256 mask = uint256(type(uint32).max) << (32 * i);
        self.values = (self.values & ~mask) | ((uint256(value) << (32 * i)));
    }

    /// unpack retrieves a value from a packed slot
    /// @param self the Store struct to unpack the value from
    /// @param i index at which to retrieve the value; indexing starts at 0, MUST be less than 8
    function unpack(Store8 storage self, uint256 i) internal view _validIndex(i, 7) returns (uint32 res) {
        uint256 mask = uint256(type(uint32).max) << (32 * i);
        res = uint32((self.values & mask) >> (32 * i));
    }

    /// reset sets the value of the Store8 to 0
    /// @param self the Store struct to reset the value from
    function reset(Store8 storage self) internal {
        delete(self.values);
    }

    /// resets the slot at the given index
    /// @param self the Store struct to reset the value from
    /// @param i index at which to reset the value; indexing starts at 0, MUST be less than 8
    function reset(Store8 storage self, uint256 i) internal _validIndex(i, 7) {
        uint256 mask = uint256(type(uint32).max) << (32 * i);
        self.values = self.values & ~mask;
    }

    /* --------------------------------------------------------------------------- */
    /* Store16 (16 uint16 values)                                                 */
    /* --------------------------------------------------------------------------- */
    /// Store16 stores 16 uint16 values in a single uint256 slot
    struct Store16 {
        uint256 values;
    }

    /// pack stores a value in the slot at the given index; it automatically clears the slot
    /// @param self the Store struct to pack the value into
    /// @param value value to pack
    /// @param i index at which to insert the value. Indexing starts at 0
    function pack(Store16 storage self, uint16 value, uint256 i) internal _validIndex(i, 15) {
        uint256 mask = uint256(type(uint16).max) << (16 * i);
        self.values = (self.values & ~mask) | ((uint256(value) << (16 * i)));
    }

    /// unpack retrieves a value from a packed slot
    /// @param self the Store struct to unpack the value from
    /// @param i index at which to retrieve the value. Indexing starts at 0
    function unpack(Store16 storage self, uint256 i) internal view _validIndex(i, 15) returns (uint16 res) {
        uint256 mask = uint256(type(uint16).max) << (16 * i);
        res = uint16((self.values & mask) >> (16 * i));
    }

    /// reset sets the value of the Store16 to 0
    /// @param self the Store struct to reset the value from
    function reset(Store16 storage self) internal {
        delete(self.values);
    }

    /// resets the slot at the given index
    /// @param self the Store struct to reset the value from
    /// @param i index at which to reset the value. Indexing starts at 0
    function reset(Store16 storage self, uint256 i) internal _validIndex(i, 15) {
        uint256 mask = uint256(type(uint16).max) << (16 * i);
        self.values = self.values & ~mask;
    }

    /* --------------------------------------------------------------------------- */
    /* Store32 (32 uint8 values)                                                  */
    /* --------------------------------------------------------------------------- */
    /// Store32 stores 32 uint8 values in a single uint256 slot
    struct Store32 {
        uint256 values;
    }

    /// pack stores a value in the slot at the given index; it automatically clears the slot
    /// @param self the Store struct to pack the value into
    /// @param value value to pack
    /// @param i index at which to insert the value; indexing starts at 0, MUST be less than 32
    function pack(Store32 storage self, uint8 value, uint256 i) internal _validIndex(i, 31) {
        uint256 mask = uint256(type(uint8).max) << (8 * i);
        self.values = (self.values & ~mask) | ((uint256(value) << (8 * i)));
    }

    /// unpack retrieves a value from a packed slot
    /// @param self the Store struct to unpack the value from
    /// @param i index at which to retrieve the value; indexing starts at 0, MUST be less than 32
    function unpack(Store32 storage self, uint256 i) internal view _validIndex(i, 31) returns (uint8 res) {
        uint256 mask = uint256(type(uint8).max) << (8 * i);
        res = uint8((self.values & mask) >> (8 * i));
    }

    /// reset sets the value of the Store32 to 0
    /// @param self the Store struct to reset the value from
    function reset(Store32 storage self) internal {
        delete(self.values);
    }

    /// resets the slot at the given index
    /// @param self the Store struct to reset the value from
    /// @param i index at which to reset the value; indexing starts at 0, MUST be less than 32
    function reset(Store32 storage self, uint256 i) internal _validIndex(i, 31) {
        uint256 mask = uint256(type(uint8).max) << (8 * i);
        self.values = self.values & ~mask;
    }
}
