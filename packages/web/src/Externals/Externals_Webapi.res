module Navigator = {
  module ServiceWorkerContainer = {
    @val @scope(("navigator", "serviceWorker"))
    external register: string => Js.Promise.t<
      Externals_ServiceWorkerGlobalScope.ServiceWorkerRegistration.t,
    > = "register"

    @val @scope(("navigator", "serviceWorker"))
    external ready: Js.Promise.t<Externals_ServiceWorkerGlobalScope.ServiceWorkerRegistration.t> =
      "ready"
  }
}

module Location = {
  @val @scope("location") external origin: string = "origin"
}

module EventTarget = {
  type t

  external unsafeAsEventTarget: 'a => t = "%identity"
  @send external addEventListener: (t, string, Dom.event => unit) => unit = "addEventListener"
  @send external removeEventListener: (t, string, Dom.event => unit) => unit = "removeEventListener"
}

module Window = {
  @val @scope("window") external open_: string => unit = "open"
  @val external inst: Dom.window = "window"

  @get external innerWidth: Dom.window => float = "innerWidth"
  @get external innerHeight: Dom.window => float = "innerHeight"
}

module URL = {
  type t

  @new external make: string => t = "URL"

  @get external protocol: t => string = "protocol"
  @get external pathname: t => string = "pathname"
  @get external hostname: t => string = "hostname"
}

module URLSearchParams = {
  type t

  @new external make: string => t = "URLSearchParams"
  @send external get: (t, string) => Js.Nullable.t<string> = "get"
}

module Element = {
  @deriving(accessors)
  type domRect = {
    width: float,
    height: float,
  }
  @send external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"
}

module Intl = {
  module NumberFormat = {
    type t

    @deriving(abstract)
    type params = {
      style: string,
      maximumSignificantDigits: int,
    }
    @scope("Intl") @new external make: (string, params) => t = "NumberFormat"

    @send external format_: (t, float) => string = "format"
  }
}
