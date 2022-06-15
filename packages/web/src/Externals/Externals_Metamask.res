type provider = Externals_Ethereum.t

@module("@metamask/detect-provider")
external detectEthereumProvider: unit => Js.Promise.t<Js.Nullable.t<provider>> = "default"
