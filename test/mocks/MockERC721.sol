// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 private _nextTokenId = 1;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    // Function to mint new tokens
    // Function to mint new tokens with a specific tokenId
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // Function to get the next token ID (for external reference if needed)
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }
}
