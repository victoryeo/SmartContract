const ABC = artifacts.require('../contracts/ABC.sol')

contract('ABC', accounts => {
  let abc
  let account0 = accounts[0]
  let account1 = accounts[1]

  beforeEach('setup contract', async function(){
    abc = await ABC.new()
  })

  it("sets an owner", async () => {
    //console.log(account0)
    //balance = await web3.eth.getBalance(account0);
    //console.log(balance)
    assert.equal(await abc.owner.call(), account0)
  })

  it('is able to register', async function() {
    //console.log(account1)
    await abc.register(25, 1, {from: account1})
    balance = await abc.getShopperBalance(account1)
    //console.log(balance)
    assert.equal(balance, 0)
  })

  it('is able to buy usd token', async function() {
    await abc.buyUSDToken(100, {from: account1})
    balance = await abc.getShopperBalance(account1)
    console.log(balance)
    assert.equal(balance, 100)
  })

  it('is able to add goods', async function() {
    await abc.addGoods(web3.utils.asciiToHex("apple"), 150, 0, 0, 0, {from: account0})
    price = await abc.getGoodsPrice(web3.utils.asciiToHex("apple"))
    assert.equal(price, 150)
  })

  it('adult guy is able to buy beer', async function() {
    let q = 10
    await abc.register(25, 1, {from: account1})
    await abc.buyUSDToken(100, {from: account1})
    balanceBefore = await abc.getShopperBalance(account1)
    console.log(balanceBefore)
    await abc.buyGoods(web3.utils.asciiToHex("beer"), q, {from: account1})
    balanceAfter = await abc.getShopperBalance(account1)
    console.log(balanceAfter)
    price = await abc.getGoodsPrice(web3.utils.asciiToHex("beer"))
    spending = price * q / 100;
    console.log(spending)
    assert.equal(balanceBefore, +balanceAfter + +spending)
  })

  it('girl is able to buy skirts', async function() {
    let q = 1
    await abc.register(25, 2, {from: account1})
    await abc.buyUSDToken(100, {from: account1})
    balanceBefore = await abc.getShopperBalance(account1)
    console.log(balanceBefore)
    await abc.buyGoods(web3.utils.asciiToHex("skirt"), q, {from: account1})
    balanceAfter = await abc.getShopperBalance(account1)
    console.log(balanceAfter)
    price = await abc.getGoodsPrice(web3.utils.asciiToHex("skirt"))
    spending = price * q / 100;
    console.log(spending)
    assert.equal(balanceBefore, parseInt(balanceAfter) + parseInt(spending))
  })

  it('become elite status', async function() {
    let q = 500
    await abc.register(20, 1, {from: account1})
    await abc.buyUSDToken(1000, {from: account1})
    await abc.buyGoods(web3.utils.asciiToHex("apple"), q, {from: account1})
    status = await abc.getShopperStatus(account1)
    assert.equal(status, 1)
  })

  it('month end reward', async function() {
    let q = 100
    await abc.register(30, 2, {from: account1})
    await abc.buyUSDToken(1000, {from: account1})
    await abc.buyGoods(web3.utils.asciiToHex("beer"), q, {from: account1})
    price = await abc.getGoodsPrice(web3.utils.asciiToHex("beer"))
    spending = price * q / 100;
    await abc.monthEndReward(account1, {from: account0})
    tokenBalance = await abc.getShopperABCToken(account1)
    assert.equal(spending, 0)
  })

  it('is able to get key', async function() {
    item = await abc.getItem(web3.utils.asciiToHex("test"))
    assert.equal(item, 2)
  })
})
