pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Creates simple XRC20 Token to test with
contract XRC20 is ERC20{
    constructor(uint256 initialSupply) ERC20("Test USD", "TUSD") {
        _mint(msg.sender, initialSupply);
    }
}
//Creates simple XRC721 Token to test with
contract XRC721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor() ERC721("Test Token", "TST-NFT") {}
    function awardItem(address player, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }
}
//Creates simple XRC1155 Token to test with
contract XRC1155 is ERC1155 {
    uint256 public constant Token_1 = 0;
    uint256 public constant Token_2 = 1;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _mint(msg.sender, Token_1, 1, "");
        _mint(msg.sender, Token_2, 100, "");
    }
}