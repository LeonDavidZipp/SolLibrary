// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Recoverable} from "../src/Recoverable.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import {PermitSignature} from "permit2/test/utils/PermitSignature.sol";
import {TokenProvider} from "permit2/test/utils/TokenProvider.sol";
import {AddressBuilder} from "permit2/test/utils/AddressBuilder.sol";

// contract MyToken1 is ERC20, Ownable {
//     constructor(address owner, string memory name, string memory symbol) ERC20(name, symbol) Ownable(owner) {}

//     function mint(address to, uint256 amount) external onlyOwner {
//         _mint(to, amount);
//     }
// }

// contract MyToken2 is ERC20, Ownable {
//     constructor(address owner, string memory name, string memory symbol) ERC20(name, symbol) Ownable(owner) {}

//     function mint(address to, uint256 amount) external onlyOwner {
//         _mint(to, amount);
//     }
// }

// contract MyToken3 is ERC20, Ownable {
//     constructor(address owner, string memory name, string memory symbol) ERC20(name, symbol) Ownable(owner) {}

//     function mint(address to, uint256 amount) external onlyOwner {
//         _mint(to, amount);
//     }
// }

contract RecoveryableTest is Test, DeployPermit2, PermitSignature, TokenProvider {
    using AddressBuilder for address[];
    uint256 public constant ownerPK = 0x12341234;
    address public immutable owner = vm.addr(ownerPK);
    address public constant backup = address(2);
    uint160 public immutable defaultAmount = 10 ** 18;
    uint48 public defaultNonce = 0;
    uint48 public immutable defaultExpiration = uint48(block.timestamp + 5);
    Recoverable public recoverable;
    address public immutable permit2 = deployPermit2();
    bytes32 public immutable DOMAIN_SEPARATOR = IAllowanceTransfer(permit2).DOMAIN_SEPARATOR();

    // IAllowanceTransfer.PermitDetails[] public permitDetails;
    // IAllowanceTransfer.AllowanceTransferDetails[] public allowanceDetails;

    // IAllowanceTransfer.PermitBatch public permitBatch;
    // IAllowanceTransfer.AllowanceTransferDetails[] public transferDetails;

    // function preparePermitDetails() internal returns (IAllowanceTransfer.PermitDetails[] memory details) {
    //     details = new IAllowanceTransfer.PermitDetails[](2);
    //     details[0] = IAllowanceTransfer.PermitDetails({
    //         token: supportedTokens[0],
    //         amount: 100,
    //         expiration: block.timestamp + 1000,
    //         nonce: 0
    //     });
    //     details[1] = IAllowanceTransfer.PermitDetails({
    //         token: supportedTokens[1],
    //         amount: 100,
    //         expiration: block.timestamp + 1000,
    //         nonce: 0
    //     });
    // }

    // function prepareAllowanceTransferDetails()
    //     internal
    //     returns (IAllowanceTransfer.AllowanceTransferDetails[] memory details)
    // {
    //     details = new IAllowanceTransfer.AllowanceTransferDetails[](2);
    //     details[0] = IAllowanceTransfer.AllowanceTransferDetails({
    //         token: supportedTokens[0],
    //         spender: firstResponder,
    //         amount: 100
    //     });
    //     details[1] = IAllowanceTransfer.AllowanceTransferDetails({
    //         token: supportedTokens[1],
    //         spender: firstResponder,
    //         amount: 100
    //     });
    // }

    function setUp() public {
        initializeERC20Tokens();

        setERC20TestTokens(owner);
        setERC20TestTokenApprovals(vm, owner, permit2);
        // IAllowanceTransfer.PermitBatch memory permit =
        address[] memory tokens = AddressBuilder.fill(1, address(token0)).push(address(token1));
        IAllowanceTransfer.PermitBatch memory permitBatch =
            defaultERC20PermitBatchAllowance(tokens, defaultAmount, defaultExpiration, 1);
        // first token nonce is 1, second token nonce is 0
        permitBatch.details[1].nonce = 0;
        bytes memory sig1 = getPermitBatchSignature(permitBatch, ownerPK, DOMAIN_SEPARATOR);
    }
}
