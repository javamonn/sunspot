module BigNumber = {
  type t

  @scope("BigNumber") @module("ethers") external makeFromString: string => t = "from"
  @scope("BigNumber") @module("ethers") external makeFromFloat: float => t = "from"

  @send external mul: (t, t) => t = "mul"
  @send external div: (t, t) => t = "div"
  @send external add: (t, t) => t = "add"
  @send external toString: t => string = "toString"
}

module Provider = {
  type t
  @new @scope("providers") @module("ethers")
  external makeJsonRpcProvider: string => t = "JsonRpcProvider"

  @new @scope("providers") @module("ethers")
  external makeInfuraProvider: (int, string) => t = "InfuraProvider"

  @new @scope("providers") @module("ethers")
  external makeInfuraWebSocketProvider: (int, string) => t = "InfuraWebSocketProvider"
}

module Signer = {
  type t
}

module Interface = {
  type t
  @new @scope("utils") @module("ethers") external makeWithString: string => t = "Interface"
}

module Contract = {
  type t
  @new @module("ethers")
  external makeWithProvider: (string, Interface.t, Provider.t) => t = "Contract"

  @new @module("ethers")
  external makeWithSigner: (string, Interface.t, Signer.t) => t = "Contract"

  @deriving(abstract)
  type transactionOverrides = {
    @optional value: BigNumber.t,
    @optional gasLimit: BigNumber.t,
  }
}

module Utils = {
  @scope("utils") @module("ethers") external parseUnits: string => BigNumber.t = "parseUnits"
  @scope("utils") @module("ethers")
  external formatUnits: (BigNumber.t, string) => string = "formatUnits"
}

module TransactionReceipt = {
  // https://docs.ethers.io/v5/api/providers/types/#providers-TransactionReceipt
  type t = {transactionHash: string, status: bool}
}

module Transaction = {
  // https://docs.ethers.io/v5/api/utils/transactions/#Transaction
  @deriving(accessors)
  type t = {hash: string}
}
