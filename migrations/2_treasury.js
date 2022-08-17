const MultiSigTreasury = artifacts.require("MultiSigTreasury");

module.exports = function (deployer) {
  deployer.deploy(MultiSigTreasury, 5,3,"test");
};

