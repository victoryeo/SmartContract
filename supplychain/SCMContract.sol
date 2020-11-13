pragma solidity ^0.4.23;

contract MasterContract {
    struct User {
      string[] field;
    }
    string[] public textfield;

    struct Custom_Field {
      string field_name;
    }
    struct PO_Step {
      string step_name;
      mapping (uint => Custom_Field) custom_fields;
    }
    mapping (uint => PO_Step) public po_steps;

    address[] public deployedFactory;

    //authorized user to access this contract
    address public administrator;
    //keeps track of number of users to whom this contract can be assigned
    uint public numUsers;

    struct CustomerContract {
      string description; //contract description
      uint expiry; //expiry date of this contract (UNIX timestamp)
      address deployed; //address of where this contract was deployed
      uint status; //status of this contract (0=inactive, 1=active)
    }

    struct Customer {
      uint id; //customer's id (used by AE to manage customer accounts)
      string name; //customer's display name
      uint numContracts; //keeps track of number of factory contracts created
      //collection of factory contracts created for this customer
      mapping (uint => CustomerContract) contracts;
    }
    mapping (uint => Customer) public customers; //list of customers

    function createFactory(uint num, string name) public {
      address newFactory = new Factory(name, msg.sender);
      deployedFactory.push(newFactory);

      customers[num].id = num;
      customers[num].name = name;
    }

    function getDeployedFactory() public view returns (address[]) {
      return deployedFactory;
    }

    function setCustomerContract(uint num, string desc) public {
      uint contractNumber = customers[num].numContracts;
      customers[num].contracts[contractNumber].description = desc;
      customers[num].contracts[contractNumber].status = 0;
      customers[num].numContracts++;
    }

    function getCustomerContract(uint num, uint contractNumber)
        public constant returns (string) {
      return customers[num].contracts[contractNumber].description;
    }

    function setCustomField(uint step, string dyn) public {
      po_steps[step].step_name = "custom";
      po_steps[step].custom_fields[0].field_name = dyn;
    }

    function getCustomField(uint step, uint idx) public constant returns (string) {
      return po_steps[step].custom_fields[idx].field_name;
    }

    function setDynamicField(string dyn) public {
      textfield.push(dyn);
      User memory user = User(textfield);
    }
}

contract Factory {
    address[] public deployedChildren;
    address public manager;
    string public companyName;

    string public customerId;    //customer's id (used by AE to manage customer accounts)
    string public customerName;  //customer's display name
    address public owner;        //authorized user to access this contract
    string public contractTitle; //title of this contract (e.g. "SCM PO Process")
    uint public numUsers;        //keeps track of number of users to whom this contract can be assigned
    mapping (uint => UserLookup) public users; //list of users to whom this contract can be assigned
    uint public numChildContracts;   //keeps track of number of child contracts created by customer
    address[] public childContracts; //collection of child contracts created by customer
    uint public status;          //status of this contract (0=inactive, 1=active)

    struct UserLookup {
      uint id; //user's id (used by user lookup service in AE)
      string name; //user's display name
      address wallet; //user's address
    }
    UserLookup m_userLookup;

    modifier restricted() {
      require(msg.sender == manager);
      _;
    }

    constructor(string name, address creator) public {
      manager = creator;
      companyName = name;
      m_userLookup.name = name;
      m_userLookup.wallet = creator;
    }

    function findUserAddress(address userAddress) public view returns (address) {
      return m_userLookup.wallet;
    }

    function createChild(uint PO) public restricted {
      address newChild = new Child(PO, msg.sender);
      deployedChildren.push(newChild);
    }

    function getDeployedChildren() public view returns (address[]) {
      return deployedChildren;
    }
}

contract Child {
    uint public PONumber;
    address public company;
    string POIpfsHash;

    string public documentId; //id of this contract
    uint public numSteps; //keeps track of number of steps configured by customer in this contract
    string[] public attachmentHashes; //collection of ipfs hashes which were linked to this contract
    uint public status; //status of this contract (0=inactive, 1=active)

    modifier restricted() {
      require(msg.sender == company);
      _;
    }

    constructor(uint PO, address creator) public {
      company = creator;
      PONumber = PO;
    }

    function getIpfsHash() public constant returns (string) {
      return POIpfsHash;
    }

    function setIpfsHash(string ipfsHashArg) public {
      POIpfsHash = ipfsHashArg;
    }
}
