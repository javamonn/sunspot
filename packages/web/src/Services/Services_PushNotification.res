exception UnableToGetApplicationServerKey
exception PushNotificationPermissionDenied

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

let permissionState = () => {
  open Externals.ServiceWorkerGlobalScope

  Js.Promise.all2((
    getApplicationServerKey(),
    Externals.Webapi.Navigator.ServiceWorkerContainer.ready,
  )) |> Js.Promise.then_(((applicationServerKey, registration)) =>
    ServiceWorkerRegistration.PermissionState.execute(
      registration,
      ServiceWorkerRegistration.PermissionState.options(
        ~userVisibleOnly=true,
        ~applicationServerKey,
      ),
    )
  )
}

let subscribe = (~onShowSnackbar: Contexts_Snackbar.openSnackbar) => {
  open Externals.ServiceWorkerGlobalScope

  Js.Promise.all2((
    getApplicationServerKey(),
    Externals.Webapi.Navigator.ServiceWorkerContainer.ready,
  )) |> Js.Promise.then_(((applicationServerKey, registration)) => {
    let timeoutId = Js.Global.setTimeout(() => {
      let _ = Externals.Raw.isBrave() |> Js.Promise.then_(isBrave => {
        if isBrave {
          onShowSnackbar(
            ~message=<span className={Cn.make(["whitespace-pre-wrap"])}>
              {React.string(
                "brave may require you to manually enable Google services for push messaging.\n\nTo enable:\n1. open the brave menu\n2. select \"Settings\"\n3. select \"Security and Privacy\"\n4. locate and enable the setting \"Use Google services for push messaging.\"\n5. relaunch the browser.",
              )}
            </span>,
            ~type_=Contexts_Snackbar.TypeWarning,
            (),
          )
        }
        Js.Promise.resolve()
      })
    }, 4000)

    ServiceWorkerRegistration.subscribe(
      registration,
      ServiceWorkerRegistration.subscribeOptions(~userVisibleOnly=true, ~applicationServerKey),
    ) |> Js.Promise.then_(result => {
      let _ = Js.Global.clearTimeout(timeoutId)
      Js.Promise.resolve(result)
    })
  })
}

let checkPermissionAndGetSubscription = (~onShowSnackbar: Contexts_Snackbar.openSnackbar) =>
  permissionState() |> Js.Promise.then_(permissionState =>
    switch permissionState {
    | #denied => Js.Promise.resolve(Error(PushNotificationPermissionDenied))
    | _ =>
      getSubscription()
      |> Js.Promise.then_(subscription => {
        switch subscription {
        | Some(subscription) => Js.Promise.resolve(subscription)
        | None => subscribe(~onShowSnackbar)
        }
      })
      |> Js.Promise.then_(subscription => {
        Js.Promise.resolve(Ok(subscription))
      })
    }
  )
