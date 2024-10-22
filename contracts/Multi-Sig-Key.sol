pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface MultiSigTreasury_interface{
    function checkVote(uint _keyNumb,uint _transNumb) external returns(uint,bool,bool);
    function submitProposal(uint [] memory _amount, address [] memory _address,string [] memory _topic) external returns(bool);
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) external returns(uint,uint,string memory);
    function revokeConfirmation(uint _TransactionNumber, uint _keyNumb) external returns(string memory);
    function checkTransactionStatus(uint _transNumb) external returns(bool);
}

contract MultiSigTreasury is ERC1155,MultiSigTreasury_interface{
    uint public totalKeys =0;
    uint public TotalTransactions=0;
    uint public VotesNeededToPass;
    uint public XRCcontracts=0;
    //Events for Proposals and executions
    event Proposal(uint _transactionNumb, string _memo);
    event Execute(uint _transactionNumb, string _memo);
    event BlankExecute(uint _TransactionNumber, string _memo);
    event Vote(string _memo,uint _key);
    //mappings of structs
    mapping(uint => KeyListings) keys;
    mapping(string => VoteOnTransaction) vote;
    mapping(uint => MultiSigTransaction) MSTrans;
    mapping(uint => XRCTokens) XRC;
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
    //list of XRCTokens
    struct XRCTokens{
        address XRCcontract;
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
        address XRC;
        uint tokenNumb;
        string call;
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI) payable ERC1155(URI){
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
    //checks to see if a contract function is being requested to be called
    function checkTransactionExecution(uint _entryLength,string memory _transaction) internal returns(string memory){
        if(_entryLength == 2){
            return _transaction;
        } else {
            return "";
        }
    }
    //check vote summition total
    function checkTotal(uint _TransactionNumber) internal returns(bool){
        //set up voting count
        if(MSTrans[_TransactionNumber].pass >= VotesNeededToPass){
            executeTransaction(_TransactionNumber);
            return true;
        } else if(MSTrans[_TransactionNumber].fail >= VotesNeededToPass) {
            MSTrans[_TransactionNumber].status = true;
            emit Execute(_TransactionNumber,"Vote Failed!");
            return true;
        }else {
            return false;
        }
    }
    //check to see if holder is holding their key
    //1 key per address if an address holds multiple keys they will only be able to sign one
    function checkKey(uint _checkKey) internal returns(bool){
        (bool keyStatus,uint keyNumb) = checkTokens(msg.sender);
        require(keyStatus == true && keyNumb == _checkKey, "You must hold a Key to access this function");
        return true;
    }
    //check is tranaction has passed
    function checkTransactionStatus(uint _transNumb) public CheckKeys returns(bool){
        return MSTrans[_transNumb].status;
    }
    //checks the voting status of a particular vote on a transactions
    function checkVote(uint _keyNumb,uint _transNumb) public CheckKeys returns(uint,bool,bool){
        string memory checkStatus;
        checkStatus = string(abi.encodePacked(Strings.toString(_transNumb),"-",Strings.toString(_keyNumb)));
        return (vote[checkStatus].Key,vote[checkStatus].status,vote[checkStatus].exist);
    }
    //view previouse & pending transactions
    function ViewTransactions() public CheckKeys returns(MultiSigTransaction[] memory){
        MultiSigTransaction[] memory All_Transactions = new MultiSigTransaction[](TotalTransactions);
        for(uint i = 0; i < TotalTransactions; i++){
            MultiSigTransaction storage NewAll_Transactions = MSTrans[i];
            All_Transactions[i] = NewAll_Transactions;
        }
        return (All_Transactions);
    }  

    //make a submittion to move funds to the contract
    function submitProposal(uint [] memory _amount, address [] memory _address,string [] memory _topic) public CheckKeys returns(bool){
        if(_address.length == 1 ){
            require(address(this).balance >= _amount[0], "Not enough funds in contract");
            MSTrans[TotalTransactions] = MultiSigTransaction(_amount[0],_address[0],_topic[0],_topic[1],false,0,0,0,true,0x0000000000000000000000000000000000000000,0,checkTransactionExecution(_topic.length,_topic[2]));
            emit Proposal(TotalTransactions,"Transactionan Proposal Made");
            TotalTransactions++;
            return true;
        } else if(_address.length == 2 && _amount.length == 1){
            require(ERC20(_address[1]).balanceOf(address(this)) >= _amount[0], "Not enough XRC funds in contract");
            MSTrans[TotalTransactions] = MultiSigTransaction(_amount[0],_address[0],_topic[0],_topic[1],false,0,0,0,true,_address[1],0,"");
            emit Proposal(TotalTransactions,"XRC Transactionan Proposal Made");
            TotalTransactions++;
            return true;
        }else if(_address.length == 2 && _amount.length == 2){
            MSTrans[TotalTransactions] = MultiSigTransaction(_amount[0],_address[0],_topic[0],_topic[1],false,0,0,0,true,_address[1],_amount[1],"");
            emit Proposal(TotalTransactions,"XRC NFT Transactionan Proposal Made");
            TotalTransactions++;           
        } else {
            return false;
        }
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
        emit Vote("Vote Casted",_keyNumb);

        return (MSTrans[_TransactionNumber].pass,MSTrans[_TransactionNumber].fail,castVote);
    }
    //Executes payment ticket after parties have voted on it
    //0x0000000000000000000000000000000000000000 as address will produce a blank vote
    //0x0000000000000000000000000000000000000000 as XRC will submit XDC transaction and an adress contract will send the addres token
    function executeTransaction(uint _TransactionNumber) internal returns(bool){
        address _address = MSTrans[_TransactionNumber].toAddress;
        MSTrans[_TransactionNumber].status = true;

        if(MSTrans[_TransactionNumber].XRC == 0x0000000000000000000000000000000000000000 ){
            if(_address != 0x0000000000000000000000000000000000000000){
                require(address(this).balance >= MSTrans[_TransactionNumber].amount, "Not enough funds in contract transaction canceled");
                payable(_address).transfer(MSTrans[_TransactionNumber].amount);                
            } else{
                emit BlankExecute(_TransactionNumber,"Vote Passed!");
            }
        } else if (keccak256(abi.encode(MSTrans[_TransactionNumber].call)) == keccak256(abi.encode("XRC20")) && MSTrans[_TransactionNumber].XRC != 0x0000000000000000000000000000000000000000){
            ERC20(MSTrans[_TransactionNumber].XRC).transfer(MSTrans[_TransactionNumber].toAddress, MSTrans[_TransactionNumber].amount);
        } else if(keccak256(abi.encode(MSTrans[_TransactionNumber].call)) == keccak256(abi.encode("XRC20")) && MSTrans[_TransactionNumber].XRC != 0x0000000000000000000000000000000000000000){
            XRC1155_XRC721Send(MSTrans[_TransactionNumber].XRC,MSTrans[_TransactionNumber].tokenNumb,MSTrans[_TransactionNumber].amount);
        }
        emit Execute(_TransactionNumber,"Transaction successful!");
        return true;
    }
    //check to see if contract is XRC1155 or XRC721 and send token
    function XRC1155_XRC721Send(address _contractAddress, uint _tokenNumb,uint _amount) internal returns(bool){
        if(IERC721(_contractAddress).supportsInterface(0x80ac58cd) == true){
            ERC721(_contractAddress).safeTransferFrom(address(this), _contractAddress, _tokenNumb,"");
        }else{
            ERC1155(_contractAddress).safeTransferFrom(address(this), _contractAddress, _tokenNumb,_amount,"");
        }
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
    //ERC1155Received fuctions
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    // send funds to contract
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
