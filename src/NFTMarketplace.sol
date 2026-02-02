// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title NFTMarketplace
 * @dev A simple marketplace for buying and selling ERC721 NFTs with ETH
 */
contract NFTMarketplace is IERC721Receiver {
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    // Mapping from NFT contract address => token ID => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event NFTSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price
    );

    event ListingCancelled(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    /**
     * @dev List an NFT for sale
     * @param nftContract The address of the ERC721 contract
     * @param tokenId The token ID to list
     * @param price The price in wei (ETH)
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");

        IERC721 nft = IERC721(nftContract);

        // Check that the caller owns the NFT
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this NFT");

        // Check that the listing doesn't already exist
        require(
            !listings[nftContract][tokenId].active,
            "NFT is already listed"
        );

        // Transfer NFT from seller to marketplace contract
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        // Create listing
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }

    /**
     * @dev Buy an NFT that is listed for sale
     * @param nftContract The address of the ERC721 contract
     * @param tokenId The token ID to buy
     */
    function buyNFT(address nftContract, uint256 tokenId) external payable {
        Listing storage listing = listings[nftContract][tokenId];

        require(listing.active, "NFT is not listed for sale");
        require(msg.value == listing.price, "Incorrect payment amount");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Mark listing as inactive
        listing.active = false;

        // Transfer NFT from marketplace to buyer
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        // Transfer ETH to seller
        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "Failed to send ETH to seller");

        emit NFTSold(nftContract, tokenId, seller, msg.sender, price);
    }

    /**
     * @dev Cancel a listing (only the seller can cancel)
     * @param nftContract The address of the ERC721 contract
     * @param tokenId The token ID to cancel listing for
     */
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];

        require(listing.active, "NFT is not listed for sale");
        require(
            listing.seller == msg.sender,
            "Only the seller can cancel the listing"
        );

        // Mark listing as inactive
        listing.active = false;

        // Transfer NFT back to seller
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit ListingCancelled(nftContract, tokenId, msg.sender);
    }

    /**
     * @dev Get listing details
     * @param nftContract The address of the ERC721 contract
     * @param tokenId The token ID
     * @return seller The address of the seller
     * @return price The price in wei
     * @return active Whether the listing is active
     */
    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (address seller, uint256 price, bool active) {
        Listing memory listing = listings[nftContract][tokenId];
        return (listing.seller, listing.price, listing.active);
    }

    /**
     * @dev Required to receive ERC721 tokens via safeTransferFrom
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
