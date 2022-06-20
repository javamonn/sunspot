module Fragment_EventsListItem_EventFilters_AlertRulePartial = %graphql(`
  fragment EventsListItem_EventFilters_AlertRulePartial on AlertRuleSatisfiedEvent_AlertRulePartial {
    eventFilters {
      ... on AlertMacroRelativeChangeEventFilter {
        timeBucket
        timeWindow
        relativeValueChange
        absoluteValueChange
        emptyRelativeDiffAbsoluteValueChange
        direction
      }
      ... on AlertQuantityEventFilter {
        intValueAlias: value
        intValue
        direction
      }
      ... on AlertRarityRankEventFilter {
        intValueAlias: value
        intValue
        direction
      }
      ... on AlertPriceThresholdEventFilter {
        stringValueAlias: value
        stringValue
        direction
        paymentToken {
          id
          decimals
        }
      }
      ... on AlertAttributesEventFilter {
        attributes {
          ... on OpenSeaAssetNumberAttribute {
            traitType
            displayType
            numberValue
            numberValueAlias: value
            maxValue
          }
          ... on OpenSeaAssetStringAttribute {
            traitType
            displayType
            stringValue
            stringValueAlias: value
            maxValue
          }
        }
      }
    }
  }
`)

@react.component
let make = (~alertRule: Fragment_EventsListItem_EventFilters_AlertRulePartial.t) => {
  let displayFilters = alertRule.eventFilters->Belt.Array.keepMap(eventFilter =>
    switch eventFilter {
    | #AlertAttributesEventFilter(filter) =>
      let attributes =
        filter.attributes
        ->Belt.Array.keepMap(attribute => {
          let displayTrait = switch attribute {
          | #OpenSeaAssetNumberAttribute({traitType, numberValue: Some(numberValue)})
          | #OpenSeaAssetNumberAttribute({traitType, numberValueAlias: Some(numberValue)}) =>
            Some((traitType, Belt.Float.toString(numberValue)))
          | #OpenSeaAssetStringAttribute({traitType, stringValue: Some(stringValue)})
          | #OpenSeaAssetStringAttribute({traitType, stringValueAlias: Some(stringValue)}) =>
            Some((traitType, stringValue))
          | #FutureAddedValue(_) | _ => None
          }
          displayTrait->Belt.Option.map(((traitType, displayValue)) =>
            `${traitType} (${displayValue})`
          )
        })
        ->Belt.Array.joinWith(", ", i => i)
      Some(`properties matching: ${attributes}`)
    | #AlertQuantityEventFilter({direction, intValue: Some(intValue)})
    | #AlertQuantityEventFilter({direction, intValueAlias: Some(intValue)}) =>
      let displayModifier = switch direction {
      | #ALERT_ABOVE => Some(">")
      | #ALERT_BELOW => Some("<")
      | #ALERT_EQUAL => Some("=")
      | _ => None
      }
      let quantity = intValue->Belt.Int.toString

      displayModifier->Belt.Option.map(displayModifier => `quantity ${displayModifier} ${quantity}`)
    | #AlertRarityRankEventFilter({direction, intValue: Some(intValue)})
    | #AlertRarityRankEventFilter({direction, intValueAlias: Some(intValue)}) =>
      let displayModifier = switch direction {
      | #ALERT_ABOVE => Some(">")
      | #ALERT_BELOW => Some("<")
      | #ALERT_EQUAL => Some("=")
      | _ => None
      }
      let quantity = intValue->Belt.Int.toString

      displayModifier->Belt.Option.map(displayModifier => `rank ${displayModifier} ${quantity}`)
    | #AlertPriceThresholdEventFilter({
      direction,
      stringValueAlias: Some(stringValue),
      paymentToken,
    })
    | #AlertPriceThresholdEventFilter({direction, stringValue: Some(stringValue), paymentToken}) =>
      let displayPrice =
        stringValue
        ->Services.PaymentToken.parseTokenPrice(paymentToken.decimals)
        ->Belt.Option.map(Belt.Float.toString)

      let displayModifier = switch direction {
      | #ALERT_ABOVE => Some(">")
      | #ALERT_BELOW => Some("<")
      | #ALERT_EQUAL => Some("=")
      | _ => None
      }

      switch (displayModifier, displayPrice) {
      | (Some(displayModifier), Some(displayPrice)) =>
        Some(`price ${displayModifier} Ξ${displayPrice}`)
      | _ => None
      }
    | _ => None
    }
  )

  if Belt.Array.length(displayFilters) > 0 {
    <div
      className={Cn.make([
        "flex",
        "flex-row",
        "flex-1",
        "items-center",
        "justify-end",
        "overflow-x-hidden",
      ])}>
      <div className={Cn.make(["flex-shrink-0", "mr-2"])}>
        <Externals.MaterialUi_Icons.FilterList
          style={ReactDOM.Style.make(~opacity="0.42", ~height="18px", ())}
        />
      </div>
      <span
        className={Cn.make([
          "text-darkPrimary",
          "text-sm",
          "overflow-x-hidden",
          "whitespace-nowrap",
          "truncate",
        ])}>
        {displayFilters->Belt.Array.joinWith(", ", i => i)->React.string}
      </span>
    </div>
  } else {
    <div className={Cn.make(["flex", "flex-1"])} />
  }
}
