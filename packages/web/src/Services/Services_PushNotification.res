exception UnableToGetApplicationServerKey

module Query_WebPushApplicationServerKey = %graphql(`
  query WebPushApplicationServerKey {
    result: webPushApplicationServerKey {
      applicationServerKey
    }
  }
`)

let isSupported = () => %raw(`"PushManager" in globalThis`)

let applicationServerKeyRef = ref(None)

let getApplicationServerKey = () =>
  switch applicationServerKeyRef.contents {
  | Some(applicationServerKey) => Js.Promise.resolve(applicationServerKey)
  | None =>
    Contexts_Apollo_Client.inst.contents.query(
      ~query=module(Query_WebPushApplicationServerKey),
      (),
    ) |> Js.Promise.then_(result =>
      switch result {
      | Ok(
          {
            data: {result: {applicationServerKey}},
          }: ApolloClient__Core_ApolloClient.ApolloQueryResult.t__ok<
            Query_WebPushApplicationServerKey.t,
          >,
        ) =>
        applicationServerKeyRef := Some(applicationServerKey)
        Js.Promise.resolve(applicationServerKey)
      | Error(_) => Js.Promise.reject(UnableToGetApplicationServerKey)
      }
    )
  }

let getSubscription = () =>
  Externals.Webapi.Navigator.ServiceWorkerContainer.ready
  |> Js.Promise.then_(registration =>
    Externals.ServiceWorkerGlobalScope.ServiceWorkerRegistration.getSubscription(registration)
  )
  |> Js.Promise.then_(subscription => subscription->Js.Nullable.toOption->Js.Promise.resolve)

let subscribe = () => {
  open Externals.ServiceWorkerGlobalScope

  Js.Promise.all2((
    getApplicationServerKey(),
    Externals.Webapi.Navigator.ServiceWorkerContainer.ready,
  )) |> Js.Promise.then_(((applicationServerKey, registration)) =>
    ServiceWorkerRegistration.subscribe(
      registration,
      ServiceWorkerRegistration.subscribeOptions(~userVisibleOnly=true, ~applicationServerKey),
    )
  )
}
