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
let address = "0x2fa99301cf59c3f343955e39c3545a669e1868bd"

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
  Externals.Ethers.Contract.transactionOverrides,
) => Js.Promise.t<Externals.Ethers.Transaction.t> = "atomicMatch"

@scope("estimateGas") @send
external estimateGasAtomicMatch: (
  contract,
  Externals.Ethers.BigNumber.t,
  Externals.Ethers.BigNumber.t,
  string,
  string,
  Externals.Ethers.Contract.transactionOverrides,
) => Js.Promise.t<Externals.Ethers.BigNumber.t> = "atomicMatch"
