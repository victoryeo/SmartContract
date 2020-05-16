const Web3 = require('web3')
const contract = require('truffle-contract')
const path = require('path')

let contractABI = require(path.join(__dirname, '../build/contracts/MetaCoin.json'))
let provider = new Web3.providers.HttpProvider("http://localhost:7545")
let masterContract = contract(contractABI)
masterContract.setProvider(provider)

const web3 = new Web3()
web3.setProvider(provider)

let accounts
getAccount = async () => {
  accounts = await web3.eth.getAccounts();
  console.log(accounts)
}

getAccount()

getBalance = async (instance) => {
  let bal0 = await instance.getBalance(accounts[0])
  let bal1 = await instance.getBalance(accounts[1])
  console.log(bal0)
  console.log(bal1)
}

fix_account = "0x8279F5648427919CEdb0fc413E9eFE34ff6D2baf"
masterContract.deployed().then(function(instance) {
  console.log(instance.address)
  instance.sendCoin(accounts[1], 10, {from: accounts[0]})
  getBalance(instance)
}).then(function(result) {
  console.log("result " + result)
})
