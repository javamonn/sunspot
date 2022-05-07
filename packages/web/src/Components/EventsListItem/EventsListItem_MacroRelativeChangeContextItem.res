@react.component
let make = (
  ~alertRule: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_alertRule,
  ~context: EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t_context_AlertRuleSatisfiedEvent_MacroRelativeChangeContext,
  ~now,
  ~style,
  ~onAssetMediaClick,
) => {
  let relativeTime =
    context.targetEndAtMinuteTime
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

  let eventsScatterplotSrc = switch (
    context,
    context.targetEndAtMinuteTime->Js.Json.decodeNumber,
    context.anchorEndAtMinuteTime->Js.Json.decodeNumber,
  ) {
  | (
      {collection: {slug: collectionSlug}},
      Some(targetEndAtMinuteTime),
      Some(anchorEndAtMinuteTime),
    ) =>
    let end = targetEndAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
    let start = anchorEndAtMinuteTime->Belt.Float.toInt->Belt.Int.toString

    Some(
      `https://dpldouen3w8e7.cloudfront.net/production/events-scatterplot?collectionSlug=${collectionSlug}&startCreatedAtMinuteTime=${start}&endCreatedAtMinuteTime=${end}`,
    )
  | _ => None
  }
  let displayChange = switch context.changeDirection {
  | #INCREASE => Some(("increase", `↗`))
  | #DECREASE => Some(("decrease", `↘`))
  | #FutureAddedValue(_) => None
  }
  let displayTimeElapsed = switch (
    context.targetEndAtMinuteTime->Js.Json.decodeNumber,
    context.anchorEndAtMinuteTime->Js.Json.decodeNumber,
  ) {
  | (Some(targetEndAtMinuteTime), Some(anchorEndAtMinuteTime)) =>
    let mDiff =
      ((targetEndAtMinuteTime -. anchorEndAtMinuteTime) /. 60.0)
      ->Belt.Float.toInt
      ->Belt.Int.toString
    Some(mDiff ++ "m")
  | _ => None
  }

  let displayRelativeChange =
    context.relativeChangePercent->Belt.Option.map(Services.Format.percent(~includeSymbol=true))
  let displayFloorPrice =
    context.collectionFloorPrice->Belt.Option.map(collectionFloorPrice =>
      collectionFloorPrice
      ->Externals.Ethers.Utils.parseUnitsWithDecimals(0)
      ->Externals.Ethers.Utils.formatUnitsWithDecimals(context.paymentToken.decimals)
    )

  let (eventLabel, title, subtitle) = switch (
    alertRule.eventType,
    context,
    displayTimeElapsed,
    displayChange,
  ) {
  | (
      #FLOOR_PRICE_CHANGE,
      {collection: {name: Some(collectionName)}, absoluteChangeValue},
      Some(displayTimeElapsed),
      Some((changeVerb, changeIndicatorArrow)),
    ) =>
    let displayAbsoluteChange = absoluteChangeValue->Belt.Float.toString
    let displayChange =
      displayRelativeChange
      ->Belt.Option.map(displayRelativeChange =>
        `Ξ${displayAbsoluteChange} (${displayRelativeChange})`
      )
      ->Belt.Option.getWithDefault(`Ξ${displayAbsoluteChange}`)

    (
      Some(`floor ${changeVerb}`),
      Some(`${collectionName} ${changeIndicatorArrow} ${displayChange} in ${displayTimeElapsed}`),
      displayFloorPrice->Belt.Option.map(displayFloorPrice =>
        `current floor: ${displayFloorPrice}`
      ),
    )
  | (
      #SALE_VOLUME_CHANGE,
      {
        collection: {name: Some(collectionName)},
        absoluteChangeValue,
        timeBucket: Some(timeBucket),
        targetCount: Some(targetCount),
      },
      Some(displayTimeElapsed),
      Some((changeVerb, changeIndicatorArrow)),
    ) =>
    let displayAbsoluteChange = absoluteChangeValue->Belt.Float.toInt->Belt.Int.toString
    let displayChange =
      displayRelativeChange
      ->Belt.Option.map(displayRelativeChange =>
        `${displayAbsoluteChange} (${displayRelativeChange})`
      )
      ->Belt.Option.getWithDefault(displayAbsoluteChange)

    let displayTimeBucket = switch timeBucket {
    | #MACRO_TIME_BUCKET_5M => Some("5m")
    | #MACRO_TIME_BUCKET_15M => Some("15m")
    | #MACRO_TIME_BUCKET_30M => Some("30m")
    | #MACRO_TIME_BUCKET_1H => Some("1h")
    | _ => None
    }

    (
      Some(`sales ${changeVerb}`),
      Some(`${collectionName} ${changeIndicatorArrow} ${displayChange} in ${displayTimeElapsed}`),
      displayTimeBucket->Belt.Option.map(displayTimeBucket =>
        `current ${displayTimeBucket} sales: ${Belt.Int.toString(targetCount)}`
      ),
    )
  | _ => (None, None, None)
  }

  switch (eventLabel, title, eventsScatterplotSrc) {
  | (Some(eventLabel), Some(title), Some(eventsScatterplotSrc)) =>
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
            {React.string(`${eventLabel}: ${title}`)}
          </h2>
          <h2
            className={Cn.make(["text-darkPrimary", "hidden", "text-xs", "xs:flex", "xs:flex-1"])}>
            {React.string(`${eventLabel}: ${title}`)}
          </h2>
          <h3 className={Cn.make(["text-darkSecondary", "text-base", "xs:hidden"])}>
            {switch subtitle {
            | Some(subtitle) => React.string(`${relativeTime} • ${subtitle}`)
            | None => React.string(relativeTime)
            }}
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
