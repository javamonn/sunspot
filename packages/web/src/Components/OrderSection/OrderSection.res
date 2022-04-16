%raw(`require('react-image-lightbox/style.css')`)
type executionState =
  | Buy
  | ClientPending 
  | WalletConfirmPending
  | TransactionCreated({transactionHash: string})
  | TransactionConfirmed({transactionHash: string})
  | TransactionFailed({transactionHash: string})
  | InvalidOrder(option<string>)

let eventsScatterplotHours = 4.0

module CollectionStatistics = {
  @react.component
  let make = (
    ~collection: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaAsset.t_collection,
  ) => {
    let (isLightboxOpen, setIsLightboxOpen) = React.useState(_ => false)
    let eventsScatterplotSrc = {
      let endCreatedAtMinuteTime =
        Js.Math.floor_float(Js.Math.floor_float(Js.Date.now() /. 1000.0) /. 60.0) *. 60.0
      let startCreatedAtMinuteTime =
        endCreatedAtMinuteTime -. 60.0 *. 60.0 *. eventsScatterplotHours

      let start = startCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
      let end = endCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
      let collectionSlug = collection.slug

      `https://dpldouen3w8e7.cloudfront.net/production/events-scatterplot?collectionSlug=${collectionSlug}&startCreatedAtMinuteTime=${start}&endCreatedAtMinuteTime=${end}`
    }

    <>
      <img
        onClick={_ => {
          setIsLightboxOpen(_ => true)
        }}
        src={eventsScatterplotSrc}
        className={Cn.make([
          "flex-1",
          "border",
          "border-solid",
          "rounded",
          "cursor-pointer",
          "border-darkBorder",
          "mt-8",
        ])}
      />
      {isLightboxOpen
        ? <Externals.ReactImageLightbox
            mainSrc={eventsScatterplotSrc}
            onCloseRequest={() => setIsLightboxOpen(_ => false)}
            imagePadding={30}
            reactModalStyle={{
              "overlay": {
                "zIndex": "1500",
              },
            }}
          />
        : React.null}
    </>
  }
}

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

    <div className={Cn.make(["grid-cols-2", "grid", "gap-2", "sm:grid-cols-1"])}>
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
    | ClientPending =>
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
        <MaterialUi.LinearProgress
          color=#Primary
          classes={MaterialUi.LinearProgress.Classes.make(
            ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
            (),
          )}
          variant=#Indeterminate
        />
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
        <MaterialUi.LinearProgress
          color=#Primary
          classes={MaterialUi.LinearProgress.Classes.make(
            ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
            (),
          )}
          variant=#Indeterminate
        />
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
          <MaterialUi.LinearProgress
            color=#Primary
            classes={MaterialUi.LinearProgress.Classes.make(
              ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
              (),
            )}
            variant=#Indeterminate
          />
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
    ~quickbuy,
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
        "sm:flex-col",
        "sm:p-4",
        "sm:space-y-4",
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
          <div className={Cn.make(["flex", "flex-row", "items-end", "font-mono"])}>
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
        {!quickbuy
          ? <QuickbuyPrompt className={Cn.make(["hidden", "sm:flex", "sm:mt-4"])} />
          : React.null}
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
    let (isLightboxOpen, setIsLightboxOpen) = React.useState(_ => false)
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
    | {imageUrl: Some(uri)}
    | {imagePreviewUrl: Some(uri)}
    | {imageThumbnailUrl: Some(uri)} =>
      let imageSrc = Services.URL.resolveMedia(~uri, ())
      <>
        <img
          className={Cn.make(["rounded", "cursor-pointer"])}
          src={imageSrc}
          onClick={_ => {
            setIsLightboxOpen(_ => true)
          }}
        />
        {isLightboxOpen
          ? <Externals.ReactImageLightbox
              mainSrc={imageSrc}
              onCloseRequest={() => setIsLightboxOpen(_ => false)}
              imagePadding={30}
              reactModalStyle={{
                "overlay": {
                  "zIndex": "1500",
                },
              }}
            />
          : React.null}
      </>
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
    | _ => <div className={Cn.make(["rounded", "bg-gray-100"])} />
    }

    <>
      <div className={Cn.make(["flex", "flex-col"])}>
        <div
          className={Cn.make([
            "flex",
            "flex-row",
            "space-x-4",
            "mb-8",
            "sm:flex-col",
            "sm:space-x-0",
          ])}>
          <div className={Cn.make(["flex-1", "sm:order-last", "sm:mt-4"])}> {media} </div>
          <div className={Cn.make(["flex-1", "justify-end", "flex", "flex-col"])}>
            <a href={asset.permalink} onClick={_ => handleClick("asset")} target="_blank">
              <MaterialUi.Button
                variant=#Text
                classes={MaterialUi.Button.Classes.make(
                  ~root=Cn.make(["normal-case"]),
                  ~label=Cn.make(["flex", "flex-row", "items-center"]),
                  (),
                )}>
                <h1
                  className={Cn.make([
                    "font-bold",
                    "font-mono",
                    "text-3xl",
                    "sm:text-lg",
                    "text-darkPrimary",
                    "leading-none",
                    "text-left",
                  ])}>
                  {asset.name->Belt.Option.getWithDefault(`#${asset.tokenId}`)->React.string}
                </h1>
                <Externals.MaterialUi_Icons.OpenInNew
                  className={Cn.make(["opacity-50", "w-4", "h-4", "ml-2"])}
                />
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
                  classes={MaterialUi.Button.Classes.make(
                    ~root=Cn.make(["normal-case", "mt-2"]),
                    (),
                  )}>
                  <div className={Cn.make(["flex-row", "flex", "items-center"])}>
                    {collection.imageUrl
                    ->Belt.Option.map(imageUrl =>
                      <MaterialUi.Avatar
                        classes={MaterialUi.Avatar.Classes.make(
                          ~root=Cn.make(["w-8", "h-8", "sm:w-6", "sm:h-6"]),
                          (),
                        )}>
                        <img src={imageUrl} />
                      </MaterialUi.Avatar>
                    )
                    ->Belt.Option.getWithDefault(React.null)}
                    <h2
                      className={Cn.make([
                        "font-mono",
                        "text-lg",
                        "text-darkSecondary",
                        "ml-2",
                        "leading-none",
                        "text-left",
                        "sm:text-base",
                      ])}>
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
        <div className={Cn.make(["grid-cols-4", "grid", "gap-2", "mb-8", "sm:grid-cols-2"])}>
          {attributes
          ->Belt.Array.keepMap(attribute =>
            switch attribute {
            | #OpenSeaAssetNumberAttribute({traitType, numberValue}) =>
              Some(
                Services.OpenSea.URL.NumberTrait({
                  name: traitType,
                  value: numberValue,
                }),
              )
            | #OpenSeaAssetStringAttribute({traitType, stringValue})
              if Js.String2.length(stringValue) > 0 =>
              Some(
                Services.OpenSea.URL.StringTrait({
                  name: traitType,
                  value: stringValue,
                }),
              )
            | #FutureAddedValue(_) | _ => None
            }
          )
          ->Belt.Array.map(trait => {
            let traitUrl = Services.OpenSea.URL.makeAssetsUrl(
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
      {asset.collection
      ->Belt.Option.map(collection => <CollectionStatistics collection={collection} />)
      ->Belt.Option.getWithDefault(React.null)}
    </>
  }
}

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
  ~quickbuy,
) => {
  <>
    <Header
      onClickBuy={onClickBuy}
      executionState={executionState}
      openSeaOrderFragment={openSeaOrderFragment}
      quickbuy={quickbuy}
    />
    <AssetDetail openSeaOrderFragment={openSeaOrderFragment} />
  </>
}
