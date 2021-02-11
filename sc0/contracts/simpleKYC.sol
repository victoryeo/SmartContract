pragma solidity >=0.4.21 <=0.8.0;

contract simpleKYC {
  uint public storedKYC;
  bool public eKYC;

  constructor(bool initKYC) public {
    eKYC = initKYC;
  }

  function startUserKYC() public {
    eKYC = true;
  }

  function createUserInfo(uint x) public {
    storedKYC = x;
  }

  function getUserKYCApproval() view public returns (uint retVal) {
    return storedKYC;
  }
}

