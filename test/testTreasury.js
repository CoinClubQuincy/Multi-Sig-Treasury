const MultiSigTreasury = artifacts.require("MultiSigTreasury");

//Unit Testing on Multi Sig Contract
// Blank Vote
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        const partyA = accounts[0];
        const partyB = accounts[1];

        web3.eth.sendTransaction({to:treasury.address, from:accounts[0], value:web3.utils.toWei("1", "ether")})
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    it("submitProposal()", async() =>  {
        var uint = [0];
        var address = ["0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000"];
        var string = ["Test blank Transaction","MSG",""];

        const result = treasury.submitProposal(uint,address,string);
        assert(result === true, "Proposal submitted");
    })
    //it("confirmTransaction()", async() =>  { })
    //it("revokeConfirmation()", async() =>  { })
    //it("Complete Vote", async() =>  { })
})

//XDC Tranaction Testing on Multi Sig Contract
contract(MultiSigTreasury, (accounts) => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        const partyA = accounts[0];
        const partyB = accounts[1];

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
        const partyA = accounts[0];
        const partyB = accounts[1];

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
        const partyA = accounts[0];
        const partyB = accounts[1];

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
        const partyA = accounts[0];
        const partyB = accounts[1];

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