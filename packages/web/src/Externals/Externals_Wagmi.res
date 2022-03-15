module Connector = {
  @deriving(accessors)
  type t = {
    id: string,
    name: string,
    ready: bool,
    provider: Externals_Ethereum.t,
  }
}

module Provider = {
  type connectorsOptions = {chainId: int}
  @module("wagmi") @react.component
  external make: (
    ~autoConnect: bool=?,
    ~connectors: connectorsOptions => array<Connector.t>=?,
    ~children: React.element,
  ) => React.element = "Provider"
}

@deriving(accessors)
type currency = {
  decimals: int,
  name: string,
  symbols: string,
}
@deriving(accessors)
type blockExplorers = {
  name: string,
  url: string,
}
@deriving(accessors)
type chain = {
  id: int,
  name: string,
  nativeCurrency: option<currency>,
  rpcUrls: array<string>,
  blockExplorers: option<array<blockExplorers>>,
  testnet: option<bool>,
}

// mainnet, rinkeby, etc
@val @module("wagmi") external chain: Js.Dict.t<chain> = "chain"
@val @module("wagmi") external defaultChains: array<chain> = "defaultChains"

// connectors

type injectedConnectorOptions = {shimDisconnect: bool}
type injectedConnectorParams = {chains: array<chain>, options: injectedConnectorOptions}
@new @module("wagmi/connectors/injected")
external makeInjectedConnector: injectedConnectorParams => Connector.t = "InjectedConnector"

type walletConnectConnectorOptions = {
  infuraId: string,
  qrcode: bool,
}
type walletConnectConnectorParams = {options: walletConnectConnectorOptions}
@new @module("wagmi/connectors/walletConnect")
external makeWalletConectConnector: walletConnectConnectorParams => Connector.t =
  "WalletConnectConnector"

module UseConnect = {
  @deriving(accessors)
  type data = {
    connector: Connector.t,
    connectors: array<Connector.t>,
  }
  @deriving(accessors)
  type result = {
    data: option<data>,
    error: option<Js.Exn.t>,
    loading: option<bool>,
  }

  @deriving(accessors)
  type connectResultData = {
    account: option<string>,
    provider: Externals_Ethereum.t,
    chain: option<chain>,
  }

  @deriving(accessors)
  type connectResult = {
    data: option<connectResultData>,
    error: option<Js.Exn.t>,
  }
  @module("wagmi")
  external use: unit => (result, Connector.t => Js.Promise.t<connectResult>) = "useConnect"
}

module UseAccount = {
  @deriving(accessors)
  type ens = {
    avatar: string,
    name: string,
  }
  @deriving(accessors)
  type data = {
    address: string,
    connector: Connector.t,
    ens: option<ens>,
  }
  @deriving(accessors)
  type result = {
    data: option<data>,
    error: option<Js.Exn.t>,
    loading: bool,
  }

  @module("wagmi")
  external use: unit => (result, unit => unit) = "useAccount"
}

module UseSignMessage = {
  @deriving(accessors)
  type result = {
    data: option<string>,
    error: option<Js.Exn.t>,
    loading: option<bool>,
  }

  @deriving(accessors)
  type options = {message: string}

  @module("wagmi")
  external use: unit => (result, options => Js.Promise.t<result>) = "useSignMessage"
}

module UseTransaction = {
  @deriving(accessors)
  type result = {
    data: option<Js.Json.t>,
    error: option<string>,
  }

  type request = {
    @as("to") to_: string,
    value: Externals_Ethers.BigNumber.t,
  }

  type options = {request: request}

  @module("wagmi")
  external use: unit => (result, options => Js.Promise.t<result>) = "useTransaction"
}

module UseContext = {
  type state = {connecting: bool}
  type t = {state: state}

  @module("wagmi")
  external use: unit => t = "useContext"
}
