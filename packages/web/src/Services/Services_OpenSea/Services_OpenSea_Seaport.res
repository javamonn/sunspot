%%raw(`
  import {fulfillOrder as rawFulfillOrder, estimateCurrentPrice as rawEstimateCurrentPrice} from './Raw/seaport'
  import {make as rawMakeWyvernExchangeContract} from './Raw/wyvern-exchange-contract.mjs'
`)

@deriving(abstract)
type fulfillOrderParams = {
  order: Externals.OpenSea.order,
  accountAddress: string,
  @optional recipientAddress: string,
  @optional referrerAddress: string,
  networkName: [
    | #main
    | #rinkeby
  ],
  wyvernExchangeContract: Externals.Ethers.Contract.t,
}

let fulfillOrder: fulfillOrderParams => Js.Promise.t<Externals.Ethers.Transaction.t> = %raw(
  "rawFulfillOrder"
)

@deriving(abstract)
type makeWyvernExchangeContractParams = {web3: Externals.Wagmi.Signer.t}

let makeWyvernExchangeContract: makeWyvernExchangeContractParams => Externals.Ethers.Contract.t = %raw(
  "rawMakeWyvernExchangeContract"
)

let estimateCurrentPrice = %raw("rawEstimateCurrentPrice")
