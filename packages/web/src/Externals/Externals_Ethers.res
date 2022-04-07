module BigNumber = {
  type t

  @scope("BigNumber") @module("ethers") external makeFromString: string => t = "from"
  @scope("BigNumber") @module("ethers") external makeFromFloat: float => t = "from"
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

module Interface = {
  type t
  @new @scope("utils") @module("ethers") external makeWithString: string => t = "Interface"
}

module Contract = {
  type t
  @new @module("ethers")
  external makeWithProvider: (string, Interface.t, Provider.t) => t = "Contract"
}

module Utils = {
  @scope("utils") @module("ethers") external parseUnits: string => BigNumber.t = "parseUnits"
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
