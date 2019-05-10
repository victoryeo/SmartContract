pragma solidity >= 0.4.22 < 0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      // uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

contract Token {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
      return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[msg.sender]);
      require(_to != address(0));
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[_from], "Not enough balance");
      //require(_value <= allowed[_from][msg.sender]);
      //require(_to != address(0));
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      //allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
    }

    function allowance(address _owner,address _spender) public view returns (uint256) {
      return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public returns (bool) {
      allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public returns (bool) {
      uint256 oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue >= oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }

      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }
}

contract STOToken is Token {
    string public name = 'VictorSTOToken';
    string public symbol = 'Victor';
    uint256 public decimals = 18;
    address public crowdsaleAddress;
    address payable public owner;
    uint256 public STOEndTime;
    uint256 public totalSupplyLimit_;
    mapping (address => bool) public shareholderWhitelist;
    mapping (address => bool) public investorWhitelist;
    event BuyToken(address, address, uint256);
    event Minted(address, uint256);

    modifier onlyCrowdsale {
      require(msg.sender == crowdsaleAddress);
      _;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier afterCrowdsale {
      require(now > STOEndTime || msg.sender == crowdsaleAddress);
      _;
    }

    constructor (//uint256 _STOEndTime
        )  public Token() {
      //require(_STOEndTime > 0);
      totalSupplyLimit_ = 100e24;
      owner = msg.sender;
      //a dummy date, Thursday, 8 December 2050 06:46:50
      //just for testing
      STOEndTime = 2554094810;  //STOEndTime = _STOEndTime;
      // add owner to whitelist
      shareholderWhitelist[owner] = true;
      investorWhitelist[owner] = true;
    }

    function addToShareholderWhiteList(address _shareholder) public {
        shareholderWhitelist[_shareholder] = true;
    }

    function addToInvestorWhiteList(address _investor) public {
        investorWhitelist[_investor] = true;
    }

    function checkInvestorWhitelist(address _investor) public view returns(bool) {
        require(investorWhitelist[_investor]);
        return true;
    }

    function mint(address _to, uint256 _value) public
        returns (bool)
    {
      require(shareholderWhitelist[_to]);
      if (totalSupplyLimit_ >= totalSupply_ + _value) {
        balances[_to] = balances[_to].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Minted(_to, _value);
        return true;
      }
      return false;
    }

    /* If the transfer request comes from the STO, it only checks that the
    investor is in the whitelist
    * If the transfer request comes from a token holder, it checks that:
    * a) Both are on the whitelist
    * b) Seller's sale lockup period is over
    * c) Buyer's purchase lockup is over
    */
    function verifyTransfer(address _from, address _to, uint256 _value)
        public view returns (bool) {
      //require(now > STOEndTime || msg.sender == crowdsaleAddress);
      require(investorWhitelist[_from]);
      require(investorWhitelist[_to]);
      require(_value >= 0);
      return true;
    }

    function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
      require(_crowdsaleAddress != address(0));
      crowdsaleAddress = _crowdsaleAddress;
    }

    function buyTokens(address _receiver, uint256 _amount) public {
      //require(_receiver != address(0));
      //require(_amount > 0);
      emit BuyToken(owner, _receiver, _amount);
      transferFrom(owner, _receiver, _amount);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function transfer(address _to, uint256 _value) public returns(bool) {
      //require(verifyTransfer( owner, _to, _value ));
      return super.transfer(_to, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function transferFrom(address _from, address _to, uint256 _value) public
        returns(bool) {
      //require(verifyTransfer(_from, _to, _value));
      return super.transferFrom(_from, _to, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function approve(address _spender, uint256 _value) public returns(bool) {
      return super.approve(_spender, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function increaseApproval(address _spender, uint _addedValue) public afterCrowdsale
        returns(bool success) {
      return super.increaseApproval(_spender, _addedValue);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function decreaseApproval(address _spender, uint _subtractedValue) public afterCrowdsale returns(bool success) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function emergencyExtract() external onlyOwner {
      owner.transfer(address(this).balance);
    }

    function returnSTOEndTime() external view returns (uint256) {
      return STOEndTime;
    }
}

contract CrowdSale {
    bool stoCompleted;
    uint256 public stoStartTime;
    uint256 public stoEndTime;
    uint256 public tokenRate;
    address public tokenAddress;
    uint256 public fundingGoal;
    address payable public owner;
    STOToken public token;
    uint256 public tokensRaised;
    uint256 public etherRaised;
    //mapping (address => bool) public investorWhitelist;

    modifier whenStoCompleted {
      require(stoCompleted);
      _;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier onlyWhitelist {
      require(token.checkInvestorWhitelist(msg.sender));
      _;
    }

    modifier lockupPeriod {
      require(now < stoEndTime && now > stoStartTime);
      _;
    }

    constructor(
        /**uint256 _stoStart,
        uint256 _stoEnd,
        uint256 _tokenRate,
        uint256 _fundingGoal,*/
        address _tokenAddress)  public {
      require(_tokenAddress != address(0));
      /** require(
        _stoStart != 0 &&
        _stoEnd != 0 &&
        _stoStart < _stoEnd &&
        _tokenRate != 0 &&
        _tokenAddress != address(0) &&
        _fundingGoal != 0); */
      stoStartTime = 0;
      tokenRate = 1000000000;
      fundingGoal = 100000;

      tokenAddress = _tokenAddress;
      owner = msg.sender;
      token = STOToken(_tokenAddress);
      stoEndTime = token.returnSTOEndTime();
    }

    function addToWhiteList(address _investor) public {
      //investorWhitelist[_investor] = true;
      token.addToInvestorWhiteList(_investor);
    }

    function () external payable {
      buy();
    }

    function buy() public payable {

      //require(tokensRaised < fundingGoal);
      uint256 tokensToBuy;
      uint256 etherUsed = msg.value;
      tokensToBuy = msg.value * (10 ** token.decimals()) / 1 ether * tokenRate;
      // Check if we have reached and exceeded the funding goal
      // to refund the exceeding tokens and ether
      //to be added?

      // Send the tokens to the buyer
      token.buyTokens(msg.sender, tokensToBuy);

      // Increase the tokens raised and ether raised state variables
      tokensRaised += tokensToBuy;
      etherRaised += etherUsed;
    }

    function buyWithAddress(address _investor) public payable {

      //require(tokensRaised < fundingGoal);
      uint256 tokensToBuy;
      uint256 etherUsed = msg.value;
      tokensToBuy = msg.value * (10 ** token.decimals()) / 1 ether * tokenRate;
      // Check if we have reached and exceeded the funding goal
      // to refund the exceeding tokens and ether
      //to be added?

      // Send the tokens to the buyer
      token.buyTokens(_investor, tokensToBuy);

      // Increase the tokens raised and ether raised state variables
      tokensRaised += tokensToBuy;
      etherRaised += etherUsed;
    }

    function extractEther() public whenStoCompleted onlyOwner {
      owner.transfer(address(this).balance);
    }
}
