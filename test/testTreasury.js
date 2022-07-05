const MultiSigTreasury = artifacts.require("MultiSigTreasury");

//Unit Testing on Multi Sig Contract
contract(MultiSigTreasury, () => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(3,2,"test 1");
        partyA = accounts[0];
        partyB = accounts[1];
        partyC = accounts[1];
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        assert(await treasury.address !== '', "Multi Sig Launched ");
    })
    it("submitProposal()", async() =>  {
        uint = [];
        address = [];
        string = [];
        assert(await treasury.submitProposal(uint,address,string) == true, "Proposal submitted ");
    })

    //it("confirmTransaction()", async() =>  { })
    //it("checkVote()", async() =>  { })
    //it("revokeConfirmation()", async() =>  { })
    //it("checkVote()", async() =>  { })
    //it("Complete Vote", async() =>  { })
})