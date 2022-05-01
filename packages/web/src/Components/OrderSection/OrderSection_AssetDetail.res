exception InvalidOrder

module OrderSection_AssetMetadata_OpenSeaOrder = OrderSection_AssetMetadata.Fragment_OrderSection_AssetMetadata_OpenSeaOrder
module OpenSeaAssetMedia_OpenSeaAsset = OpenSeaAssetMedia.Fragment_OpenSeaAssetMedia_OpenSeaAsset

module Fragment_OrderSection_AssetDetail_OpenSeaOrder = %graphql(`
  fragment OrderSection_AssetDetail_OpenSeaOrder on OpenSeaOrder {
    asset {
      name
      tokenId
      collectionSlug
      permalink
      collection {
        slug
        imageUrl
        name
      }
      attributes {
        ... on OpenSeaAssetNumberAttribute {
          traitType
          displayType
          numberValue: value
          maxValue
        }
        ... on OpenSeaAssetStringAttribute {
          traitType
          displayType
          stringValue: value
          maxValue
        }
      }
      ...OpenSeaAssetMedia_OpenSeaAsset
    }
    ...OrderSection_AssetMetadata_OpenSeaOrder
  }
`)

@react.component
let make = (~openSeaOrder: Fragment_OrderSection_AssetDetail_OpenSeaOrder.t) => {
  let (lightboxSrc, setLightboxSrc) = React.useState(_ => None)
  let handleClick = destination => {
    Services.Logger.logWithData(
      "buy",
      "asset click",
      [("destination", Js.Json.string(destination))]->Js.Dict.fromArray->Js.Json.object_,
    )
  }

  let (asset, collection, openSeaAssetMedia_OpenSeaAsset) = switch openSeaOrder {
  | {asset: Some({openSeaAssetMedia_OpenSeaAsset, collection: Some(collection)} as asset)} => (
      asset,
      collection,
      openSeaAssetMedia_OpenSeaAsset,
    )
  | _ => raise(InvalidOrder)
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
        <div className={Cn.make(["flex-1", "sm:order-last", "sm:mt-4"])}>
          <OpenSeaAssetMedia
            openSeaAsset={openSeaAssetMedia_OpenSeaAsset}
            onClick={src => setLightboxSrc(_ => Some(src))}
          />
          {switch lightboxSrc {
          | Some(src) =>
            <Externals.ReactImageLightbox
              mainSrc={src}
              onCloseRequest={() => setLightboxSrc(_ => None)}
              imagePadding={30}
              reactModalStyle={{
                "overlay": {
                  "zIndex": "1500",
                },
              }}
            />
          | None => React.null
          }}
        </div>
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
          <a
            href={Services.URL.collectionUrl(collection.slug)}
            onClick={_ => handleClick("collection")}
            target="_blank">
            <MaterialUi.Button
              variant=#Text
              classes={MaterialUi.Button.Classes.make(~root=Cn.make(["normal-case", "mt-2"]), ())}>
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
    <OrderSection_AssetMetadata
      openSeaOrder={openSeaOrder.orderSection_AssetMetadata_OpenSeaOrder}
    />
    <OrderSection_CollectionStatistics collectionSlug={collection.slug} />
  </>
}
