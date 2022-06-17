let client = ref(None)

let openseaCrossChainConduitKey = "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000"
let openseaCrossChainConduit = "0x1e0049783f008a0085193e00003d00cd54003c71"
let conduitKeyToConduit = Js.Dict.fromArray([
  (openseaCrossChainConduitKey, openseaCrossChainConduit),
])

@decco
type order = {
  @decco.key("protocol_data") protocolData: Js.Json.t,
  @decco.key("current_price") currentPrice: string,
  finalized: bool,
  cancelled: bool,
}

let getClient = provider =>
  switch client.contents {
  | Some(c) => c
  | None =>
    open Externals_Seaport.Client
    let c = make(
      provider,
      makeParams(
        ~conduitKeyToConduit,
        ~overrides=overrides(~defaultConduitKey=openseaCrossChainConduitKey),
      ),
    )
    client.contents = Some(c)
    c
  }
