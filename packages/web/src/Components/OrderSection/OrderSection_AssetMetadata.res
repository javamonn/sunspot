module Fragment_OrderSection_AssetMetadata_OpenSeaOrder = %graphql(`
  fragment OrderSection_AssetMetadata_OpenSeaOrder on OpenSeaOrder {
    createdTime
    expirationTime

    asset {
      tokenId
      tokenMetadata
      collection {
        contractAddress
      }
    }
  }
`)

@react.component
let make = (~openSeaOrder: Fragment_OrderSection_AssetMetadata_OpenSeaOrder.t) => {
  let (now, setNow) = React.useState(_ => Js.Date.now())
  let _ = React.useEffect(_ => {
    let intervalId = Js.Global.setInterval(() => {
      setNow(_ => Js.Date.now())
    }, 1000)

    Some(
      () => {
        Js.Global.clearInterval(intervalId)
      },
    )
  })
  let handleClick = label => {
    Services.Logger.logWithData(
      "buy",
      "metadata click",
      [("label", Js.Json.string(label))]->Js.Dict.fromArray->Js.Json.object_,
    )
  }

  let {expirationTime, createdTime, asset} = openSeaOrder
  let {tokenId, tokenMetadata, collection} = Belt.Option.getExn(asset)
  let {contractAddress} = Belt.Option.getExn(collection)

  let items = [
    createdTime
    ->Js.Json.decodeNumber
    ->Belt.Option.map(createdTime => (
      "listing time",
      Externals.DateFns.formatDistanceStrict(
        createdTime *. 1000.0,
        now,
        Externals.DateFns.formatDistanceStrictOptions(~addSuffix=true, ()),
      ),
      None,
    )),
    expirationTime
    ->Js.Json.decodeNumber
    ->Belt.Option.map(expirationTime => (
      "expiration time",
      Externals.DateFns.formatDistanceStrict(
        expirationTime *. 1000.0,
        now,
        Externals.DateFns.formatDistanceStrictOptions(~addSuffix=true, ()),
      ),
      None,
    )),
    Some((
      "contract address",
      Services.Format.address(contractAddress),
      Some(Services.URL.etherscanAddress(contractAddress)),
    )),
    Some((
      "token id",
      tokenId,
      tokenMetadata->Belt.Option.map(tokenMetadata => {
        Services.Ipfs.isIpfsUri(tokenMetadata)
          ? `https://ipfs.io${Services.Ipfs.getNormalizedCidPath(tokenMetadata)}`
          : tokenMetadata
      }),
    )),
  ]->Belt.Array.keepMap(i => i)

  <div className={Cn.make(["grid-cols-2", "grid", "gap-2", "sm:grid-cols-1"])}>
    {items
    ->Belt.Array.map(((label, value, href)) => {
      let text =
        <MaterialUi.ListItemText primary={React.string(label)} secondary={React.string(value)} />

      switch href {
      | None =>
        <MaterialUi.ListItem
          classes={MaterialUi.ListItem.Classes.make(~root=Cn.make(["bg-gray-100", "rounded"]), ())}>
          {text}
        </MaterialUi.ListItem>
      | Some(href) =>
        <a onClick={_ => handleClick(label)} href={href} target="_blank">
          <MaterialUi.ListItem
            button={true}
            classes={MaterialUi.ListItem.Classes.make(
              ~root=Cn.make(["bg-gray-100", "rounded"]),
              (),
            )}>
            {text}
          </MaterialUi.ListItem>
        </a>
      }
    })
    ->React.array}
  </div>
}
