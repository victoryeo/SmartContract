const express       = require('express')
const Web3 = require('web3')
const contract = require('truffle-contract')
const path = require('path')

const router = express.Router()

let contractABI = require(path.join(__dirname, '../../build/contracts/MetaCoin.json'))
let provider = new Web3.providers.HttpProvider("http://localhost:7545")
let masterContract = contract(contractABI)
masterContract.setProvider(provider)

const web3 = new Web3()
web3.setProvider(provider)

getAccount = async() => {
  accounts = await web3.eth.getAccounts();
}
getAccount()

let contractInstance
let keyStore
let secretkey = web3.utils.randomHex(8)
masterContract.deployed().then(function(instance) {
  console.log("address " + instance.address)
  contractInstance = instance
}).then(function(result) {
  console.log("result " + result)
})

router.get('/', (req, res) => {
  console.log("address "+ contractInstance.address)
  res.send("contract instance" + contractInstance.address)
})

router.get('/addAccount', (req, res) => {
  objectAcc = web3.eth.accounts.create()
  // add account to wallet
  web3.eth.accounts.wallet.add(objectAcc)
  console.log("wallet 0 " + web3.eth.accounts.wallet[0].address)
  objectKey = web3.eth.accounts.wallet.encrypt(secretkey)
  console.log(objectKey)
  keyStore = objectKey
  res.send(objectKey)
})

router.get('/sendCoin/:amount', (req, res) => {
  sendAmount = req.params.amount
  transferCoin = async () => {
    result = await contractInstance.sendCoin(walletObj[0].address, sendAmount, {from: accounts[0]})
    console.log(result)
    res.send(result)
  }
  //decrypt wallet
  walletObj = web3.eth.accounts.wallet.decrypt(keyStore, secretkey)
  transferCoin()
})

router.get('/getCoinBal', (req, res) => {
  getCoinBalance = async () => {
    let bal0 = await contractInstance.getBalance(walletObj[0].address)
    console.log(bal0)
    res.send("Coin Balance is " + bal0)
  }
  //decrypt wallet
  walletObj = web3.eth.accounts.wallet.decrypt(keyStore, secretkey)
  getCoinBalance()
})

router.get('/sendEther/:amount', (req, res) => {
  sendAmount = req.params.amount
  transferEth = async() => {
    let txObj = {
      from: accounts[0],
      to: walletObj[0].address,
      value:  web3.utils.toWei(sendAmount, "ether"),
      gas: 4600000
    }
    //obj = await web3.eth.accounts.signTransaction(txObj, walletObj[0].privateKey)
    //console.log(obj)

    //await web3.eth.sendSignedTransaction(obj.rawTransaction)
    await web3.eth.sendTransaction(txObj)
      .then(function(err, txHash) {
          if (!err) {
                console.log("txHash " + txHash)
	        res.send(txHash)
	  }
          else {
                console.log(err)
	        res.send(err)
	  }
    })
  }
  //decrypt wallet
  walletObj = web3.eth.accounts.wallet.decrypt(keyStore, secretkey)
  transferEth()
})

router.get('/getEthBal', (req, res) => {
  getEthBalance = async() => {
    let bal0 = await web3.eth.getBalance(walletObj[0].address)
    console.log(bal0)
    res.send("Ether Balance is " + bal0)
  }
  //decrypt wallet
  walletObj = web3.eth.accounts.wallet.decrypt(keyStore, secretkey)
  getEthBalance()
})

module.exports = router

