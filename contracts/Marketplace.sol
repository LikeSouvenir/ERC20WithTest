// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/SimpleERC20.sol";
import "./ERC721/BaseNFT.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract Marketplace {
    uint8 feePersent = 2;
    address feeReceiver; 

    struct TokenPrice {
        IERC20 payableToken; //bytes20
        bool isListed;       //bytes1
        uint256 price;
    }
    mapping(address NFT => mapping(uint tokenId => TokenPrice)) private _nftInfoMap;
    mapping(address NFT => uint[]) private _nftAddressToTokenIdMap;
    address[] private _allNFTs;

    constructor(address receiver) {
        feeReceiver = receiver;
    }

    modifier supportERC165(address addressNFT) {
        require(IERC165(addressNFT).supportsInterface(type(IERC721).interfaceId), "not support ERC165");
        _;
    }

    modifier notListed(address addressNFT, uint tokenId) {
        require(!_nftInfoMap[addressNFT][tokenId].isListed, "token is listed");
        _;
    }
    modifier isListed(address addressNFT, uint tokenId) {
        require(_nftInfoMap[addressNFT][tokenId].isListed, "token not listed or not dound");
        _;
    }

    function _haveRules(IERC721 addressNFT, uint tokenId) internal view {
        address tokenOwner = addressNFT.ownerOf(tokenId);
        require(tokenOwner == msg.sender || addressNFT.isApprovedForAll(tokenOwner, msg.sender) || addressNFT.getApproved(tokenId) == msg.sender, "permission denied");
    }

    function add(address addressNFT, uint tokenId, address addressToken, uint price) external supportERC165(addressNFT) {
        IERC721 contractNFT = IERC721(addressNFT);

        require(
            contractNFT.isApprovedForAll(msg.sender, address(this)) || 
            contractNFT.getApproved(tokenId) == address(this),
            "must set approval or operator"
        );

        _add(addressNFT, tokenId, addressToken, price);
    }

    function multipleAdd(address addressNFT, uint[] calldata tokenIds, address[] calldata addressesToken, uint[] calldata prices) external supportERC165(addressNFT) {
        require(IERC721(addressNFT).isApprovedForAll(msg.sender, address(this)), "must set operator");
        
        for (uint i = 0; i < tokenIds.length; i++) {
            _add(addressNFT, tokenIds[i], addressesToken[i], prices[i]);
        }
    }

    function _add(address addressNFT, uint tokenId, address addressToken, uint price) internal notListed(addressNFT, tokenId) {
        _haveRules(IERC721(addressNFT), tokenId);

        TokenPrice storage tokenInfo = _nftInfoMap[addressNFT][tokenId];

        if (address(tokenInfo.payableToken) == address(0)) { // токен ранее не выставлялся
            _nftAddressToTokenIdMap[addressNFT].push(tokenId);

            if (_nftAddressToTokenIdMap[addressNFT].length == 0)  // адрес контракта фигурирует в первый раз
                _allNFTs.push(addressNFT);
        }

        tokenInfo.payableToken = IERC20(addressToken);
        tokenInfo.price = price;
        tokenInfo.isListed = true;
    }

    function change(address addressNFT, uint tokenId, address addressToken, uint price) external  {
        _change(addressNFT, tokenId, addressToken, price);
    }

    function multipleChange(address addressNFT, uint[] calldata tokenIds, address[] calldata addressesToken, uint[] calldata prices) external  {
        for (uint i = 0; i < tokenIds.length; i++) {
            _change(addressNFT, tokenIds[i], addressesToken[i], prices[i]);
        }
    }

    function _change(address addressNFT, uint tokenId, address addressToken, uint price) internal isListed(addressNFT, tokenId) {
        _haveRules(IERC721(addressNFT), tokenId);

        TokenPrice storage tokenInfo = _nftInfoMap[addressNFT][tokenId];
        tokenInfo.payableToken = IERC20(addressToken);
        tokenInfo.price = price;
    }
    
    function cancel(address addressNFT, uint tokenId) external isListed(addressNFT, tokenId) {
        _haveRules(IERC721(addressNFT), tokenId);
        _nftInfoMap[addressNFT][tokenId].isListed = false;
    }

    function buy(address addressNFT, uint tokenId) external {
        _buy(addressNFT, tokenId);
    }

    function multiBuy(address addressNFT, uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            _buy(addressNFT, tokenIds[i]);
        }
    }

    function _buy(address addressNFT, uint tokenId) internal isListed(addressNFT, tokenId) {
        TokenPrice storage tokenInfo = _nftInfoMap[addressNFT][tokenId];
        uint fee = tokenInfo.price / 100 * feePersent;

        require(tokenInfo.payableToken.allowance(msg.sender, address(this)) >= tokenInfo.price + fee, "must be approve price + fee");

        address tokenOwner = IERC721(addressNFT).ownerOf(tokenId);
        
        tokenInfo.payableToken.transferFrom(msg.sender, feeReceiver, fee);
        tokenInfo.payableToken.transferFrom(msg.sender, tokenOwner, tokenInfo.price - fee);
        
        IERC721(addressNFT).safeTransferFrom(tokenOwner, msg.sender, tokenId);

        tokenInfo.isListed = false;
    }

    // покупатель может предложить офер на покупку NFT по своей цене и установить срок окончания офера
    // продавец может принять оффер на покупку NFT по цене, которую предложил покупатель
    function getReceiver() external view returns(address) {
        return feeReceiver;
    }

    function getFeePersent() external view returns(uint) {
        return feePersent;
    }

    function getAll() external view returns(address[] memory) {
        return _allNFTs;
    }

    function getTokensId(address addressNFT) external view returns(uint[] memory nfts) {
        nfts = _nftAddressToTokenIdMap[addressNFT];
    }

    function getByAddressAndId(
        address addressNFT, uint tokenId
    )external view isListed(addressNFT, tokenId) returns(IERC20 payableToken, bool checkListed, uint256 price) {
        TokenPrice storage tokenInfo = _nftInfoMap[addressNFT][tokenId];
        return (tokenInfo.payableToken, tokenInfo.isListed, tokenInfo.price);
    }
}
