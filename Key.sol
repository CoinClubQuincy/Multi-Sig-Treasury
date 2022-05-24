pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract Treasury is ERC1155{
    uint KEYS =0;
    uint i;
    mapping(uint => KeyListings) keys;

    struct KeyListings{
        uint count;
        bool exist;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI)ERC1155(URI){
        require(_VotesNeededToPass <= _totalKeys);
        for(i=0; i < _totalKeys; i++){
            keys[i] = KeyListings(i,true);
        }
        _mint(msg.sender, i, _totalKeys, "");
    }
    //modifier checks to see if user has a key before executing the function
    modifier CheckKeys{
        require(balanceOf(msg.sender,0) > 0);
        _;
    }

    function submitTransaction() public CheckKeys returns(bool){}
    function confrimTransaction() public CheckKeys returns(bool){}
    function executeTransaction() public CheckKeys returns(bool){}
    function revokeConfirmation() public CheckKeys returns(bool){}
}