open Externals.ServiceWorkerGlobalScope

module PushEventData = {
  @decco @deriving(accessors)
  type t = {
    title: string,
    options: Js.Json.t,
  }

  let decode = t_decode

  external unsafeOptionsAsShowNotificationOptions: Js.Json.t => ServiceWorkerRegistration.showNotificationOptions =
    "%identity"
}

let handlePushEvent = pushEvent => {
  switch pushEvent->PushEvent.data->PushEvent.json->PushEventData.decode {
  | Ok(pushEventData) =>
    PushEvent.waitUntil(
      pushEvent,
      self
      ->registration
      ->ServiceWorkerRegistration.showNotification(
        pushEventData->PushEventData.title,
        pushEventData->PushEventData.options->PushEventData.unsafeOptionsAsShowNotificationOptions,
      ) |> Js.Promise.then_(_ => Js.Promise.resolve()),
    )
  | Error(e) => Services.Logger.deccoError("ServiceWorker", "Unable to decode push event data.", e)
  }
}

let handleInstallEvent = _ => {
  Services.Logger.log("ServiceWorker", "Installed.")
}

let _ = self->addEventListener(#push(handlePushEvent))
let _ = self->addEventListener(#install(handleInstallEvent))
