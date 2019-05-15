pragma solidity >= 0.4.22 < 0.6.0;

import {DateTimeLib} from "./DateTimeLib.sol";

contract ABC {
  address public owner;

  struct shopperInfo {
    uint age;
    uint gender;   //0 neutral, 1 male, 2 female
    uint status;   //0 normal, 1 elite
    uint balance;
    uint monthlySpending;
    uint ABCtoken;
  }
  mapping (address => shopperInfo) public shopper;
  event buyUSDTokenEvent(address, uint);
  event spendingEvent(address, uint);

  struct goodsInfo {
    uint price;        //use 2 decimal place
    uint ageLimit;
    uint genderLimit;  //0: no limit, 1: male only, 2: female only
    uint returnDays;   //0: cannot return, 1 to n: number of days
  }
  mapping (bytes32 => goodsInfo) private goods;
  uint yearRecord;
  uint monthRecord;

  modifier onlyOwner() {
    require(msg.sender == owner, "must be owner");
    _;
  }

  constructor() public {
    bytes32 placeholder;
    owner = msg.sender;

    goods["beer"].price = 300;
    goods["beer"].ageLimit = 21;
    goods["skirt"].price = 500;
    goods["skirt"].genderLimit = 2;

    //this does not work, needs to convert string to bytes
    //addGoods("apple", 150, 0, 0, 0);
    placeholder = stringToBytes32("apple");
    addGoods(placeholder, 150, 0, 0, 0);
    //goods["apple"].price = 150;

    (yearRecord, monthRecord) = DateTimeLib.getMonthYear(now);
  }

  function stringToBytes32(string memory source) public returns (bytes32 result) {
    bytes memory temp = bytes(source);
    if (temp.length == 0) {
      return 0x0;
    }
    assembly {
      result := mload(add(source, 32))
    }
  }

  function register(uint _age, uint _gender) public  {
    shopper[msg.sender].age = _age;
    shopper[msg.sender].gender = _gender;
    shopper[msg.sender].status = 0;
    shopper[msg.sender].balance = 0;
  }

  function buyUSDToken(uint _amount) public {
    require(_amount > 0);
    emit buyUSDTokenEvent(msg.sender, _amount);
    shopper[msg.sender].balance += _amount;
  }

  function buyGoods(bytes32 _name, uint _quantity) public returns (uint) {
    uint spending;
    uint year;
    uint month;

    if (_name == "beer") {
      require(shopper[msg.sender].age > 21, "age limit");
    }
    else if (_name == "skirt") {
      require(shopper[msg.sender].gender == 2, "gender limit");
    }

    spending = _quantity * goods[_name].price / 100;
    //if elite shopper, get 10% discount
    if (shopper[msg.sender].status == 1) {
      spending = spending * 9 / 10;
    }

    emit spendingEvent(msg.sender, spending);
    require(shopper[msg.sender].balance > spending, "spending limit");
    shopper[msg.sender].balance -= spending;

    //calculate monthlySpending
    (year, month) = DateTimeLib.getMonthYear(now);
    if (year == yearRecord) {
      if (month == monthRecord) {
        shopper[msg.sender].monthlySpending += spending;
      }
      else {
        shopper[msg.sender].monthlySpending = 0;
        monthRecord = month;
      }
    }
    else {
      yearRecord = year;
    }

    //check monthlySpending status
    if (shopper[msg.sender].monthlySpending > 500)
      shopper[msg.sender].status = 1;  //elite

    return spending;
  }

  function addGoods(bytes32 _name, uint _price, uint _ageLimit,
        uint _genderLimit, uint _returnDays) public onlyOwner {
    goods[_name].price = _price;
    goods[_name].ageLimit = _ageLimit;
    goods[_name].genderLimit = _genderLimit;
    goods[_name].returnDays = _returnDays;
  }

  function monthEndReward(address _shopperAddr) public onlyOwner {
    shopper[_shopperAddr].ABCtoken += shopper[_shopperAddr].monthlySpending;
  }

  function getGoodsPrice(bytes32 _name) public view returns (uint) {
    return goods[_name].price;
  }

  function getShopperBalance(address _shopperAddr) public view returns (uint) {
    return shopper[_shopperAddr].balance;
  }

  function getShopperStatus(address _shopperAddr) public view returns (uint) {
    return shopper[_shopperAddr].status;
  }

  function getShopperABCToken(address _shopperAddr) public view returns (uint) {
    return shopper[_shopperAddr].ABCtoken;
  }

}
