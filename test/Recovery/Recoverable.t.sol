// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Recoverable} from "recoverable/Recoverable.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import {PermitSignature} from "permit2/test/utils/PermitSignature.sol";
import {TokenProvider} from "permit2/test/utils/TokenProvider.sol";
import {AddressBuilder} from "permit2/test/utils/AddressBuilder.sol";
import {StructBuilder} from "permit2/test/utils/StructBuilder.sol";

contract RecoverableTest is Test, DeployPermit2, PermitSignature, TokenProvider {
    using AddressBuilder for address[];

    uint256 public constant ownerPK = 0x12341234;
    address public immutable owner = vm.addr(ownerPK);
    address public constant backup = address(2);
    uint160 public immutable defaultAmount = 10 ** 18;
    uint48 public defaultNonce = 0;
    uint48 public immutable defaultExpiration = uint48(block.timestamp + 5000000);
    Recoverable public recoverable;
    address public immutable permit2 = deployPermit2();
    bytes32 public immutable DOMAIN_SEPARATOR = IAllowanceTransfer(permit2).DOMAIN_SEPARATOR();

    function _defaultERC20PermitBatchAllowance(
        address[] memory tokens,
        uint160 amount,
        uint48 expiration,
        uint48 nonce,
        address spender
    ) internal view returns (IAllowanceTransfer.PermitBatch memory) {
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            details[i] = IAllowanceTransfer.PermitDetails({
                token: tokens[i],
                amount: amount,
                expiration: expiration,
                nonce: nonce
            });
        }

        return IAllowanceTransfer.PermitBatch({details: details, spender: spender, sigDeadline: block.timestamp + 100});
    }

    function setUp() public {
        initializeERC20Tokens();
        setERC20TestTokens(owner);
        setERC20TestTokenApprovals(vm, owner, permit2);

        recoverable = new Recoverable(owner, backup);
    }

    function test_constructor() public view {
        assertEq(recoverable.owner(), owner);
        assertEq(recoverable.backup(), backup);
    }

    function test_addTokenPermits() public {
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch = _defaultERC20PermitBatchAllowance(
            tokens, defaultAmount, defaultExpiration, defaultNonce, address(recoverable)
        );
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);

        vm.prank(owner);
        recoverable.addTokenPermits(permitBatch, sig1);

        (uint160 amount, uint48 expiration, uint48 nonce) =
            IAllowanceTransfer(permit2).allowance(owner, address(token0), address(recoverable));
        assertEq(amount, defaultAmount);
        assertEq(expiration, defaultExpiration);
        assertEq(nonce, defaultNonce + 1);

        (amount, expiration, nonce) =
            IAllowanceTransfer(permit2).allowance(owner, address(token1), address(recoverable));
        assertEq(amount, defaultAmount);
        assertEq(expiration, defaultExpiration);
        assertEq(nonce, defaultNonce + 1);
    }

    function testFail_addTokenPermits_invalidCaller() public {
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch = _defaultERC20PermitBatchAllowance(
            tokens, defaultAmount, defaultExpiration, defaultNonce, address(recoverable)
        );
        permitBatch.details[1].nonce = 0;
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);

        recoverable.addTokenPermits(permitBatch, sig1);
    }

    function test_transferToBackup() public {
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch = _defaultERC20PermitBatchAllowance(
            tokens, defaultAmount, defaultExpiration, defaultNonce, address(recoverable)
        );
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);

        uint256 startBalanceOwner0 = token0.balanceOf(owner);
        uint256 startBalanceBackup0 = token0.balanceOf(backup);

        vm.prank(owner);
        recoverable.addTokenPermits(permitBatch, sig1);

        address[] memory owners = AddressBuilder.fill(2, owner);
        IAllowanceTransfer.AllowanceTransferDetails[] memory transferDetails =
            StructBuilder.fillAllowanceTransferDetail(2, tokens, 1 ** 18, backup, owners);

        vm.prank(backup);
        recoverable.transferToBackup(transferDetails);

        assertEq(token0.balanceOf(owner), startBalanceOwner0 - 1 ** 18);
        assertEq(token0.balanceOf(backup), startBalanceBackup0 + 1 ** 18);
        (uint256 amount,,) = IAllowanceTransfer(permit2).allowance(owner, address(token0), address(recoverable));
        assertEq(amount, defaultAmount - 1 ** 18);
        (amount,,) = IAllowanceTransfer(permit2).allowance(owner, address(token1), address(recoverable));
        assertEq(amount, defaultAmount - 1 ** 18);
    }

    function testFail_transferToBackup_invalidCallerOwner() public {
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch = _defaultERC20PermitBatchAllowance(
            tokens, defaultAmount, defaultExpiration, defaultNonce, address(recoverable)
        );
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);

        vm.prank(owner);
        recoverable.addTokenPermits(permitBatch, sig1);

        address[] memory owners = AddressBuilder.fill(2, owner);
        IAllowanceTransfer.AllowanceTransferDetails[] memory transferDetails =
            StructBuilder.fillAllowanceTransferDetail(2, tokens, 1 ** 18, backup, owners);

        vm.prank(owner);
        recoverable.transferToBackup(transferDetails);
    }

    function testFail_transferToBackup_invalidCaller() public {
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch = _defaultERC20PermitBatchAllowance(
            tokens, defaultAmount, defaultExpiration, defaultNonce, address(recoverable)
        );
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);

        vm.prank(owner);
        recoverable.addTokenPermits(permitBatch, sig1);

        address[] memory owners = AddressBuilder.fill(2, owner);
        IAllowanceTransfer.AllowanceTransferDetails[] memory transferDetails =
            StructBuilder.fillAllowanceTransferDetail(2, tokens, 1 ** 18, backup, owners);

        recoverable.transferToBackup(transferDetails);
    }
}
