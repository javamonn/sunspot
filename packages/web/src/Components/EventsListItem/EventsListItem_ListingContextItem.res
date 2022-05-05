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
    let relativeListingTime =
      createdTime
      ->Js.Json.decodeNumber
      ->Belt.Option.map(createdTime => {
        let formatted = Externals.DateFns.formatDistanceStrict(
          createdTime *. 1000.0,
          now,
          Externals.DateFns.formatDistanceStrictOptions(),
        )

        let replaced =
          formatted
          ->Js.String2.replace(" seconds", "s")
          ->Js.String2.replace(" minutes", "m")
          ->Js.String2.replace(" hours", "h")
          ->Js.String2.replace(" months", "mo")
          ->Js.String2.replace(" years", "y")

        replaced
      })
      ->Belt.Option.getWithDefault("now")

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
      <div
        className={Cn.make([
          "px-3",
          "border-t",
          "border-b",
          "border-r",
          "border-solid",
          "border-darkBorder",
          "rounded",
          "py-3",
          "flex-1",
          "grid",
          "xs:flex",
        ])}
        style={ReactDOM.Style.make(~gridTemplateColumns="1fr 2fr", ())}>
        <div className={Cn.make(["flex", "flex-col", "justify-between", "flex-1"])}>
          <div className={Cn.make(["flex", "flex-col"])}>
            <h2
              className={Cn.make([
                "text-darkPrimary",
                "text-lg",
                "whitespace-nowrap",
                "overflow-x-hidden",
                "truncate",
                "xs:hidden",
              ])}>
              {React.string("listing: ")}
              {asset.name->Belt.Option.getWithDefault(`#${asset.tokenId}`)->React.string}
            </h2>
            <div className={Cn.make(["hidden", "xs:flex", "flex-row", "justify-between", "mb-2"])}>
              <h3
                className={Cn.make([
                  "text-darkSecondary",
                  "text-xs",
                  "leading-none",
                  "whitespace-pre",
                ])}>
                {React.string(`listing`)}
              </h3>
              <span className={Cn.make(["text-darkSecondary", "text-xs", "leading-none"])}>
                {React.string(relativeListingTime)}
              </span>
            </div>
            <h2
              className={Cn.make([
                "text-darkPrimary",
                "text-base",
                "hidden",
                "xs:block",
                "leading-none",
                "mb-1",
              ])}>
              {asset.name->Belt.Option.getWithDefault(`#${asset.tokenId}`)->React.string}
            </h2>
            <div
              className={Cn.make([
                "flex-row",
                "flex",
                "leading-none",
                "flex-shrink-0",
                "whitespace-nowrap",
              ])}>
              <span
                className={Cn.make([
                  "text-darkSecondary",
                  "whitespace-pre",
                  "text-base",
                  "xs:hidden",
                ])}>
                {React.string(`${relativeListingTime} • `)}
              </span>
              <h3 className={Cn.make(["text-darkSecondary", "text-base", "xs:hidden"])}>
                {collection.name->Belt.Option.getWithDefault(collection.slug)->React.string}
              </h3>
            </div>
          </div>
          <div className={Cn.make(["flex", "flex-row", "space-x-4"])}>
            <MaterialUi.Button
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
            </MaterialUi.Button>
            <h1
              className={Cn.make(["text-darkPrimary", "text-xl", "font-bold", "leading-none"])}
              style={ReactDOM.Style.make(~position="relative", ~top="1px", ())}>
              <img
                src={paymentTokenContract.imageUrl}
                className={Cn.make(["mb-1", "mr-1", "inline"])}
                style={ReactDOM.Style.make(~height="18px", ())}
              />
              {currentPrice
              ->Externals.Ethers.Utils.parseUnitsWithDecimals(0)
              ->Externals.Ethers.Utils.formatUnitsWithDecimals(paymentTokenContract.decimals)
              ->React.string}
            </h1>
          </div>
        </div>
        <div className={Cn.make(["flex", "flex-col", "overflow-x-hidden", "md:hidden"])}>
          <EventsListItem_Attributes openSeaAsset={asset.eventsListItem_Attributes_OpenSeaAsset} />
          <EventsListItem_EventFilters alertRule={alertRule} />
        </div>
      </div>
    </li>
  | _ => React.null
  }
