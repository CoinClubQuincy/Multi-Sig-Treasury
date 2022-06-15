pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
interface MultiSigTreasury_interface{
    function checkVote(string memory _keyNumb, string memory _transNumb) external returns(uint,bool);
    function viewTransaction(uint _transactionNumb) external returns(uint,address,string memory,string memory,bool,uint);
    function submitTransaction(uint _ammount, address _toAddress,string memory _topic,string memory _messege) external returns(bool);
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) external returns(uint,uint);
    function revokeConfirmation(uint _TransactionNumber,string memory _castVote) external  returns(bool);
}

contract MultiSigTreasury is ERC1155{
    uint totalKeys =0;
    uint public TotalTransactions=0;
    uint public VotesNeededToPass;
    //Events for Proposals and executions
    event Proposal(uint _transactionNumb, string _memo);
    event Execute(uint _transactionNumb, string _memo);
    //mappings of structs
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
        bool exist;
    }
    //transaction request
    struct MultiSigTransaction{
        uint amount;
        address toAddress;
        string topic;
        string messege;
        bool status;
        uint pass;
        uint fail;
        uint voteCount;
        bool exist;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI)ERC1155(URI){
        require(_VotesNeededToPass <= _totalKeys, "you cant have more votes needed than keys created");
        totalKeys =_totalKeys;
        VotesNeededToPass = _VotesNeededToPass;
        uint countKeys;
        for(countKeys=0; countKeys < _totalKeys; countKeys++){
            keys[countKeys] = KeyListings(countKeys,true);
            _mint(msg.sender, countKeys, 1, "");
        }
    }
    //modifier checks to see if user has a key before executing the function
    modifier CheckKeys{
        (bool keyStatus,uint keyNumb) = checkTokens(msg.sender);
        require(keyStatus == true, "You must hold a Key to access this function");
        _;
    }
    //internal function checks to see if user has key
    function checkTokens(address _user) internal returns(bool,uint){
        uint i;
        for(i=0; i <= totalKeys; i++){
            if(balanceOf(_user,i) > 0){
                return (true,i);
            } else if(i == totalKeys){
                return (false,i);
            }
        }       
    }
    //check vote summition total
    function checkTotal(uint _TransactionNumber) internal returns(bool){
        //set up voting count
        if(MSTrans[_TransactionNumber].pass >= VotesNeededToPass){
            executeTransaction(_TransactionNumber);
            return true;
        } else {
            return false;
        }
    }
    //check to see if holder is holdin ther key
    //1 key per address if an address holds multiple key they will only be able to sign one
    function checkKey(uint _checkKey) internal returns(bool){
        (bool keyStatus,uint keyNumb) = checkTokens(msg.sender);
        require(keyStatus == true && keyNumb == _checkKey, "You must hold a Key to access this function");
        return true;
    }
    //checks the voting status of a particular vote on a transactions
    function checkVote(uint _keyNumb,uint _transNumb) public CheckKeys returns(uint,bool,bool){
        string memory checkStatus;
        checkStatus = string(abi.encodePacked(Strings.toString(_transNumb),"-",Strings.toString(_keyNumb)));
        return (vote[checkStatus].Key,vote[checkStatus].status,vote[checkStatus].exist);
    }
    //view previouse & pending transactions
    function viewTransaction(uint _transactionNumb) public CheckKeys returns(uint,address,string memory,bool,uint,uint){
        require(_transactionNumb <= TotalTransactions, " _transactionNumb cant exceed the totalTransactions");
        return (MSTrans[_transactionNumb].amount ,MSTrans[_transactionNumb].toAddress ,string.concat(MSTrans[_transactionNumb].topic ,"-",MSTrans[_transactionNumb].messege),MSTrans[_transactionNumb].status ,MSTrans[_transactionNumb].pass,MSTrans[_transactionNumb].fail);
    }
    //make a submittion to move funds to the contract
    function submitProposal(uint _ammount, address _toAddress,string memory _topic,string memory _messege) public CheckKeys returns(bool){
        require(address(this).balance >= _ammount, "Not enough funds in contract");
        MSTrans[TotalTransactions] = MultiSigTransaction(_ammount,_toAddress,_topic,_messege,false,0,0,0,true);
        emit Proposal(TotalTransactions,"Transactionan Proposal Made");
        TotalTransactions++;
        return true;
    }
    //key holders can cast votes as a key for a transaction
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) public CheckKeys returns(uint,uint,string memory){
        string memory castVote;
        castVote = string(abi.encodePacked(Strings.toString(_TransactionNumber),"-",Strings.toString(_keyNumb)));
        require(MSTrans[_TransactionNumber].status == false, "Contract Transaction Completed...no futher confrimation votes can be cast");
        require(vote[castVote].exist == false, "vote has been cast already");
        require(checkKey(_keyNumb) == true, "you must be the holder of the key");

        vote[castVote] = VoteOnTransaction(_keyNumb,_vote,true);
        if(_vote== true){
            MSTrans[_TransactionNumber].pass++;
        }else{
            MSTrans[_TransactionNumber].fail++;
        }
        checkTotal(_TransactionNumber);
        return (MSTrans[_TransactionNumber].pass,MSTrans[_TransactionNumber].fail,castVote);
    }
    //Executes payment ticket after parties have voted on it
    function executeTransaction(uint _TransactionNumber) internal returns(bool){
        address _address = MSTrans[_TransactionNumber].toAddress;
        MSTrans[_TransactionNumber].status = true;

        require(address(this).balance >= MSTrans[_TransactionNumber].amount, "Not enough funds in contract transaction canceled");
        emit Execute(_TransactionNumber,"Transaction successful!");
        payable(_address).transfer(MSTrans[_TransactionNumber].amount);
        return true;
    }
    //remove vote if transaction hasent been confirmed yet
    function revokeConfirmation(uint _TransactionNumber, uint _keyNumb) public CheckKeys returns(string memory){
        string memory castVote = string(abi.encodePacked(Strings.toString(_TransactionNumber),"-",Strings.toString(_keyNumb)));
        require(MSTrans[_TransactionNumber].status ==false && MSTrans[_TransactionNumber].exist == true ,"Transaction already confirmed");
        require(vote[castVote].exist == true, "you havent casted a vote");
        require(checkKey(_keyNumb) == true, "you must be the holder of the key");
        //remove vote
        if(vote[castVote].status == true){
            MSTrans[_TransactionNumber].pass--;
            vote[castVote] = VoteOnTransaction(_keyNumb,false,false);
            return "Vote Removed Pass: -1";
        }else{
            MSTrans[_TransactionNumber].fail--;
            vote[castVote] = VoteOnTransaction(_keyNumb,false,false);
            return "Vote Removed Fail: -1";
        }        
    }
    // upload funds to contract
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}