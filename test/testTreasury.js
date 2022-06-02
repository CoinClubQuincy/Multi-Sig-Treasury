const MultiSigTreasury = artifacts.require("MultiSigTreasury");

contract(MultiSigTreasury, () => {
    let treasury = null;

    before( async() => {
        treasury = await MultiSigTreasury.deployed(5,3,"test 1");
    });
    it("Launch MultiSigTreasury contract", async() =>  {
        assert(await treasury.address !== '', "Coinbank Address Expected");
    })
})