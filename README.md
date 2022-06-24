# ***submitProposal()*** *Parameters*
- uint: Amount 
- Array: [0: toAddress, 1: XRC_Type, 2: NFT_id] **(token based parameters)**
- String: Topic 
- String: Message

# #Token Based Parameters
Note: 0x0000000000000000000000000000000000000000 is used as a 0 place hoder

**Governance Vote:**
- 0: (address) 0x0000000000000000000000000000000000000000 (Required!)
- 1: (address) 0x0000000000000000000000000000000000000000 (Required!)
- 2: N/A

**XDC Transactions:**
- 0:(address) toAddress 
- 1: N/A
- 2: N/A

**XRC20  Transactions:**
- 0: (address) toAddress 
- 1: (address) XRC contract address 
- 2:N/A

**XRC721&1155 Transactions:**
 - 0: (address) toAddress 
- 1: (address) XRC contract address
- 2: (uint) Token number 


![multiSigTreasury (1)](https://user-images.githubusercontent.com/16103963/175453972-a67d397f-2dcf-4099-8d43-dafad21ab17b.png)
