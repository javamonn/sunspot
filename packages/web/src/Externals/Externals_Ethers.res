module BigNumber = {
  type t

  @scope("BigNumber") @module("ethers") external makeFromString: string => t = "from"
}
