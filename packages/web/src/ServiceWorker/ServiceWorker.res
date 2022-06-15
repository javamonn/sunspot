open Externals.ServiceWorkerGlobalScope

module PushEventData = {
  @decco @deriving(accessors)
  type t = {
    title: string,
    options: Js.Json.t,
    sentAt: option<float>,
  }

  let decode = t_decode

  external unsafeOptionsAsShowNotificationOptions: Js.Json.t => ServiceWorkerRegistration.showNotificationOptions =
    "%identity"
}

let handleActivateEvent = _ => {
  Services.Logger.initialize()
}

let handlePushEvent = pushEvent => {
  switch pushEvent->PushEvent.data->PushEvent.json->PushEventData.decode {
  | Ok(pushEventData) =>
    let tag =
      pushEventData
      ->PushEventData.options
      ->Js.Json.decodeObject
      ->Belt.Option.flatMap(o => o->Js.Dict.get("tag"))
      ->Belt.Option.flatMap(Js.Json.decodeString)
      ->Belt.Option.getWithDefault("")

    Services.Logger.logWithData(
      "ServiceWorker",
      "handle event push",
      Js.Dict.fromArray([("tag", Js.Json.string(tag))])->Js.Json.object_,
    )

    let isExpired =
      tag !== "marketing" && {
          let sentAt =
            pushEventData->PushEventData.sentAt->Belt.Option.getWithDefault(Js.Date.now())

          sentAt <= Js.Date.now() -. 1000.0 *. 60.0 *. 5.0
        }

    if !isExpired {
      PushEvent.waitUntil(
        pushEvent,
        self
        ->registration
        ->ServiceWorkerRegistration.showNotification(
          pushEventData->PushEventData.title,
          pushEventData
          ->PushEventData.options
          ->PushEventData.unsafeOptionsAsShowNotificationOptions,
        ) |> Js.Promise.then_(_ => Js.Promise.resolve()),
      )
    }
  | exception e =>
    Services.Logger.exn_(~tag="ServiceWorker", ~message="Unable to decode push event data", e)
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

  let notificationData =
    event->NotificationClickEvent.notification->Notification.data->Js.Json.decodeObject

  let destinationUrl = switch (
    event->NotificationClickEvent.action,
    notificationData
    ->Belt.Option.flatMap(o => o->Js.Dict.get("href"))
    ->Belt.Option.flatMap(Js.Json.decodeString),
    notificationData
    ->Belt.Option.flatMap(o => o->Js.Dict.get("quickbuyUrl"))
    ->Belt.Option.flatMap(Js.Json.decodeString),
  ) {
  | ("buy", _, quickbuyUrl) => quickbuyUrl
  | (_, href, _) => href
  }

  let openP =
    destinationUrl
    ->Belt.Option.map(destinationUrl =>
      Clients.openWindow(self->clients, destinationUrl) |> Js.Promise.then_(_ =>
        Js.Promise.resolve()
      )
    )
    ->Belt.Option.getWithDefault(Js.Promise.resolve())

  NotificationClickEvent.waitUntil(event, openP)
}

let _ = self->addEventListener(#install(handleInstallEvent))
let _ = self->addEventListener(#activate(handleActivateEvent))
let _ = self->addEventListener(#push(handlePushEvent))
let _ = self->addEventListener(#notificationclick(handleNotificationClickEvent))
let _ = self->addEventListener(#notificationclose(handleNotificationCloseEvent))
let _ = Workbox.register()
