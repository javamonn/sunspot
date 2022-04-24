@react.component
let make = (
  ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
  ~asset: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaAsset.t,
) => {
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

  let items = [
    openSeaOrderFragment.createdTime
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
    openSeaOrderFragment.expirationTime
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
    asset.collection->Belt.Option.map(collection => (
      "contract address",
      Services.Format.address(collection.contractAddress),
      Some(Services.URL.etherscanAddress(collection.contractAddress)),
    )),
    Some((
      "token id",
      asset.tokenId,
      asset.tokenMetadata->Belt.Option.map(tokenMetadata => {
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
