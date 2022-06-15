type t

@scope("globalThis") @val external inst: Js.Nullable.t<t> = "ethereum"

@deriving(accessors)
type sendResult<'a> = {
  id: Js.Nullable.t<string>,
  jsonrpc: string,
  result: array<'a>,
}

@send external send: (t, string) => Js.Promise.t<sendResult<'a>> = "send"
@send external on: (t, @string [#accountsChanged(array<string> => unit)]) => unit = "on"
@send
external removeListener: (t, @string [#accountsChanged(array<string> => unit)]) => unit =
  "removeListener"

let requestAccounts = inst => send(inst, "eth_requestAccounts")
