pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MultiSigTreasury is ERC1155{
    uint KEYS =0;
    uint public TotalTransactions=0;

    mapping(uint => KeyListings) keys;
    mapping(string => VoteOnTransaction) vote;
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
        bool status;
        uint pass;
        uint fail;
        uint voteCount;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI)ERC1155(URI){
        require(_VotesNeededToPass <= _totalKeys);
        KEYS =_totalKeys;
        uint countKeys;
        for(countKeys=0; countKeys < _totalKeys; countKeys++){
            keys[countKeys] = KeyListings(countKeys,true);
            _mint(msg.sender, countKeys, 1, "");
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
    //check vote summition total
    function checkTransactions() internal returns(bool){
        //set up voting count
        if(true){
            return true;
        } else {
            return false;
        }
    }
    //checks the voting status of a particular vote on a transactions
    function checkVote(string memory _keyNumb, string memory _transNumb) public CheckKeys returns(uint,bool){
        string memory checkStatus;
        checkStatus = string(abi.encodePacked(_transNumb,"-",_keyNumb));
        return (vote[checkStatus].Key,vote[checkStatus].status);
    }
    //view previouse & pending transactions
    function viewTransaction(uint _transactionNumb) public CheckKeys returns(uint,address,string memory,string memory){
        require(_transactionNumb <= TotalTransactions, " _transactionNumb cant exceed the totalTransactions");
        return (MSTrans[_transactionNumb].ammount ,MSTrans[_transactionNumb].toAddress ,MSTrans[_transactionNumb].topic ,MSTrans[_transactionNumb].messege);
    }
    //make a submittion to move funds to the contract
    function submitTransaction(uint _ammount, address _toAddress,string memory _topic,string memory _messege) public CheckKeys returns(bool){
        MSTrans[TotalTransactions] = MultiSigTransaction(_ammount,_toAddress,_topic,_messege,false,0,0,0);
        TotalTransactions++;
        return true;
    }
    //key holders can cast votes as a key for a transaction
    function confirmTransaction(string memory _TransactionNumber, bool _vote,uint _keyNumb) public CheckKeys returns(bool,bool){
        string memory castVote;
        require(balanceOf(msg.sender,_keyNumb)>0, "you must hold key");
        castVote = string(abi.encodePacked(_TransactionNumber,"-",_keyNumb));
        vote[castVote] = VoteOnTransaction(_keyNumb,_vote);
        //check if vote has been made
        //cast vote
        //show vote status
    }
    function executeTransaction() public CheckKeys returns(bool){}
    function revokeConfirmation() public CheckKeys returns(bool){}
}