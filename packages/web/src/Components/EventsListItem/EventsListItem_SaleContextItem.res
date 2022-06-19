@react.component
let make = (
  ~alertRule: EventsListItem_GraphQL.EventsListItem_EventFilters_AlertRulePartial.t,
  ~context: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_context_AlertRuleSatisfiedEvent_SaleContext,
  ~now,
  ~style,
  ~onAssetMediaClick,
) =>
  switch context {
  | {
      openSeaEvent: {
        id,
        asset: Some({collection: Some({slug} as collection)} as asset),
        paymentToken,
        totalPrice: Some(totalPrice),
        createdDate,
      },
    } =>
    <li
      style={style}
      className={Cn.make(["list-none", "flex", "flex-row", "pb-4", "px-4", "cursor-pointer"])}
      onClick={_ => Externals.Webapi.Window.open_(asset.permalink)}>
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
        eventLabel="sale"
        assetName={asset.name}
        assetTokenId={asset.tokenId}
        collectionSlug={collection.slug}
        collectionName={collection.name}
        createdAt={
          let ts = (createdDate ++ "Z")->Js.Date.fromString->Js.Date.valueOf
          Some(Js.Math.floor_float(ts /. 1000.0))
        }
        price={totalPrice}
        paymentTokenImageUrl={paymentToken
        ->Belt.Option.flatMap(p => p.imageUrl)
        ->Belt.Option.getWithDefault(
          Services.PaymentToken.ethPaymentToken.imageUrl->Belt.Option.getExn,
        )}
        paymentTokenDecimals={paymentToken
        ->Belt.Option.map(p => p.decimals)
        ->Belt.Option.getWithDefault(Services.PaymentToken.ethPaymentToken.decimals)}
        openSeaAssetAttributes={asset.eventsListItem_Attributes_OpenSeaAsset}
        openSeaAssetRarityRank={asset.eventsListItem_RarityRank_OpenSeaAsset}
        alertRule={alertRule}
        action={React.null}
      />
    </li>
  | _ => React.null
  }
