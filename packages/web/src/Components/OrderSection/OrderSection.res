type executionState =
  | Buy
  | AuthenticationPending
  | WalletConfirmPending
  | TransactionCreated({transactionHash: string})
  | TransactionConfirmed({transactionHash: string})
  | TransactionFailed({transactionHash: string})
  | InvalidOrder(option<string>)

module AssetMetadata = {
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
        Externals.DateFns.formatDistance(
          createdTime *. 1000.0,
          now,
          Externals.DateFns.formatDistanceOptions(~includeSeconds=true, ~addSuffix=true, ()),
        ),
        None,
      )),
      openSeaOrderFragment.expirationTime
      ->Js.Json.decodeNumber
      ->Belt.Option.map(expirationTime => (
        "expiration time",
        Externals.DateFns.formatDistance(
          expirationTime *. 1000.0,
          now,
          Externals.DateFns.formatDistanceOptions(~includeSeconds=true, ~addSuffix=true, ()),
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

    <div className={Cn.make(["grid-cols-2", "grid", "gap-2"])}>
      {items
      ->Belt.Array.map(((label, value, href)) => {
        let text =
          <MaterialUi.ListItemText primary={React.string(label)} secondary={React.string(value)} />

        switch href {
        | None =>
          <MaterialUi.ListItem
            classes={MaterialUi.ListItem.Classes.make(
              ~root=Cn.make(["bg-gray-100", "rounded"]),
              (),
            )}>
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
}

module HeaderButton = {
  @react.component
  let make = (~onClickBuy, ~executionState) =>
    switch executionState {
    | Buy =>
      <MaterialUi.Button
        onClick={_ => onClickBuy()}
        color=#Primary
        variant=#Contained
        fullWidth={true}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "font-bold", "py-4", "text-base"]),
          (),
        )}>
        {React.string("buy")}
      </MaterialUi.Button>
    | AuthenticationPending =>
      <MaterialUi.Button
        color=#Primary
        variant=#Contained
        size=#Large
        fullWidth={true}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "font-bold", "py-4", "text-base"]),
          (),
        )}>
        {React.string("connecting...")}
      </MaterialUi.Button>
    | WalletConfirmPending =>
      <MaterialUi.Button
        color=#Primary
        variant=#Contained
        fullWidth={true}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "py-4"]),
          ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
          (),
        )}>
        {React.string("wallet confirm pending...")}
      </MaterialUi.Button>
    | TransactionCreated({transactionHash}) =>
      <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
        <MaterialUi.Button
          color=#Primary
          variant=#Contained
          fullWidth={true}
          classes={MaterialUi.Button.Classes.make(
            ~root=Cn.make(["flex-2", "lowercase", "py-4"]),
            ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
            (),
          )}>
          {React.string("tx pending...")}
        </MaterialUi.Button>
      </a>
    | TransactionConfirmed({transactionHash}) =>
      <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
        <MaterialUi.Button
          fullWidth={true}
          variant=#Contained
          color=#Inherit
          startIcon={<Externals_MaterialUi_Icons.CheckCircleOutline />}
          classes={MaterialUi.Button.Classes.make(
            ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-green-600"]),
            ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
            (),
          )}>
          <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
            {React.string("tx confirmed")}
          </span>
        </MaterialUi.Button>
      </a>
    | TransactionFailed({transactionHash}) =>
      <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
        <MaterialUi.Button
          fullWidth={true}
          variant=#Contained
          startIcon={<Externals_MaterialUi_Icons.Error />}
          classes={MaterialUi.Button.Classes.make(
            ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-red-600"]),
            ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
            (),
          )}>
          <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
            {React.string("tx failed")}
          </span>
        </MaterialUi.Button>
      </a>
    | InvalidOrder(reason) =>
      <MaterialUi.Button
        fullWidth={true}
        variant=#Contained
        startIcon={<Externals_MaterialUi_Icons.Error />}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-red-600"]),
          ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
          (),
        )}>
        <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
          {reason->Belt.Option.getWithDefault("invalid order")->React.string}
        </span>
      </MaterialUi.Button>
    }
}

