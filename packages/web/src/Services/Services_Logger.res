exception DeccoDecodeError(string)

let initialize = () => {
  Externals.Sentry.init(Externals.Sentry.config(~dsn=Config.sentryDsn, ~normalizeDepth=10))
  Externals.Amplitude.init(Externals.Amplitude.getInstance(), Config.amplitudeApiKey)
}

let setUserId = userId =>
  if Config.isProduction && Config.isBrowser() {
    switch userId {
    | Some(userId) => Externals.Sentry.setUser(Externals.Sentry.user(~id=userId, ()))
    | None =>
      Externals.Sentry.configureScope(scope =>
        Externals.Sentry.Scope.setUser(scope, Js.Nullable.null)
      )
    }
    Externals.Amplitude.setUserId(Externals.Amplitude.getInstance(), userId)
  } else {
    Js.log2("setUserId", userId)
  }

let log = (tag, message) =>
  if Config.isProduction && Config.isBrowser() {
    Externals.Amplitude.logEvent(Externals.Amplitude.getInstance(), `${tag} - ${message}`)
  } else {
    Js.log2(tag, message)
  }

let logWithData = (tag, message, data) =>
  if Config.isProduction && Config.isBrowser() {
    Externals.Amplitude.logEventWithProperties(
      Externals.Amplitude.getInstance(),
      `${tag} - ${message}`,
      data,
    )
  } else {
    Js.log3(tag, message, data)
  }

let promiseError = (tag, message, e) =>
  if Config.isProduction && Config.isBrowser() {
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

let apolloError = (tag, message, e) =>
  if Config.isProduction && Config.isBrowser() {
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
  if Config.isProduction && Config.isBrowser() {
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

let exn_ = (~tag, ~message, ~extra=?, e) =>
  if Config.isProduction && Config.isBrowser() {
    e
    ->Js.Exn.asJsExn
    ->Belt.Option.getWithDefault(e->Obj.magic)
    ->Externals.Sentry.captureExceptionWithContext(
      Externals.Sentry.exceptionContext(
        ~extra=Js.Json.object_(
          Js.Dict.fromArray(
            Belt.Array.concat(
              [("tag", Js.Json.string(tag)), ("message", Js.Json.string(message))],
              extra->Belt.Option.getWithDefault([]),
            ),
          ),
        ),
        (),
      ),
    )
  } else {
    Js.log3(tag, message, e)
  }

let jsExn = (tag, message, e) =>
  if Config.isProduction && Config.isBrowser() {
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
