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
  Js.log2("handlePushEvent", pushEvent)
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

let handleNotificationClickEvent = event => {
  let _ = event->NotificationClickEvent.notification->Notification.close

  Js.log2(
    "handleNotificationClickEvent",
    event->NotificationClickEvent.notification->Notification.data,
  )

  let openP =
    event
    ->NotificationClickEvent.notification
    ->Notification.data
    ->Js.Json.decodeObject
    ->Belt.Option.flatMap(o => o->Js.Dict.get("href"))
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.map(href =>
      Clients.openWindow(self->clients, href) |> Js.Promise.then_(_ => Js.Promise.resolve())
    )
    ->Belt.Option.getWithDefault(Js.Promise.resolve())

  NotificationClickEvent.waitUntil(event, openP)
}

let _ = self->addEventListener(#push(handlePushEvent))
let _ = self->addEventListener(#install(handleInstallEvent))
let _ = self->addEventListener(#notificationclick(handleNotificationClickEvent))
