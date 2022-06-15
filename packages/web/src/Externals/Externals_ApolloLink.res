module Observable = {
  type t

  @send external map: (t, Js.Json.t => Js.Json.t) => t = "map"
}

@deriving(accessors)
type operation = {
  query: Js.Json.t,
  variables: Js.Json.t,
  operationName: string,
  extensions: Js.Json.t,
  setContext: Js.Json.t => Js.Json.t,
  getContext: unit => Js.Json.t,
  toKey: unit => string,
}

type requestHandler = (operation, operation => Observable.t) => option<Observable.t>

@new @module("apollo-link")
external make: requestHandler => ReasonMLCommunity__ApolloClient.Link.t = "ApolloLink"
