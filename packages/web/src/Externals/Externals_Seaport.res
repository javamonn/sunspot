module Client = {
  type t

  @deriving(abstract)
  type overrides = {defaultConduitKey: string}

  @deriving(abstract)
  type makeParams = {
    conduitKeyToConduit: Js.Dict.t<string>,
    overrides: overrides,
  }

  @new @module("@opensea/seaport-js")
  external make: (Externals_Ethereum.t, makeParams) => t = "Seaport"
}

module FulfillOrder = {
  @deriving(abstract)
  type tip = {amount: string, recipient: string}

  @deriving(abstract)
  type input = {order: Js.Json.t, @optional tips: array<tip>}

  @deriving(accessors)
  type useCase = {executeAllActions: unit => Js.Promise.t<Externals_Ethers.Transaction.t>}

  @send external execute: (Client.t, input) => Js.Promise.t<useCase> = "fulfillOrder"
}
