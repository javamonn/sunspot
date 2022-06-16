@react.component
let make = (
  ~alertRule: EventsListItem_GraphQL.EventsListItem_EventFilters_AlertRulePartial.t,
  ~context: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_context_AlertRuleSatisfiedEvent_OpenSeaEventListingContext,
  ~now,
  ~style,
  ~onAssetMediaClick,
  ~onOpenOpenSeaEventDialog,
) =>
  switch context {
  | {
      openSeaEvent: {
        id,
        asset: Some({collection: Some({slug, contractAddress} as collection)} as asset),
        paymentToken,
        startingPrice: Some(startingPrice),
        createdDate,
      },
    } =>
    <li
      style={style}
      className={Cn.make(["list-none", "flex", "flex-row", "pb-4", "px-4", "cursor-pointer"])}
      onClick={_ => onOpenOpenSeaEventDialog(~id, ~contractAddress, ~quickbuy=false)}>
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
        createdAt={
          let ts = (createdDate ++ "Z")->Js.Date.fromString->Js.Date.valueOf
          Some(Js.Math.floor_float(ts /. 1000.0))
        }
        price={startingPrice}
        paymentTokenImageUrl={paymentToken
        ->Belt.Option.flatMap(p => p.imageUrl)
        ->Belt.Option.getWithDefault(
          Services.PaymentToken.ethPaymentToken.imageUrl->Belt.Option.getExn,
        )}
        paymentTokenDecimals={paymentToken
        ->Belt.Option.map(p => p.decimals)
        ->Belt.Option.getWithDefault(Services.PaymentToken.ethPaymentToken.decimals)}
        openSeaAssetAttributes={asset.eventsListItem_Attributes_OpenSeaAsset}
        alertRule={alertRule}
        action={<MaterialUi.Button
          color=#Primary
          variant=#Contained
          size=#Small
          onClick={ev => {
            let _ = ev->ReactEvent.Mouse.stopPropagation
            Externals.Webapi.Window.open_(asset.permalink)
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