module Header = {
  @react.component
  let make = (
    ~onClickBuy,
    ~executionState,
    ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
  ) =>
    <div
      className={Cn.make([
        "border",
        "border-solid",
        "border-darkDisabled",
        "rounded",
        "p-6",
        "mb-8",
        "flex",
        "flex-row",
      ])}>
      <div className={Cn.make(["flex", "flex-row", "justify-space", "flex-1", "leading-none"])}>
        <div className={Cn.make(["flex", "items-center", "justify-center", "mr-1"])}>
          <img
            style={ReactDOM.Style.make(~marginTop="6px", ~opacity="60%", ())}
            src={openSeaOrderFragment.paymentTokenContract.imageUrl}
            className={Cn.make(["h-5", "mr-1"])}
          />
        </div>
        <div className={Cn.make(["flex", "justify-center", "items-center"])}>
          <div className={Cn.make(["flex", "flex-row", "items-end"])}>
            <span className={Cn.make(["font-bold", "text-4xl", "block", "mr-2", "leading-none"])}>
              {openSeaOrderFragment.basePrice
              ->Services.PaymentToken.parseTokenPrice(
                Services.PaymentToken.ethPaymentToken.decimals,
              )
              ->Belt.Option.map(Belt.Float.toString)
              ->Belt.Option.getWithDefault("N/A")
              ->React.string}
            </span>
            {openSeaOrderFragment.basePrice
            ->Services.PaymentToken.parseUsdPrice(
              ~paymentToken={
                ...Services.PaymentToken.ethPaymentToken,
                usdPrice: Some(openSeaOrderFragment.paymentTokenContract.usdPrice),
              },
            )
            ->Belt.Option.map(parsedUsdPrice =>
              <span
                className={Cn.make(["text-darkSecondary", "leading-none", "block"])}
                style={ReactDOM.Style.make(~position="relative", ~bottom="4px", ())}>
                {React.string(`(${Services.PaymentToken.formatUsdPrice(parsedUsdPrice)})`)}
              </span>
            )
            ->Belt.Option.getWithDefault(React.null)}
          </div>
        </div>
      </div>
      <div className={Cn.make(["flex-1"])}>
        <HeaderButton executionState={executionState} onClickBuy={onClickBuy} />
      </div>
    </div>
}

module AssetDetail = {
  type activeState = {
    asset: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaAsset.t,
    metadata: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrderMetadataAsset.t,
  }

