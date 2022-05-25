pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract Treasury is ERC1155{
    uint KEYS =0;
    uint public TotalTransactions=0;
    uint private i;

    mapping(uint => KeyListings) keys;
    mapping(uint => VoteOnTransaction) vote;
    mapping(uint => MultiSigTransaction) MSTrans;
    //list Keys
    struct KeyListings{
        uint count;
        bool exist;
    }
    //cast vote for transaction
    struct VoteOnTransaction{
        uint Key;
        bool status;
    }
    struct MultiSigTransaction{
        uint ammount;
        address toAddress;
        string topic;
        string messege;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI)ERC1155(URI){
        require(_VotesNeededToPass <= _totalKeys);
        KEYS =_totalKeys;
        for(i=0; i < _totalKeys; i++){
            keys[i] = KeyListings(i,true);
            _mint(msg.sender, i, 1, "");
        }
    }
    //modifier checks to see if user has a key before executing the function
    modifier CheckKeys{
        (bool keyStatus,uint keyNumb) = checkTokens(msg.sender);
        require(keyStatus == true);
        _;
    }
    //internal function checks to see if user has key
    function checkTokens(address _user) internal returns(bool,uint){
        uint i;
        for(i=0; i <= KEYS; i++){
            if(balanceOf(_user,i) > 0){
                return (true,i);
            } else if(i == KEYS){
                return (false,i);
            }
        }       
    }
    //view previouse & pending transactions
    function viewTransaction(uint _transactionNumb) public CheckKeys returns(uint,address,string memory,string memory){
        require(_transactionNumb <= TotalTransactions, " _transactionNumb cant exceed the totalTransactions");
        return (MSTrans[_transactionNumb].ammount ,MSTrans[_transactionNumb].toAddress ,MSTrans[_transactionNumb].topic ,MSTrans[_transactionNumb].messege);
    }
    //view transactions in contract
    function checkTransactions() internal returns(uint,uint){}
    //make a submittion to move funds to the contract
    function submitTransaction(uint _ammount, address _toAddress,string memory _topic,string memory _messege) public CheckKeys returns(bool){
        MSTrans[TotalTransactions] = MultiSigTransaction(_ammount,_toAddress,_topic,_messege);
        TotalTransactions++;
        return true;
    }
    function confirmTransaction(uint _TransactionNumber, bool _vote) public CheckKeys returns(bool,bool){}
    function executeTransaction() public CheckKeys returns(bool){}
    function revokeConfirmation() public CheckKeys returns(bool){}
}