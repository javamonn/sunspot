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

module Window = {
  @val @scope("window") external open_: string => unit = "open"
}
