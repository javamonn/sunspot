type t
@val external self: t = "self"

module PushEvent = {
  type data

  @deriving(accessors)
  type t = {data: data}

  @send external waitUntil: (t, Js.Promise.t<unit>) => unit = "waitUntil"
  @send external json: data => Js.Json.t = "json"
}

module InstallEvent = {
  type t
}

@send
external addEventListener: (
  t,
  @string [#push(PushEvent.t => unit) | #install(InstallEvent.t => unit)],
) => unit = "addEventListener"

module PushSubscription = {
  @deriving(accessors)
  type t = {
    endpoint: string,
    expirationTime: Js.Nullable.t<float>,
    options: Js.Json.t,
    subscriptionId: string,
  }
  
  @deriving(accessors)
  type keys = {
    p256dh: string,
    auth: string,
  }

  @deriving(accessors)
  type serialized = {
    endpoint: string,
    expirationTime: Js.Nullable.t<float>,
    keys: keys,
  }

  @send external getSerialized: t => serialized = "toJSON"
}

module ServiceWorkerRegistration = {
  type t

  @deriving(abstract)
  type subscribeOptions = {
    userVisibleOnly: bool,
    applicationServerKey: string,
  }
  @send @scope("pushManager")
  external subscribe: (t, subscribeOptions) => Js.Promise.t<PushSubscription.t> = "subscribe"

  @send @scope("pushManager")
  external getSubscription: t => Js.Promise.t<Js.Nullable.t<PushSubscription.t>> = "getSubscription"

  @deriving(abstract)
  type action = {
    action: string,
    title: string,
    icon: string,
  }
  @deriving(abstract)
  type showNotificationOptions = {
    @optional badge: string,
    @optional body: string,
    @optional actions: array<action>,
    @optional data: Js.Json.t,
    @optional dir: string,
    @optional icon: string,
    @optional image: string,
    @optional lang: string,
    @optional renotify: bool,
    @optional requireInteraction: bool,
    @optional silent: bool,
    @optional tag: string,
    @optional timestamp: float,
    @optional vibrate: array<float>,
  }
  @send
  external showNotification: (
    t,
    string,
    showNotificationOptions,
  ) => Js.Promise.t<Js.Nullable.t<unit>> = "showNotification"
}

@get
external registration: t => ServiceWorkerRegistration.t = "registration"
