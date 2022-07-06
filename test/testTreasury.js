const MultiSigTreasury = artifacts.require("MultiSigTreasury");
const XRC20 = artifacts.require("XRC20");
const XRC721 = artifacts.require("XRC721");
const XRC1155 = artifacts.require("XRC1155");
//Unit Testing on Multi Sig Contract
// Blank Vote
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1",{from: accounts[0]});
        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
        
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");

    })
    it("send Keys to required address", async() =>  {
        let sendToken = await treasury.safeTransferFrom( accounts[0],  accounts[1], 1, 1, "0x0")
        let tokenB = await treasury.balanceOf(accounts[1],1)

        assert.equal(tokenB.toNumber(), 1, "Both addresses have Keys");
    })    
    it("execute submitProposal()", async() =>  {
        var uint = [0];
        var address = ["0x0000000000000000000000000000000000000000"];
        var string = ["Test blank Transaction","MSG",""];

        const result = await treasury.submitProposal(uint,address,string);
        assert.equal(result.receipt.status, true, "Proposal submitted");
    })
    it("confirmTransaction()", async() =>  { 
        const result = await treasury.confirmTransaction(0, true,0, {from: accounts[0]})
        assert.equal(result.receipt.status, true, "Proposal submitted");
    })
    it("Finnish Vote()", async() =>  { 
        const result = await treasury.confirmTransaction(0, true,1, {from: accounts[1]})
        assert.equal(result.receipt.status, true, "Proposal submitted");
    })
})

//XDC Tranaction Testing on Multi Sig Contract
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    //it("submitProposal()", async() =>  {
    //    uint = [];
    //    address = [];
    //    string = [];
    //    assert(await treasury.submitProposal(uint,address,string) == true, "Proposal submitted ");
    //})
    //it("confirmTransaction()", async() =>  { })
    //it("revokeConfirmation()", async() =>  { })
    //it("Complete Vote", async() =>  { })
})

//XRC20 Tranaction Testing on Multi Sig Contract
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
    });
    it("Send XRC20 Token", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    //it("submitProposal()", async() =>  {
    //    uint = [];
    //    address = [];
    //    string = [];
    //    assert(await treasury.submitProposal(uint,address,string) == true, "Proposal submitted ");
    //})
    //it("confirmTransaction()", async() =>  { })

    //it("Complete Vote", async() =>  { })
})
//XRC721 Tranaction Testing on Multi Sig Contract
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
    });
    it("Send 721 Token", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    //it("submitProposal()", async() =>  {
    //    uint = [];
    //    address = [];
    //    string = [];
    //    assert(await treasury.submitProposal(uint,address,string) == true, "Proposal submitted ");
    //})
    //it("confirmTransaction()", async() =>  { })

    //it("Complete Vote", async() =>  { })
})
//XRC1155 Tranaction Testing on Multi Sig Contract
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
    });
    it("Send XRC1155 Token", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    //it("submitProposal()", async() =>  {
    //    uint = [];
    //    address = [];
    //    string = [];
    //    assert(await treasury.submitProposal(uint,address,string) == true, "Proposal submitted ");
    //})
    //it("confirmTransaction()", async() =>  { })

    //it("Complete Vote", async() =>  { })
})