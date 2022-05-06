@react.component
let make = (
  ~alertRule: EventsListItem_GraphQL.EventsListItem_EventFilters_AlertRulePartial.t,
  ~context: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_context_AlertRuleSatisfiedEvent_ListingContext,
  ~now,
  ~style,
  ~onAssetMediaClick,
  ~onBuy,
) =>
  switch context {
  | {
      openSeaOrder: {
        id,
        asset: Some({collection: Some({slug} as collection)} as asset),
        paymentTokenContract,
        currentPrice,
        createdTime,
      },
    } =>
    <li
      style={style}
      className={Cn.make(["list-none", "flex", "flex-row", "pb-4", "px-4", "cursor-pointer"])}
      onClick={_ => onBuy(~orderId=id, ~orderCollectionSlug=slug, ~quickbuy=false)}>
      <OpenSeaAssetMedia
        onClick={onAssetMediaClick}
        openSeaAsset={asset.openSeaAssetMedia_OpenSeaAsset}
        className={Cn.make([
          "h-32",
          "w-32",
          "rounded-r-none",
          "flex-shrink-0",
          "xs:h-24",
          "xs:w-24",
        ])}
      />
      <EventsListItem_AssetEventDetails
        now={now}
        eventLabel="listing"
        assetName={asset.name}
        assetTokenId={asset.tokenId}
        collectionSlug={collection.slug}
        collectionName={collection.name}
        createdAt={createdTime->Js.Json.decodeNumber}
        price={currentPrice}
        paymentTokenImageUrl={paymentTokenContract.imageUrl}
        paymentTokenDecimals={paymentTokenContract.decimals}
        openSeaAssetAttributes={asset.eventsListItem_Attributes_OpenSeaAsset}
        alertRule={alertRule}
        action={<MaterialUi.Button
          color=#Primary
          variant=#Contained
          size=#Small
          onClick={ev => {
            let _ = ev->ReactEvent.Mouse.stopPropagation
            onBuy(~orderId=id, ~orderCollectionSlug=slug, ~quickbuy=true)
          }}
          classes={MaterialUi.Button.Classes.make(
            ~root=Cn.make(["text-base", "text-lightPrimary"]),
            ~label=Cn.make(["lowercase", "py-0", "leading-none", "font-bold"]),
            (),
          )}>
          {React.string("buy")}
        </MaterialUi.Button>}
      />
    </li>
  | _ => React.null
  }
