# ***submitProposal()*** *Parameters*

    function submitProposal(uint  _ammount, address [] memory  _address,string  memory  _topic,string  memory  _messege) public CheckKeys returns(bool)

- uint: [Amount,tokenID] 
- address: [0: toAddress, 1: XRC_Type, 2: NFT_id] **(token based parameters)**
- String: [Topic,Message, FunctionExecution() ] 

# #int [] Based Parameters
**governance Vote**
- [NA]

**XDC & XRC20 transactions**
- [amount,N/A]

**XRC721&1155 Transactions:**
- [1,tokenNumber]

# #address [] Based Parameters
Note: 0x0000000000000000000000000000000000000000 is used as a 0 place hoder

**Governance Vote:**
A blank vote where token holders can vote on a topic (no execution is made other than showing the result of a majority vote)
- 0: (address) 0x0000000000000000000000000000000000000000 (Required!)
- 1: (address) 0x0000000000000000000000000000000000000000 (Required!)

**XDC Transactions:**
A simple transaction sending XDC to another address upon a completed vote
- 0:(address) toAddress 
- 1: N/A

**XRC20  Transactions:**
A simple transaction sending XRC20 tokens to another address upon a completed vote
- 0: (address) toAddress 
- 1: (address) XRC contract address 

**XRC721&1155 Transactions:**
A simple transaction sending a XRC721 or XRC1155  tokens to another address upon a completed vote
 - 0: (address) toAddress 
- 1: (address) XRC contract address
 
# #String [] Based Parameters
**Topic & Message** 
Topic and message of transaction or vote describing the 
- ["Topic name" , "message",""] : XDC transaction without function excution or blank transaction
- ["Topic name" , "message","XRC20"] : XRC20 transaction or blank transaction
- ["Topic name" , "message","XRC20"] : NFT transaction or blank transaction


 **FunctionExecution()** [Not completed]
 
Function Execution can only be made with an XDC transaction and execute another contracts external functions **(only one execution at a time!)** 
so a multi executing function would require to be done in a separately created contract where the Treasury would execute to automate multiple executions
-  ["Topic name" , "message", FunctionExecution()]

![multiSigTreasury (1)](https://user-images.githubusercontent.com/16103963/175453972-a67d397f-2dcf-4099-8d43-dafad21ab17b.png)

