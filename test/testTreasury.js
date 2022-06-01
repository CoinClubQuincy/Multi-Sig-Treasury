const MultiSigTreasury = artifacts.require("MultiSigTreasury");

contract(MultiSigTreasury, () => {
    before( async() => {
        var treasury = await MultiSigTreasury.deployed(5,3,"test 1");
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        console.log("check address");
        assert(await treasury.address !== '', "Coinbank Address Expected");
    })
})