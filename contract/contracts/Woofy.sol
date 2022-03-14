// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Utils.sol";

contract Woofy is ERC721URIStorage, ERC721Enumerable {
    /* CONSTANTS */
    uint256 constant PRICE = 0.001 ether; // NFT PRICE
    uint256 constant COOLDOWN_PERIOD = 15 minutes; // Cooldown period, before which a signer cannot mint

    /* Counter for TokenId */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    /* Mapping to store info about new NFTs: whether their metadata should be changed */
    mapping(address => IdAndTime) newMintAddressToIdAndTime;

    /* Constructor */
    constructor() payable ERC721("WOOFY", "WFY") {
        _tokenId.increment();
    }

    /* Creates a new NFT */
    function createNFT() external payable {
        // Check if user is paying the correct amount to purchase
        require(
            msg.value == PRICE,
            strcat(
                "INCORRECT AMOUNT OF WEI SENT! SEND ",
                Strings.toString(PRICE)
            )
        );

        // Check if an exisiting incomplete NFT is in progress or cooldown is not over yet
        require(
            (newMintAddressToIdAndTime[msg.sender].tokenId == 0 ||
                block.timestamp -
                    newMintAddressToIdAndTime[msg.sender].timestamp >=
                COOLDOWN_PERIOD),
            "SIGNER HAS A PENDING NFT! WAITING FOR COOLDOWN."
        );

        // Mint token
        uint256 newTokenId = _tokenId.current();
        _safeMint(msg.sender, newTokenId);
        newMintAddressToIdAndTime[msg.sender] = IdAndTime(
            newTokenId,
            block.timestamp
        );

        // Increment token id
        _tokenId.increment();
    }

    /* Returns new, incomplete token id that a signer may have */
    function getNewTokenId() public view returns (uint256) {
        return newMintAddressToIdAndTime[msg.sender].tokenId;
    }

    /* Sets URI on newly created NFT */
    function setNewTokenURI(string memory _nftImageURI) external {
        // Checks to make sure URI of existing NFTs are not modified, only a new one
        uint256 newTokenId = newMintAddressToIdAndTime[msg.sender].tokenId;
        require(
            newTokenId != 0,
            "SIGNER DOES NOT HAVE A NEWLY MINTED, INCOMPLETE NFT!"
        );
        require(
            block.timestamp - newMintAddressToIdAndTime[msg.sender].timestamp <
                COOLDOWN_PERIOD,
            "SIGNER HAS NO PENDING NFT!"
        );

        // Create new token's URI
        string memory tokenMetadataJson = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"Woofy","description":"Woofy is a cute dog, likes to play superhero in a cape. Each NFT of him is marked with a unique number. Get yours today!!","attributes":[{"trait_type":"Cuteness","value":100,"display_type":"boost_number"},{"trait_type":"Heroism","value":75,"display_type":"boost_number"}],"image":"',
                    _nftImageURI,
                    '"}'
                )
            )
        );
        string memory newTokenURI = string(
            bytes(
                abi.encodePacked(
                    "data:application/json;base64,",
                    tokenMetadataJson
                )
            )
        );

        // Set new token's uri
        _setTokenURI(newTokenId, newTokenURI);
        delete newMintAddressToIdAndTime[msg.sender];
    }

    /* Retrieves NFTs owned by a signer */
    function getAllNftsOwned() public view returns(NFT[] memory) {
        uint256 numOfNftsOwned = balanceOf(msg.sender);
        NFT[] memory nfts = new NFT[](numOfNftsOwned);
        uint256 tokenId = 0;
        for(uint256 i = 0; i < numOfNftsOwned; i++){
            tokenId = tokenOfOwnerByIndex(msg.sender, i);
            string memory tokenUri = tokenURI(tokenId);
            nfts[i] = NFT(tokenId, tokenUri);
        }
        return nfts;
    }

    /* OVERRIDES */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
