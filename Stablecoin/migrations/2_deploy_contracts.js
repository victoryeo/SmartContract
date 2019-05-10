var Stablecoin = artifacts.require("Stablecoin");

module.exports = function(deployer) {
    deployer.deploy(Stablecoin);
    // Additional contracts can be deployed here
};
