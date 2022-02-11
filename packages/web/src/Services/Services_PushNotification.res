exception UnableToGetApplicationServerKey
exception PushNotificationPermissionDenied

let isSupported = () => %raw(`"PushManager" in globalThis`)
let applicationServerKey = "BIjfRVSpCkHcZv7YFwDe7sCFilNHqdUl9fwI_NHAfFZbO9ZmQp4IlOEYhcqPgwAplvDCjOPKHSKn5dtZcl9z__M"

let getSubscription = () =>
  Externals.Webapi.Navigator.ServiceWorkerContainer.ready
  |> Js.Promise.then_(registration =>
    Externals.ServiceWorkerGlobalScope.ServiceWorkerRegistration.getSubscription(registration)
  )
  |> Js.Promise.then_(subscription => subscription->Js.Nullable.toOption->Js.Promise.resolve)

let permissionState = () => {
  open Externals.ServiceWorkerGlobalScope

  Externals.Webapi.Navigator.ServiceWorkerContainer.ready |> Js.Promise.then_(registration =>
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

  Externals.Webapi.Navigator.ServiceWorkerContainer.ready
  |> Js.Promise.then_((registration) => {
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
