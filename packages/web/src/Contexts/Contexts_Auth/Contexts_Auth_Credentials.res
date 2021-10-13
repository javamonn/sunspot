@deriving(accessors)
type t = {
  identityId: string,
  accessKeyId: string,
  secretKey: string,
  sessionToken: string,
  expiration: string,
}

let make = (~accessKeyId, ~secretKey, ~sessionToken, ~expiration, ~identityId) => {
  accessKeyId: accessKeyId,
  secretKey: secretKey,
  sessionToken: sessionToken,
  expiration: expiration,
  identityId: identityId,
}

external unsafeOfJson: Js.Json.t => t = "%identity"

module LocalStorage = {
  let key = "__sunspot__credentials"

  let getLocalStorage = () =>
    try Some(Dom.Storage2.localStorage) catch {
    | _ => None
    }

  let read = () =>
    getLocalStorage()
    ->Belt.Option.flatMap(s => Dom.Storage2.getItem(s, key))
    ->Belt.Option.flatMap(json =>
      try {
        Some(Js.Json.parseExn(json))
      } catch {
      | _ => None
      }
    )
    ->Belt.Option.map(unsafeOfJson)

  let write = (credentials: t) =>
    switch (getLocalStorage(), Js.Json.stringifyAny(credentials)) {
    | (Some(s), Some(json)) => Dom.Storage2.setItem(s, key, json)
    | _ => ()
    }

  let clear = () => getLocalStorage()->Belt.Option.forEach(s => Dom.Storage2.removeItem(s, key))
}