  @react.component
  let make = (
    ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
  ) => {
    let handleClick = destination => {
      Services.Logger.logWithData(
        "buy",
        "asset click",
        [("destination", Js.Json.string(destination))]->Js.Dict.fromArray->Js.Json.object_,
      )
    }

    let ({asset: {collection} as asset, metadata}, _setActive) = React.useState(() => {
      let result = switch openSeaOrderFragment {
      | {asset: Some(asset), metadata: {asset: Some(assetMetadata)}} =>
        Some({
          asset: asset,
          metadata: assetMetadata,
        })
      | {assetBundle: Some({assets}), metadata: {bundle: Some({assets: assetMetadatas})}} =>
        switch (assets->Belt.Array.get(0), assetMetadatas->Belt.Array.get(0)) {
        | (Some(asset), Some(assetMetadata)) =>
          Some({
            asset: asset,
            metadata: assetMetadata,
          })
        | _ => None
        }
      | _ => None
      }

      result->Belt.Option.getExn
    })

    let media = switch asset {
    | {animationUrl: Some(animationUrl)} =>
      <video
        controls={true}
        muted={true}
        autoPlay={true}
        className={Cn.make(["rounded"])}
        src={Services.Ipfs.isIpfsUri(animationUrl)
          ? `https://ipfs.io${Services.Ipfs.getNormalizedCidPath(animationUrl)}`
          : animationUrl}
      />
    | _ =>
      let assetImageUrl = Services.URL.assetImageUrl(
        ~contractAddress=metadata.address,
        ~tokenId=metadata.id,
        ~cacheId=openSeaOrderFragment.id
        ->Js.Json.decodeNumber
        ->Belt.Option.getWithDefault(-1.0)
        ->Belt.Float.toString,
        (),
      )
      <img className={Cn.make(["rounded"])} src={assetImageUrl} />
    }

    <>
      <div className={Cn.make(["flex", "flex-col"])}>
        <div className={Cn.make(["flex", "flex-row", "space-x-4", "mb-8"])}>
          <div className={Cn.make(["flex-1"])}> {media} </div>
          <div className={Cn.make(["flex-1", "justify-end", "flex", "flex-col"])}>
            <a href={asset.permalink} onClick={_ => handleClick("asset")} target="_blank">
              <MaterialUi.Button
                variant=#Text
                size=#Small
                classes={MaterialUi.Button.Classes.make(~root=Cn.make(["normal-case"]), ())}>
                <h1
                  className={Cn.make([
                    "font-bold",
                    "font-mono",
                    "text-4xl",
                    "text-darkPrimary",
                    "leading-none",
                  ])}>
                  {React.string(asset.name)}
                </h1>
              </MaterialUi.Button>
            </a>
            {collection
            ->Belt.Option.map(collection =>
              <a
                href={Services.URL.collectionUrl(collection.slug)}
                onClick={_ => handleClick("collection")}
                target="_blank">
                <MaterialUi.Button
                  variant=#Text
                  size=#Small
                  classes={MaterialUi.Button.Classes.make(
                    ~root=Cn.make(["normal-case", "mt-2"]),
                    (),
                  )}>
                  <div className={Cn.make(["flex-row", "flex"])}>
                    {collection.imageUrl
                    ->Belt.Option.map(imageUrl =>
                      <MaterialUi.Avatar
                        classes={MaterialUi.Avatar.Classes.make(~root=Cn.make(["w-8", "h-8"]), ())}>
                        <img src={imageUrl} />
                      </MaterialUi.Avatar>
                    )
                    ->Belt.Option.getWithDefault(React.null)}
                    <h2 className={Cn.make(["font-mono", "text-xl", "text-darkSecondary", "ml-2"])}>
                      {collection.name->Belt.Option.getWithDefault(collection.slug)->React.string}
                    </h2>
                  </div>
                </MaterialUi.Button>
              </a>
            )
            ->Belt.Option.getWithDefault(React.null)}
          </div>
        </div>
      </div>
      {asset.attributes
      ->Belt.Option.map(attributes =>
        <div className={Cn.make(["grid-cols-4", "grid", "gap-2", "mb-8"])}>
          {attributes
          ->Belt.Array.keepMap(attribute =>
            switch attribute {
            | #OpenSeaAssetNumberAttribute({traitType, numberValue}) =>
              Some(
                Services.OpenSea.NumberTrait({
                  name: traitType,
                  value: numberValue,
                }),
              )
            | #OpenSeaAssetStringAttribute({traitType, stringValue}) =>
              Some(
                Services.OpenSea.StringTrait({
                  name: traitType,
                  value: stringValue,
                }),
              )
            | #FutureAddedValue(_) => None
            }
          )
          ->Belt.Array.map(trait => {
            let traitUrl = Services.OpenSea.makeAssetsUrl(
              ~collectionSlug=asset.collectionSlug,
              ~traitsFilter=[trait],
              ~eventType=#LISTING,
              ~sortBy=#PRICE,
              ~sortAscending=true,
              (),
            )

            <a href={traitUrl} target="_blank" className={Cn.make(["flex"])}>
              <MaterialUi.Button
                fullWidth={true}
                size=#Small
                variant=#Outlined
                classes={MaterialUi.Button.Classes.make(
                  ~label=Cn.make(["flex", "flex-col", "p-2"]),
                  (),
                )}>
                <span
                  className={Cn.make([
                    "text-darkSecondary",
                    "lowercase",
                    "font-semibold",
                    "text-center",
                    "text-sm",
                    "leading-none",
                    "mb-1",
                  ])}>
                  {switch trait {
                  | StringTrait({name}) | NumberTrait({name}) => React.string(name)
                  }}
                </span>
                <span
                  className={Cn.make([
                    "text-darkPrimary",
                    "font-bold",
                    "text-center",
                    "text-sm",
                    "normal-case",
                    "leading-none",
                  ])}>
                  {switch trait {
                  | StringTrait({value}) => React.string(value)
                  | NumberTrait({value}) => value->Belt.Float.toString->React.string
                  }}
                </span>
              </MaterialUi.Button>
            </a>
          })
          ->React.array}
        </div>
      )
      ->Belt.Option.getWithDefault(React.null)}
      <AssetMetadata openSeaOrderFragment={openSeaOrderFragment} asset={asset} />
    </>
  }
}

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
) => {
  <section className={Cn.make(["py-4", "flex", "flex-col"])}>
    <Header
      onClickBuy={onClickBuy}
      executionState={executionState}
      openSeaOrderFragment={openSeaOrderFragment}
    />
    <AssetDetail openSeaOrderFragment={openSeaOrderFragment} />
  </section>
}
