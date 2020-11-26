const Web3 = require('web3')
const contract = require('truffle-contract')
const path = require('path')

let contractABI = require(path.join(__dirname, '../build/contracts/MetaCoin.json'))
let provider = new Web3.providers.HttpProvider("http://localhost:7545")
let masterContract = contract(contractABI)
masterContract.setProvider(provider)

const web3 = new Web3()
web3.setProvider(provider)

objectAcc = web3.eth.accounts.create(web3.utils.randomHex(32))
console.log(objectAcc)
AddedAcc = web3.eth.accounts.wallet.add(objectAcc)
console.log(AddedAcc)
objectKey = web3.eth.accounts.wallet.encrypt("password")
console.log(objectKey)

let accounts

getAccount = async() => {
  accounts = await web3.eth.getAccounts();
  console.log(accounts)
}

transferEth = async() => {
  await web3.eth.sendTransaction({
    from: accounts[1],
    to: objectAcc.address,
    value:  web3.utils.toWei("1", "ether"),
    gas: 4600000
  }).then(function(err, txHash) {
          if (!err)
                console.log("txHash " + txHash)
          else
                console.log(err)
  })
}

getEthBalance = async() => {
  let bal0 = await web3.eth.getBalance(objectAcc.address)
  let bal1 = await web3.eth.getBalance(accounts[1])
  console.log(bal0)
  console.log(bal1)
}

getCoinBalance = async(instance) => {
  let user = 0
  let bal0 = await instance.getBalance(accounts[user])
  console.log("account %d %s", user, bal0)
}

getAccount()

fix_account = "0x8279F5648427919CEdb0fc413E9eFE34ff6D2baf"

masterContract.deployed().then(function(instance) {
  console.log("address " + instance.address)
  instance.sendCoin(accounts[1], 10, {from: accounts[0]})
  getCoinBalance(instance)

  transferEth()
  getEthBalance()
}).then(function(result) {
  console.log("result " + result)
})

