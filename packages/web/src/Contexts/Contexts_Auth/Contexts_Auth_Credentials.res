@decco @deriving(accessors)
type awsCredentials = {
  identityId: string,
  accessKeyId: string,
  secretKey: string,
  sessionToken: string,
  expiration: string,
}

module JWT = {
  @decco @deriving(accessors)
  type t = {
    exp: float,
    iat: float,
    identityId: string,
    accountAddress: string,
    raw: string
  }

  let decode = t_decode
  let encode = t_encode

  let makeFromString = s =>
    s
    ->Externals.JWTDecode.decode
    ->Js.Json.decodeObject
    ->Belt.Option.flatMap(o => {
      switch (
        o->Js.Dict.get("exp")->Belt.Option.flatMap(Js.Json.decodeNumber),
        o->Js.Dict.get("iat")->Belt.Option.flatMap(Js.Json.decodeNumber),
        o->Js.Dict.get("identityId")->Belt.Option.flatMap(Js.Json.decodeString),
        o->Js.Dict.get("accountAddress")->Belt.Option.flatMap(Js.Json.decodeString)
      ) {
        | (Some(exp), Some(iat), Some(identityId), Some(accountAddress)) => Some({
          exp: exp,
          iat: iat,
          identityId: identityId,
          accountAddress: accountAddress,
          raw: s
        })
        | _ => None
      }
    })
}

@decco @deriving(accessors)
type t = {
  awsCredentials: awsCredentials,
  jwt: JWT.t,
}

let decode = t_decode
let encode = t_encode

let make = (
  ~accessKeyId,
  ~secretKey,
  ~sessionToken,
  ~expiration,
  ~identityId,
  ~jwt,
) => {
  jwt: jwt,
  awsCredentials: {
    accessKeyId: accessKeyId,
    secretKey: secretKey,
    sessionToken: sessionToken,
    expiration: expiration,
    identityId: identityId,
  },
}

let isAwsCredentialValid = (~skew=0., awsCredentials) => {
  let exp = awsCredentials->expiration->Js.Date.fromString->Js.Date.valueOf
  let now = Js.Date.make()->Js.Date.valueOf

  now +. skew < exp
}

let isJwtValid = (~skew=0., jwt) => {
  let exp = JWT.exp(jwt) *. 1000.
  let now = Js.Date.make()->Js.Date.valueOf

  now +. skew < exp
}

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
    ->Belt.Option.flatMap(o =>
      switch decode(o) {
      | Ok(d) => Some(d)
      | Error(_) => None
      }
    )

  let write = (inst: t) =>
    getLocalStorage()->Belt.Option.forEach(localStorage => {
      Dom.Storage2.setItem(localStorage, key, inst->encode->Js.Json.stringify)
    })

  let clear = () => getLocalStorage()->Belt.Option.forEach(s => Dom.Storage2.removeItem(s, key))
}
