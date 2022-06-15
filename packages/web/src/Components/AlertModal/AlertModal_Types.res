module CollectionOption = {
  @deriving(abstract)
  type t = {
    name: option<string>,
    slug: string,
    imageUrl: option<string>,
    contractAddress: string,
  }
  let make = t
  external unsafeFromJs: Js.t<'a> => t = "%identity"
}

module MacroTimeBucket = {
  type t = [
    | #MACRO_TIME_BUCKET_5M
    | #MACRO_TIME_BUCKET_15M
    | #MACRO_TIME_BUCKET_30M
    | #MACRO_TIME_BUCKET_1H
  ]

  let toDisplay = t =>
    switch t {
    | #MACRO_TIME_BUCKET_5M => "5m"
    | #MACRO_TIME_BUCKET_15M => "15m"
    | #MACRO_TIME_BUCKET_30M => "30m"
    | #MACRO_TIME_BUCKET_1H => "1h"
    }
}

module MacroTimeWindow = {
  type t = [
    | #MACRO_TIME_WINDOW_10M
    | #MACRO_TIME_WINDOW_30M
    | #MACRO_TIME_WINDOW_1H
    | #MACRO_TIME_WINDOW_12H
    | #MACRO_TIME_WINDOW_24H
  ]

  let toDisplay = t =>
    switch t {
    | #MACRO_TIME_WINDOW_10M => "10m"
    | #MACRO_TIME_WINDOW_30M => "30m"
    | #MACRO_TIME_WINDOW_1H => "1h"
    | #MACRO_TIME_WINDOW_12H => "12h"
    | #MACRO_TIME_WINDOW_24H => "24h"
    }
}
