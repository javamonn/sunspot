exception DeccoDecodeError(string)

let initialize = () => {
  open Externals.Sentry
  init(config(~dsn=Config.sentryDsn, ~normalizeDepth=10))
}

let setUserId = userId => {
  switch userId {
  | Some(userId) => Externals.Sentry.setUser(Externals.Sentry.user(~id=userId, ()))
  | None =>
    Externals.Sentry.configureScope(scope =>
      Externals.Sentry.Scope.setUser(scope, Js.Nullable.null)
    )
  }
}

let log = (tag, message) => {
  Js.log2(tag, message)
}

let logWithData = (tag, message, data) => {
  Js.log3(tag, message, data)
}

let promiseError = (tag, message, e) =>
  if Config.isProduction {
    Externals.Sentry.captureExceptionWithContext(
      Obj.magic(e),
      Externals.Sentry.exceptionContext(
        ~extra=Js.Json.object_(
          Js.Dict.fromArray([("tag", Js.Json.string(tag)), ("message", Js.Json.string(message))]),
        ),
        (),
      ),
    )
  } else {
    Js.log3(tag, message, e)
  }

let deccoError = (tag, message, e: Decco.decodeError) => {
  if Config.isProduction {
    DeccoDecodeError(e.message)
    ->Js.Exn.asJsExn
    ->Belt.Option.getWithDefault(e->Obj.magic)
    ->Externals.Sentry.captureExceptionWithContext(
      Externals.Sentry.exceptionContext(
        ~extra=Js.Json.object_(
          Js.Dict.fromArray([
            ("tag", Js.Json.string(tag)),
            ("message", Js.Json.string(message)),
            ("deccoPath", Js.Json.string(e.path)),
            ("deccoValue", e.value),
          ]),
        ),
        (),
      ),
    )
  } else {
    Js.log3(tag, message, e)
  }
}

let exn_ = (tag, message, e) =>
  if Config.isProduction {
    e
    ->Js.Exn.asJsExn
    ->Belt.Option.getWithDefault(e->Obj.magic)
    ->Externals.Sentry.captureExceptionWithContext(
      Externals.Sentry.exceptionContext(
        ~extra=Js.Json.object_(
          Js.Dict.fromArray([("tag", Js.Json.string(tag)), ("message", Js.Json.string(message))]),
        ),
        (),
      ),
    )
  } else {
    Js.log3(tag, message, e)
  }

let jsExn = (tag, message, e) =>
  if Config.isProduction {
    Externals.Sentry.captureExceptionWithContext(
      e,
      Externals.Sentry.exceptionContext(
        ~extra=Js.Json.object_(
          Js.Dict.fromArray([("tag", Js.Json.string(tag)), ("message", Js.Json.string(message))]),
        ),
        (),
      ),
    )
  } else {
    Js.log3(tag, message, e)
  }
