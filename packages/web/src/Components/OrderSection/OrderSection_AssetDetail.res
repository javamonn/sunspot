exception InvalidOrder

module OrderSection_AssetMetadata_OpenSeaEvent = OrderSection_AssetMetadata.Fragment_OrderSection_AssetMetadata_OpenSeaEvent
module OrderSection_Attributes_OpenSeaAsset = OrderSection_Attributes.Fragment_OrderSection_Attributes_OpenSeaAsset
module OrderSection_RarityRank_OpenSeaAsset = OrderSection_RarityRank.Fragment_OrderSection_RarityRank_OpenSeaAsset
module OpenSeaAssetMedia_OpenSeaAsset = OpenSeaAssetMedia.Fragment_OpenSeaAssetMedia_OpenSeaAsset

module Fragment_OrderSection_AssetDetail_OpenSeaEvent = %graphql(`
  fragment OrderSection_AssetDetail_OpenSeaEvent on OpenSeaEvent {
    asset {
      id
      name
      tokenId
      collectionSlug
      permalink
      collection {
        slug
        imageUrl
        name
      }

      ...OrderSection_RarityRank_OpenSeaAsset
      ...OrderSection_Attributes_OpenSeaAsset
      ...OpenSeaAssetMedia_OpenSeaAsset
    }
    ...OrderSection_AssetMetadata_OpenSeaEvent
  }
`)

@react.component
let make = (~openSeaEvent: Fragment_OrderSection_AssetDetail_OpenSeaEvent.t) => {
  let (lightboxSrc, setLightboxSrc) = React.useState(_ => None)
  let handleClick = destination => {
    Services.Logger.logWithData(
      "buy",
      "asset click",
      [("destination", Js.Json.string(destination))]->Js.Dict.fromArray->Js.Json.object_,
    )
  }

  let (asset, collection, openSeaAssetMedia_OpenSeaAsset) = switch openSeaEvent {
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
    <OrderSection_RarityRank openSeaAsset={asset.orderSection_RarityRank_OpenSeaAsset} />
    <OrderSection_Attributes openSeaAsset={asset.orderSection_Attributes_OpenSeaAsset} />
    <OrderSection_AssetMetadata
      openSeaEvent={openSeaEvent.orderSection_AssetMetadata_OpenSeaEvent}
    />
    <OrderSection_CollectionStatistics collectionSlug={collection.slug} />
  </>
}
