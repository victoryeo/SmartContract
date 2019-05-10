var STOToken = artifacts.require("STOToken");

module.exports = function(deployer) {
    deployer.deploy(STOToken);
    // Additional contracts can be deployed here
};
    
