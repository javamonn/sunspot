type instance

/**
 * amplitude-js has a dependency on window, shim when running in node
 * during local dev and static html export.
 */
let getInstance: unit => instance = %raw(`
  function () {
    if (typeof window !== 'undefined') {
      return require("amplitude-js")
    } else {
      return {
        init: () => {},
        logWithEvent: () => {}
      }
    }
  }
`)

@send external init: (instance, string) => unit = "init"

/* https://help.amplitude.com/hc/en-us/articles/115001361248#settings-configuration-options */
@deriving(abstract)
type initOptions = {
  @optional
  batchEvents: bool,
  @optional
  cookieExpiration: int,
  @optional
  cookieName: string,
  @optional
  deviceId: string,
  @optional
  deviceIdFromurlParam: bool,
  @optional
  domain: string,
  @optional
  eventUploadPeriodMillis: int,
  @optional
  eventUploadThreshold: int,
  @optional
  forceHttps: bool,
  @optional
  includeGclid: bool,
  @optional
  includeReferrer: bool,
  @optional
  includeUtm: bool,
  @optional
  language: string,
  @optional
  logLevel: string,
  @optional
  optOut: bool,
  @optional
  platform: string,
  @optional
  saveEvents: bool,
  @optional
  savedMaxCount: int,
  @optional
  saveParamsReferrerOncePerSession: bool,
  @optional
  sessionTimeout: int,
  @optional
  trackingOptions: Js.Dict.t<bool>,
  @optional
  unsertParamsReferrerOnNewSession: bool,
  @optional
  uploadBatchSize: int,
}

@send
external initWithOptions: (
  instance,
  option<string>,
  option<initOptions>,
  option<unit => unit>,
) => unit = "init"

@send external logEvent: (instance, string) => unit = "logEvent"

@send external logEventWithProperties: (instance, string, Js.Json.t) => unit = "logEvent"

@send external setUserId: (instance, option<string>) => unit = "setUserId"
