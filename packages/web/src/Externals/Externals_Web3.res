type t

@module @new external make: Externals_Ethereum.t => t = "web3"

@scope("eth") @send external getAccounts: t => Js.Promise.t<array<string>> = "getAccounts"

@scope(("eth", "personal")) @send
external personalSign: (t, string, string) => Js.Promise.t<string> = "sign"
