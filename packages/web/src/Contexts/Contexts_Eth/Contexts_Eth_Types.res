type connected = {provider: Externals.Ethereum.t, address: string, web3: Externals.Web3.t}
type notConnected = {provider: Externals.Ethereum.t, web3: Externals.Web3.t}

type ethState =
  | Connected(connected)
  | NotConnected(notConnected)
  | Web3Unavailable
  | Unknown
