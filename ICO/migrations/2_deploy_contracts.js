var ICOToken = artifacts.require("ICOToken");

module.exports = function(deployer) {
    deployer.deploy(ICOToken);
    // Additional contracts can be deployed here
};
