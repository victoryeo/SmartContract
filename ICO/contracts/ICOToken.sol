
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

contract ERC20 {
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

contract ICOToken is ERC20 {
    string public name = 'VictorICOToken';
    string public symbol = 'Victor';
    uint256 public decimals = 18;
    address public crowdsaleAddress;
    address payable public owner;
    uint256 public ICOEndTime;
    uint256 public totalSupplyLimit_;
    event BuyToken(address, address, uint256);

    modifier onlyCrowdsale {
      require(msg.sender == crowdsaleAddress);
      _;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier afterCrowdsale {
      require(now > ICOEndTime || msg.sender == crowdsaleAddress);
      _;
    }

    constructor (
          //uint256 _ICOOEndTime
        )  public ERC20() {
      //require(_ICOEndTime > 0);
      totalSupplyLimit_ = 100e24;
      owner = msg.sender;
      //a dummy date, Thursday, 8 December 2050 06:46:50
      //just for testing
      ICOEndTime = 2554094810;  
      totalSupply_ = 100e24;
    }

    function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
      require(_crowdsaleAddress != address(0));
      crowdsaleAddress = _crowdsaleAddress;
    }

    function buyTokens(address _receiver, uint256 _amount) public {
      require(_receiver != address(0));
      require(_amount > 0);
      emit BuyToken(owner, _receiver, _amount);
      transferFrom(owner, _receiver, _amount);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function transfer(address _to, uint256 _value) public returns(bool) {
      return super.transfer(_to, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end
    function transferFrom(address _from, address _to, uint256 _value) public
        returns(bool) {
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
    function decreaseApproval(address _spender, uint _subtractedValue) public afterCrowdsale
        returns(bool success) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function emergencyExtract() external onlyOwner {
      owner.transfer(address(this).balance);
    }

    function returnICOEndTime() external view returns (uint256) {
      return ICOEndTime;
    }
}

contract CrowdSale {
    bool icoCompleted;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    uint256 public bonusEndTime;
    uint256 public bitcoinRate;
    uint256 public etherRate;
    address public tokenAddress;
    uint256 public fundingGoal;
    address payable public owner;
    ICOToken public token;
    uint256 public tokensRaised;
    uint256 public etherRaised;

    modifier whenIcoCompleted {
      require(icoCompleted);
      _;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    modifier lockupPeriod {
      require(now < icoEndTime && now > icoStartTime);
      _;
    }

    constructor(
        /**uint256 _icoStart,
        uint256 _icoEnd,
        uint256 _tokenRate,
        uint256 _fundingGoal,*/
        address _tokenAddress)  public {
      require(_tokenAddress != address(0));
      /** require(
        _icoStart != 0 &&
        _icoEnd != 0 &&
        _icoStart < _icoEnd &&
        _tokenRate != 0 &&
        _tokenAddress != address(0) &&
        _fundingGoal != 0); */
      icoStartTime = 0;
      etherRate = 1000000000;
      bitcoinRate = 5000000000;
      fundingGoal = 100000;

      tokenAddress = _tokenAddress;
      owner = msg.sender;
      token = ICOToken(_tokenAddress);
      icoEndTime = token.returnICOEndTime();
    }

    function getRate() external view returns (uint256, uint256) {
      return(etherRate, bitcoinRate);
    }

    function () external payable {
      buy();
    }

    function buy() public payable {

      //require(tokensRaised < fundingGoal);
      uint256 tokensToBuy;
      uint256 etherUsed = msg.value;
      tokensToBuy = msg.value * (10 ** token.decimals()) / 1 ether * etherRate;
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
      tokensToBuy = msg.value * (10 ** token.decimals()) / 1 ether * etherRate;
      // Check if we have reached and exceeded the funding goal
      // to refund the exceeding tokens and ether
      //to be added?

      // Send the tokens to the buyer
      token.buyTokens(_investor, tokensToBuy);

      // Increase the tokens raised and ether raised state variables
      tokensRaised += tokensToBuy;
      etherRaised += etherUsed;
    }

    function extractEther() public whenIcoCompleted onlyOwner {
      owner.transfer(address(this).balance);
    }
}
