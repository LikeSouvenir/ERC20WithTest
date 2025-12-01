// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import "./ERC20/SimpleERC20.sol";
import "./ERC721/BaseNFT.sol";
import "./Marketplace.sol";
import {Test} from "forge-std/Test.sol"; 
import {stdStorage, StdStorage} from "forge-std/Test.sol"; 
import {stdError} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

contract MarketPlaceTest is Test {
    struct TokenPrice {
        IERC20 payableToken; //bytes20
        bool isListed;       //bytes1
        uint256 price;
    }

    using stdStorage for StdStorage;
    address owner = vm.addr(1);
    address kate = vm.addr(2);
    address mix = vm.addr(3);
    address receiver = vm.addr(4);

    Marketplace marketContract;
    SimpleERC20 erc20Contract;
    BaseNFT erc721Contract;

    // multipleAdd
    uint[] tokensIds;
    address[] addressesToken;
    uint[] prices;
    function setUp() external {
        marketContract = new Marketplace(receiver);
        erc20Contract = new SimpleERC20("erc20", "E20");
        erc721Contract = new BaseNFT("erc721", "E721");

        erc721Contract.safeMint(owner, "QmXzZ7ZVwDRJ5acZzYbEdYbhZdgpFTcvCafXdis23XjB4W"); // tokenId = 0
        erc721Contract.safeMint(owner, "QmX553Mn6xpx1H8brBNPV6qcR2UBcFrC8LUYsVmctWk8xZ"); // tokenId = 1
        // erc721Contract.safeMint(kate, "QmSiK3Pg4tfYGKdHb4VjAm3NUDxTrtoCFfjRTLvfu8k5wn");  // tokenId = 2

        // multiple
        tokensIds = [0,1];
        addressesToken = [address(erc20Contract), address(erc20Contract)];
        prices = [99, 192];
    }
    // add
    function test_BadTokenAddress_add() public {
        vm.expectRevert();
        marketContract.add(address(erc20Contract), 1, address(erc20Contract), 100);
    }

    function test_NotHaveApproval_add() public {
        vm.expectRevert(bytes("must set approval or operator"));
        vm.prank(owner);
        marketContract.add(address(erc721Contract), tokensIds[0], addressesToken[0], prices[0]);
    }

    function test_GoodTokenAddress_add() public {
        vm.startPrank(owner);
        erc721Contract.setApprovalForAll(address(marketContract), true);
        marketContract.multipleAdd(address(erc721Contract), tokensIds, addressesToken, prices);

        bytes32 key = keccak256(abi.encode(address(erc721Contract), 1));
        bytes32 keyToKey = keccak256(abi.encode(tokensIds[0], key));

        bytes32 slot1 = vm.load(address(marketContract), keyToKey);
        bytes32 slot2 = vm.load(address(marketContract), bytes32(uint256(keyToKey) + 1));

        address payableTokenFromSlot = address(uint160(uint256(slot1)));
        uint priceFromSlot = uint(slot2);

        vm.assertEq(priceFromSlot, prices[0]);
        vm.assertEq(payableTokenFromSlot, address(erc20Contract));

        (IERC20 payableToken,,uint256 price) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        vm.assertEq(price, prices[0]);
        vm.assertEq(address(payableToken), address(erc20Contract));
    }

    function test_BadTokenId_add() public {
        uint notExistsTokenId = 100;
        erc721Contract.setApprovalForAll(address(marketContract), true);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, notExistsTokenId));
        marketContract.add(address(erc721Contract), notExistsTokenId, addressesToken[0], prices[0]);
    }

    function test_GoodTokenId_add() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        (IERC20 payableToken,,uint256 price) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        vm.assertEq(price, prices[0]);
        vm.assertEq(address(payableToken), addressesToken[0]);
    }

    function test_NonOwnedTokenId_add() public {
        vm.startPrank(mix);
        erc721Contract.setApprovalForAll(address(marketContract), true);
        vm.expectRevert(bytes("permission denied"));
        marketContract.add(address(erc721Contract), tokensIds[0], addressesToken[0], prices[0]);
    }
    // multipleAdd

    function test_BadTokenAddress_multipleAdd() public {
        vm.expectRevert();
        marketContract.multipleAdd(address(erc20Contract), tokensIds, addressesToken, prices);
    }

    function test_NotHaveApproval_multipleAdd() public {
        vm.prank(owner);
        vm.expectRevert(bytes("must set operator"));
        marketContract.multipleAdd(address(erc721Contract), tokensIds, addressesToken, prices);
    }

    function test_GoodTokenAddress_multipleAdd() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        bytes32 key = keccak256(abi.encode(address(erc721Contract), 1));
        bytes32 keyToKey = keccak256(abi.encode(tokensIds[0], key));

        bytes32 slot1 = vm.load(address(marketContract), keyToKey);
        bytes32 slot2 = vm.load(address(marketContract), bytes32(uint256(keyToKey) + 1));

        address payableTokenFromSlot = address(uint160(uint256(slot1)));
        uint priceFromSlot = uint(slot2);

        vm.assertEq(priceFromSlot, prices[0]);
        vm.assertEq(payableTokenFromSlot, address(erc20Contract));

        (IERC20 payableToken,,uint256 price) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        vm.assertEq(price, prices[0]);
        vm.assertEq(address(payableToken), address(erc20Contract));
    }

    function test_BadTokenId_multipleAdd() public {
        uint[] memory badTokensIds = new uint[] (2);
        badTokensIds[0] = 112;
        badTokensIds[1] = 999;

        erc721Contract.setApprovalForAll(address(marketContract), true);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, badTokensIds[0]));
        marketContract.multipleAdd(address(erc721Contract), badTokensIds, addressesToken, prices);
    }

    function test_GoodTokenId_multipleAdd() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        (IERC20 payableToken,,uint256 price) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);

        vm.assertEq(price, prices[0]);
        vm.assertEq(address(payableToken), address(erc20Contract));
    }

    function test_NonOwnedTokenId_multipleAdd() public {
        vm.startPrank(mix);
        erc721Contract.setApprovalForAll(address(marketContract), true);
        vm.expectRevert(bytes("permission denied"));
        marketContract.multipleAdd(address(erc721Contract), tokensIds, addressesToken, prices);
    }
    // change
    function test_Correct_change() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        (IERC20 payableTokenBefore,,uint256 priceBefore) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        
        address newErc20 = address(new SimpleERC20("new20", "N20"));
        marketContract.change(address(erc721Contract), tokensIds[0], newErc20, prices[1]);

        (IERC20 payableTokenAfter,,uint256 priceAfter) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);

        vm.assertNotEq(address(payableTokenBefore), address(payableTokenAfter));
        vm.assertNotEq(priceBefore, priceAfter);
    }

    function test_NotOwnedToken_change() public {
        _setOwnerApprovalAndAddTwoDefaultNft();
        vm.stopPrank();

        vm.startPrank(kate);
        address newErc20 = address(new SimpleERC20("new20", "N20"));
        uint newPrice = 100;

        vm.expectRevert(bytes("permission denied"));
        marketContract.change(address(erc721Contract), tokensIds[0], newErc20, newPrice);
    }

    function test_NotExistsToken_change() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        uint notExistsTokenId = 100;

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.change(address(erc721Contract), notExistsTokenId, addressesToken[0], prices[0]);
    }

    function test_NotListedToken_change() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        marketContract.cancel(address(erc721Contract), tokensIds[0]);

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.change(address(erc721Contract), tokensIds[0], addressesToken[0], prices[0]);
    }
    // multipleChange
    function test_Correct_multipleChange() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        (IERC20 payableTokenBefore,,) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        
        address newErc20 = address(new SimpleERC20("new20", "N20"));
        address[] memory badPayableToken = new address[] (2);
        badPayableToken[0] = newErc20;
        badPayableToken[1] = newErc20;
        marketContract.multipleChange(address(erc721Contract), tokensIds, badPayableToken, prices);

        (IERC20 payableTokenAfter,,) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);

        vm.assertNotEq(address(payableTokenBefore), address(payableTokenAfter));
    }

    function test_NotOwnedToken_multipleChange() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        vm.startPrank(kate);

        vm.expectRevert(bytes("permission denied"));
        marketContract.multipleChange(address(erc721Contract), tokensIds, addressesToken, prices);
    }

    function test_NotExistsToken_multipleChange() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        uint[] memory notExistsTokenIds = new uint[](2);
        notExistsTokenIds[0] = 100;

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.multipleChange(address(erc721Contract), notExistsTokenIds, addressesToken, prices);
    }

    function test_NotListedToken_multipleChange() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        marketContract.cancel(address(erc721Contract), tokensIds[0]);

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.multipleChange(address(erc721Contract), tokensIds, addressesToken, prices);
    }
    // cancel
    function test_Correct_cancel() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        marketContract.cancel(address(erc721Contract), tokensIds[0]);

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
    }

    function test_NotExistsToken_cancel() public {
        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.cancel(address(erc721Contract), tokensIds[0]);
    }

    function test_NotListedToken_cancel() public {
        _setOwnerApprovalAndAddTwoDefaultNft();

        marketContract.cancel(address(erc721Contract), tokensIds[0]);

        vm.expectRevert(bytes("token not listed or not dound"));
        marketContract.cancel(address(erc721Contract), tokensIds[0]);
    }
    // buy
    function test_correct_buy() public {
        _setOwnerApprovalAndAddTwoDefaultNft();
        vm.stopPrank();

        vm.prank(address(marketContract));
        erc20Contract.mint(mix, 100 * 10 ** erc20Contract.decimals());
        uint balanceBefore = erc20Contract.balanceOf(mix);
        (,,uint tokenPrice) = marketContract.getByAddressAndId(address(erc721Contract), tokensIds[0]);
        uint fee = tokenPrice / 100 * marketContract.getFeePersent();
        uint collision = 1;

        vm.startPrank(mix);
        erc20Contract.approve(address(marketContract), tokenPrice + fee + collision);

        marketContract.buy(address(erc721Contract), tokensIds[0]);

        vm.assertEq(erc20Contract.balanceOf(mix), balanceBefore - tokenPrice);
        vm.assertEq(erc721Contract.ownerOf(tokensIds[0]), mix);
    }
    
    function _setOwnerApprovalAndAddTwoDefaultNft() internal {
        vm.startPrank(owner);
        erc721Contract.setApprovalForAll(address(marketContract), true);
        marketContract.multipleAdd(address(erc721Contract), tokensIds, addressesToken, prices);
    }
    
}