var ABCToken = artifacts.require("ABC");

module.exports = function(deployer) {
    deployer.deploy(ABCToken);
    // Additional contracts can be deployed here
};
    
