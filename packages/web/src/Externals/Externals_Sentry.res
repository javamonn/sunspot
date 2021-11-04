@deriving(abstract)
type config = {
  dsn: string,
  normalizeDepth: int,
}
@module("@sentry/browser") external init: config => unit = "init"

@deriving(abstract)
type exceptionContext = {
  @optional tags: Js.Dict.t<string>,
  @optional extra: Js.Json.t,
  @optional user: Js.Json.t,
  @optional level: Js.Json.t,
  @optional fingerprint: Js.Json.t,
}

@module("@sentry/browser")
external captureExceptionWithContext: (Js.Exn.t, exceptionContext) => unit = "captureException"

@module("@sentry/browser")
external captureException: Js.Exn.t => unit = "captureException"

@module("@sentry/browser")
external captureMessage: string => unit = "captureMessage"

@module("@sentry/browser")
external setContext: (string, Js.Json.t) => unit = "setContext"

@deriving(abstract)
type user = {
  @optional id: string,
  @optional username: string,
  @optional email: string,
  @optional @as("ip_address") ipAddress: string,
}

@module("@sentry/browser")
external setUser: user => unit = "setUser"

@module("@sentry/browser")
external lastEventId: unit => string = "lastEventId"

module Scope = {
  type t
  @send external setUser: (t, Js.Nullable.t<user>) => unit = "setUser"
}

@module("@sentry/browser")
external configureScope: (Scope.t => unit) => unit = "configureScope"
