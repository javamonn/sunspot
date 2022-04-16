type contract
let abi = %raw(`[
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "feeValue",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "wyvernExchangeValue",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "wyvernExchangeData",
        "type": "bytes"
      },
      {
        "internalType": "bytes",
        "name": "signature",
        "type": "bytes"
      }
    ],
    "name": "atomicMatch",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }
]`)
let address = "0xaf49ad1a961e9feafa3db36af216c17ef54362d0"

let interface = Externals_Ethers.Interface.makeWithString(abi)
let makeContract = (signer): contract =>
  Obj.magic(Externals_Ethers.Contract.makeWithSigner(address, interface, signer))

@send
external atomicMatch: (
  contract,
  Externals.Ethers.BigNumber.t,
  Externals.Ethers.BigNumber.t,
  string,
  string,
) => Js.Promise.t<Externals.Ethers.Transaction.t> = "atomicMatch"
