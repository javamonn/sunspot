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
    let uris =
      [asset.imageUrl, asset.imagePreviewUrl, asset.imageThumbnailUrl]->Belt.Array.keepMap(i => i)
    let fallbackUri = uris->Belt.Array.getBy(candidate => candidate !== uri)

    Js.log(uris)

    let imageSrc = Services.URL.resolveMedia(~uri, ~fallbackUri?, ())
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
    <OrderSection_AssetMetadata openSeaOrderFragment={openSeaOrderFragment} asset={asset} />
    {asset.collection
    ->Belt.Option.map(collection => <OrderSection_CollectionStatistics collection={collection} />)
    ->Belt.Option.getWithDefault(React.null)}
  </>
}
