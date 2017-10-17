var ViToken = artifacts.require("./Vitoken.sol");

module.exports = function(deployer) {
  deployer.deploy(ViToken);
};
