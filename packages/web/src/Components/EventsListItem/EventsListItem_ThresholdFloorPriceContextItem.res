@react.component
let make = (
  ~alertRule: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_alertRule,
  ~context: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_context_AlertRuleSatisfiedEvent_ThresholdFloorPriceContext,
  ~createdAt,
  ~now,
  ~style,
  ~onAssetMediaClick,
) => {
  let relativeTime =
    createdAt
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

  let collectionName = context.collection.name->Belt.Option.getWithDefault(context.collection.slug)
  let eventsScatterplotSrc = {
    let collectionSlug = context.collection.slug
    let endCreatedAtMinuteTime =
      Js.Math.floor_float(Js.Math.floor_float(Js.Date.now() /. 1000.0) /. 60.0) *. 60.0
    let startCreatedAtMinuteTime = endCreatedAtMinuteTime -. 60.0 *. 60.0 *. 4.0
    let start = startCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
    let end = endCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString

    `https://dpldouen3w8e7.cloudfront.net/production/events-scatterplot?collectionSlug=${collectionSlug}&startCreatedAtMinuteTime=${start}&endCreatedAtMinuteTime=${end}`
  }

  let collectionFloorPrice =
    context.collectionFloorPrice->Belt.Option.map(collectionFloorPrice =>
      collectionFloorPrice
      ->Externals.Ethers.Utils.parseUnitsWithDecimals(0)
      ->Externals.Ethers.Utils.formatUnitsWithDecimals(context.paymentToken.decimals)
    )

  let threshold =
    alertRule.eventsListItem_EventFilters_AlertRulePartial.eventFilters
    ->Belt.Array.get(0)
    ->Belt.Option.flatMap(f =>
      switch f {
      | #AlertPriceThresholdEventFilter({direction, stringValue: Some(value), paymentToken})
      | #AlertPriceThresholdEventFilter({direction, stringValueAlias: Some(value), paymentToken}) =>
        let thresholdDirectionVerb = switch direction {
        | #ALERT_ABOVE => "above"
        | #ALERT_BELOW => "below"
        | _ => "equal"
        }
        let thresholdPrice =
          Services.PaymentToken.parseTokenPrice(value, paymentToken.decimals)
          ->Belt.Option.map(Belt.Float.toString)
          ->Belt.Option.getExn

        Some((thresholdDirectionVerb, thresholdPrice))
      | _ => None
      }
    )

  switch (collectionFloorPrice, threshold) {
  | (Some(collectionFloorPrice), Some((thresholdDirectionVerb, thresholdFloorPrice))) =>
    let title = `floor price ${thresholdDirectionVerb} threshold: ${collectionName} floor is ${collectionFloorPrice}`
    let subtitle = `target floor price: ${thresholdDirectionVerb} Ξ${thresholdFloorPrice}`

    <li
      style={style}
      className={Cn.make(["list-none", "flex", "flex-row", "pb-4", "px-4", "cursor-pointer"])}
      onClick={_ =>
        context.collection.slug->Services.URL.collectionUrl->Externals.Webapi.Window.open_}>
      <div
        className={Cn.make([
          "flex",
          "flex-row",
          "border",
          "border-solid",
          "border-darkBorder",
          "rounded",
          "flex-1",
          "overflow-hidden",
        ])}>
        <img
          src={eventsScatterplotSrc}
          onClick={ev => {
            let _ = ev->ReactEvent.Mouse.stopPropagation
            onAssetMediaClick(eventsScatterplotSrc)
          }}
          className={Cn.make([
            "h-32",
            "w-32",
            "rounded-r-none",
            "flex-shrink-0",
            "xs:h-24",
            "xs:w-24",
          ])}
        />
        <div className={Cn.make(["flex-col", "flex", "flex-1", "p-3", "xs:flex-row"])}>
          <h2 className={Cn.make(["text-darkPrimary", "text-lg", "md:text-base", "xs:hidden"])}>
            {React.string(title)}
          </h2>
          <h2
            className={Cn.make(["text-darkPrimary", "hidden", "text-xs", "xs:flex", "xs:flex-1"])}>
            {React.string(title)}
          </h2>
          <h3 className={Cn.make(["text-darkSecondary", "text-base", "xs:hidden"])}>
            {React.string(`${relativeTime} • ${subtitle}`)}
          </h3>
          <h3 className={Cn.make(["text-darkSecondary", "hidden", "text-xs", "xs:block"])}>
            {React.string(relativeTime)}
          </h3>
        </div>
      </div>
    </li>
  | _ => React.null
  }
}
