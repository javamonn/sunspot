module Fragment_OrderSection_AssetMetadata_OpenSeaEvent = %graphql(`
  fragment OrderSection_AssetMetadata_OpenSeaEvent on OpenSeaEvent {
    createdDate

    asset {
      id
      tokenId
      tokenMetadata
      collection {
        slug
        contractAddress
      }
    }
  }
`)

@react.component
let make = (~openSeaEvent: Fragment_OrderSection_AssetMetadata_OpenSeaEvent.t) => {
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

  let {createdDate, asset} = openSeaEvent
  let {tokenId, tokenMetadata, collection} = Belt.Option.getExn(asset)
  let {contractAddress} = Belt.Option.getExn(collection)

  let items = [
    (
      "listing time",
      Externals.DateFns.formatDistanceStrict(
        (createdDate ++ "Z")->Js.Date.fromString->Js.Date.valueOf,
        now,
        Externals.DateFns.formatDistanceStrictOptions(~addSuffix=true, ()),
      ),
      None,
    ),
    (
      "contract address",
      Services.Format.address(contractAddress),
      Some(Services.URL.etherscanAddress(contractAddress)),
    ),
    (
      "token id",
      tokenId,
      tokenMetadata->Belt.Option.map(tokenMetadata => {
        Services.Ipfs.isIpfsUri(tokenMetadata)
          ? `https://ipfs.io${Services.Ipfs.getNormalizedCidPath(tokenMetadata)}`
          : tokenMetadata
      }),
    ),
  ]

  <>
    <h1 className={Cn.make(["text-darkSecondary", "font-mono", "mb-2", "text-sm"])}>
      <Externals.MaterialUi_Icons.AssessmentOutlined
        style={ReactDOM.Style.make(~opacity="0.50", ~height="18px", ())}
      />
      {React.string("metadata")}
    </h1>
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
  </>
}
