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
    Services.Logger.logWithData(
      "ServiceWorker",
      "handle event push",
      Js.Dict.fromArray([
        (
          "tag",
          pushEventData
          ->PushEventData.options
          ->Js.Json.decodeObject
          ->Belt.Option.flatMap(o => o->Js.Dict.get("tag"))
          ->Belt.Option.flatMap(Js.Json.decodeString)
          ->Belt.Option.getWithDefault("")
          ->Js.Json.string,
        ),
      ])->Js.Json.object_,
    )
    Js.log(pushEventData)
    PushEvent.waitUntil(
      pushEvent,
      self
      ->registration
      ->ServiceWorkerRegistration.showNotification(
        pushEventData->PushEventData.title,
        pushEventData->PushEventData.options->PushEventData.unsafeOptionsAsShowNotificationOptions,
      ) |> Js.Promise.then_(_ => Js.Promise.resolve()),
    )
  | exception e => Services.Logger.jsExn("ServiceWorker", "Unable to decode push event data", e)
  | Error(e) => Services.Logger.deccoError("ServiceWorker", "Unable to decode push event data.", e)
  }
}

let handleInstallEvent = _ => {
  Services.Logger.log("ServiceWorker", "install")
}

let handleNotificationCloseEvent = event => {
  Services.Logger.logWithData(
    "ServiceWorker",
    "handle event notificationclose",
    Js.Dict.fromArray([
      ("tag", event->NotificationCloseEvent.notification->Notification.tag->Js.Json.string),
    ])->Js.Json.object_,
  )
}

let handleNotificationClickEvent = event => {
  Services.Logger.logWithData(
    "ServiceWorker",
    "handle event notificationclick",
    Js.Dict.fromArray([
      ("tag", event->NotificationClickEvent.notification->Notification.tag->Js.Json.string),
    ])->Js.Json.object_,
  )
  let _ = event->NotificationClickEvent.notification->Notification.close

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
let _ = self->addEventListener(#notificationclose(handleNotificationCloseEvent))
