pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface MultiSigTreasury_interface{
    function checkVote(uint _keyNumb,uint _transNumb) external view returns(uint,bool,bool);
    function submitProposal(uint [] memory _amount, address [] memory _address,string [] memory _topic) external returns(bool);
    function submitCallProposal(address _target, uint _value, bytes memory _data, string memory _topic, string memory _message) external returns(bool);
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) external returns(uint,uint,string memory);
    function revokeConfirmation(uint _TransactionNumber, uint _keyNumb) external returns(string memory);
    function checkTransactionStatus(uint _transNumb) external view returns(bool);
}

/// @title Multi-signature treasury controlled by tokenized keys
/// @notice Each key is an ERC-1155 token. Keys vote on proposals, and a proposal executes
/// when enough keys vote yes. It closes as soon as it can no longer pass.
contract MultiSigTreasury is ERC1155,MultiSigTreasury_interface,ReentrancyGuard{
    using SafeERC20 for IERC20;

    string private constant KIND_XRC20 = "XRC20";
    string private constant KIND_NFT = "NFT";
    string private constant KIND_CALL = "CALL";
    bytes4 private constant INTERFACE_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ERC1155 = 0xd9b67a26;

    uint public totalKeys =0;
    uint public TotalTransactions=0;
    uint public VotesNeededToPass;
    uint public constant PROPOSAL_LIFETIME = 30 days;
    mapping(uint => uint) public proposalExpiry;
    //Events for Proposals and executions
    event Proposal(uint _transactionNumb, string _memo);
    event Execute(uint _transactionNumb, string _memo);
    event BlankExecute(uint _TransactionNumber, string _memo);
    event Vote(string _memo,uint _key);
    //mappings of structs
    mapping(string => VoteOnTransaction) vote;
    mapping(uint => MultiSigTransaction) MSTrans;
    //cast vote for transaction
    struct VoteOnTransaction{
        uint Key;
        bool status;
        bool exist;
        address voter;
    }
    //transaction request
    struct MultiSigTransaction{
        uint amount;
        address toAddress;
        string topic;
        string messege;
        bool status;      //true once the proposal is closed, whether it passed or failed
        bool executed;    //true only if the proposal passed and was carried out
        uint pass;
        uint fail;
        bool exist;
        address XRC;
        uint tokenNumb;
        string call;      //"", "XRC20", "NFT" or "CALL"
        bytes data;       //calldata for a "CALL" proposal
    }
    //Launch Contract and Keys
    constructor(uint _totalKeys, uint _VotesNeededToPass,string memory URI) payable ERC1155(URI){
        require(_totalKeys > 0, "you must create at least one key");
        require(_VotesNeededToPass > 0, "you must need at least one vote");
        require(_VotesNeededToPass <= _totalKeys, "you cant have more votes needed than keys created");
        totalKeys =_totalKeys;
        VotesNeededToPass = _VotesNeededToPass;
        for(uint countKeys=0; countKeys < _totalKeys; countKeys++){
            _mint(msg.sender, countKeys, 1, "");
        }
    }
    //modifier checks to see if user has a key before executing the function
    modifier CheckKeys{
        require(holdsAnyKey(msg.sender), "You must hold a Key to access this function");
        _;
    }
    //internal function checks to see if user has key
    function holdsAnyKey(address _user) internal view returns(bool){
        for(uint i=0; i < totalKeys; i++){
            if(balanceOf(_user,i) > 0){
                return true;
            }
        }
        return false;
    }
    //check vote submission total
    function checkTotal(uint _TransactionNumber) internal returns(bool){
        countVotes(_TransactionNumber);
        if(MSTrans[_TransactionNumber].pass >= VotesNeededToPass){
            executeTransaction(_TransactionNumber);
            return true;
        } else if(MSTrans[_TransactionNumber].fail > totalKeys - VotesNeededToPass) {
            //enough keys voted no that the proposal can no longer pass
            MSTrans[_TransactionNumber].status = true;
            emit Execute(_TransactionNumber,"Vote Failed!");
            return true;
        }else {
            return false;
        }
    }
    //Counts only votes whose voter still holds the key, so moving a key ends its vote
    function countVotes(uint _TransactionNumber) internal {
        uint pass = 0;
        uint fail = 0;
        for(uint i = 0; i < totalKeys; i++){
            VoteOnTransaction memory cast = vote[voteKey(_TransactionNumber,i)];
            if(cast.exist && balanceOf(cast.voter,i) > 0){
                if(cast.status){
                    pass++;
                }else{
                    fail++;
                }
            }
        }
        MSTrans[_TransactionNumber].pass = pass;
        MSTrans[_TransactionNumber].fail = fail;
    }
    //check is transaction has been closed
    function checkTransactionStatus(uint _transNumb) public view CheckKeys returns(bool){
        return MSTrans[_transNumb].status;
    }
    //check whether a proposal passed and was carried out
    function checkTransactionExecuted(uint _transNumb) public view CheckKeys returns(bool){
        return MSTrans[_transNumb].executed;
    }
    //checks the voting status of a particular vote on a transactions
    function checkVote(uint _keyNumb,uint _transNumb) public view CheckKeys returns(uint,bool,bool){
        string memory checkStatus = voteKey(_transNumb,_keyNumb);
        return (vote[checkStatus].Key,vote[checkStatus].status,vote[checkStatus].exist);
    }
    //view previous & pending transactions
    function ViewTransactions() public view CheckKeys returns(MultiSigTransaction[] memory){
        MultiSigTransaction[] memory All_Transactions = new MultiSigTransaction[](TotalTransactions);
        for(uint i = 0; i < TotalTransactions; i++){
            All_Transactions[i] = MSTrans[i];
        }
        return (All_Transactions);
    }

    /// @notice Propose a payment or a plain vote. The shape of the input picks the kind:
    /// one address is XDC, or a plain vote if the address is zero; two addresses and one
    /// amount is XRC-20; two addresses and two amounts is an NFT with [amount, tokenId].
    /// @param _topic ["topic", "message"]. A third entry is accepted and ignored.
    function submitProposal(uint [] memory _amount, address [] memory _address,string [] memory _topic) public CheckKeys returns(bool){
        require(_amount.length >= 1, "amount is required");
        require(_topic.length >= 2, "topic and message are required");
        if(_address.length == 1 ){
            require(address(this).balance >= _amount[0], "Not enough funds in contract");
            addProposal(_amount[0],_address[0],_topic[0],_topic[1],address(0),0,"","");
            emit Proposal(TotalTransactions-1,"Transaction Proposal Made");
            return true;
        } else if(_address.length == 2 && _amount.length == 1){
            require(_address[0] != address(0), "recipient is required");
            require(IERC20(_address[1]).balanceOf(address(this)) >= _amount[0], "Not enough XRC funds in contract");
            addProposal(_amount[0],_address[0],_topic[0],_topic[1],_address[1],0,KIND_XRC20,"");
            emit Proposal(TotalTransactions-1,"XRC Transaction Proposal Made");
            return true;
        }else if(_address.length == 2 && _amount.length == 2){
            require(_address[0] != address(0), "recipient is required");
            addProposal(_amount[0],_address[0],_topic[0],_topic[1],_address[1],_amount[1],KIND_NFT,"");
            emit Proposal(TotalTransactions-1,"XRC NFT Transaction Proposal Made");
            return true;
        }
        return false;
    }
    /// @notice Propose calling a function on another contract, optionally sending XDC.
    /// Encode the function and arguments off-chain into _data. Only one call per proposal.
    function submitCallProposal(address _target, uint _value, bytes memory _data, string memory _topic, string memory _message) public CheckKeys returns(bool){
        require(_target != address(0), "target is required");
        require(address(this).balance >= _value, "Not enough funds in contract");
        addProposal(_value,_target,_topic,_message,address(0),0,KIND_CALL,_data);
        emit Proposal(TotalTransactions-1,"Function Call Proposal Made");
        return true;
    }
    function addProposal(uint _amount, address _to, string memory _topic, string memory _message, address _token, uint _tokenNumb, string memory _kind, bytes memory _data) internal{
        MSTrans[TotalTransactions] = MultiSigTransaction(_amount,_to,_topic,_message,false,false,0,0,true,_token,_tokenNumb,_kind,_data);
        proposalExpiry[TotalTransactions] = block.timestamp + PROPOSAL_LIFETIME;
        TotalTransactions++;
    }
    //key holders can cast votes as a key for a transaction
    function confirmTransaction(uint _TransactionNumber, bool _vote,uint _keyNumb) public CheckKeys nonReentrant returns(uint,uint,string memory){
        string memory castVote = voteKey(_TransactionNumber,_keyNumb);
        require(MSTrans[_TransactionNumber].exist == true, "Proposal does not exist");
        require(MSTrans[_TransactionNumber].status == false, "Contract Transaction Completed...no futher confrimation votes can be cast");
        require(block.timestamp <= proposalExpiry[_TransactionNumber], "Proposal has expired");
        require(vote[castVote].exist == false || balanceOf(vote[castVote].voter,_keyNumb) == 0, "vote has been cast already");
        require(balanceOf(msg.sender,_keyNumb) > 0, "you must be the holder of the key");

        vote[castVote] = VoteOnTransaction(_keyNumb,_vote,true,msg.sender);
        checkTotal(_TransactionNumber);
        emit Vote("Vote Casted",_keyNumb);

        return (MSTrans[_TransactionNumber].pass,MSTrans[_TransactionNumber].fail,castVote);
    }
    //Executes a proposal after parties have voted on it. A failed payment reverts the
    //whole vote, so the proposal stays open and the key can vote again later.
    function executeTransaction(uint _TransactionNumber) internal{
        MultiSigTransaction storage transaction = MSTrans[_TransactionNumber];
        transaction.status = true;
        transaction.executed = true;
        bytes32 kind = keccak256(bytes(transaction.call));

        if(kind == keccak256(bytes(KIND_XRC20))){
            IERC20(transaction.XRC).safeTransfer(transaction.toAddress, transaction.amount);
        } else if(kind == keccak256(bytes(KIND_NFT))){
            sendNFT(transaction.XRC,transaction.toAddress,transaction.tokenNumb,transaction.amount);
        } else if(kind == keccak256(bytes(KIND_CALL))){
            (bool success, ) = transaction.toAddress.call{value: transaction.amount}(transaction.data);
            require(success, "Function call failed");
        } else if(transaction.toAddress == address(0)){
            emit BlankExecute(_TransactionNumber,"Vote Passed!");
        } else {
            (bool success, ) = payable(transaction.toAddress).call{value: transaction.amount}("");
            require(success, "XDC payment failed");
        }
        emit Execute(_TransactionNumber,"Transaction successful!");
    }
    //check to see if contract is XRC1155 or XRC721 and send token to the recipient
    function sendNFT(address _contractAddress, address _to, uint _tokenNumb,uint _amount) internal{
        if(supportsToken(_contractAddress,INTERFACE_ERC721)){
            IERC721(_contractAddress).safeTransferFrom(address(this), _to, _tokenNumb);
        }else if(supportsToken(_contractAddress,INTERFACE_ERC1155)){
            IERC1155(_contractAddress).safeTransferFrom(address(this), _to, _tokenNumb,_amount,"");
        }else{
            revert("Token is not XRC721 or XRC1155");
        }
    }
    function supportsToken(address _contractAddress, bytes4 _interface) internal view returns(bool){
        try IERC165(_contractAddress).supportsInterface(_interface) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }
    function voteKey(uint _TransactionNumber, uint _keyNumb) internal pure returns(string memory){
        return string(abi.encodePacked(Strings.toString(_TransactionNumber),"-",Strings.toString(_keyNumb)));
    }
    //remove vote if transaction hasent been confirmed yet
    function revokeConfirmation(uint _TransactionNumber, uint _keyNumb) public CheckKeys returns(string memory){
        string memory castVote = voteKey(_TransactionNumber,_keyNumb);
        require(MSTrans[_TransactionNumber].status ==false && MSTrans[_TransactionNumber].exist == true ,"Transaction already confirmed");
        require(vote[castVote].exist == true, "you havent casted a vote");
        require(balanceOf(msg.sender,_keyNumb) > 0, "you must be the holder of the key");
        //remove vote
        bool wasPass = vote[castVote].status;
        delete vote[castVote];
        countVotes(_TransactionNumber);
        return wasPass ? "Vote Removed Pass: -1" : "Vote Removed Fail: -1";
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
