type validationError =
  | InvalidInput(string)
  | AccountSubscriptionRequired({
      message: string,
      requiredAccountSubscriptionType: [#TELESCOPE | #OBSERVATORY],
    })

let validateValue = value => {
  let collectionValidation = switch value->AlertModal_Value.collection {
  | None => Some("collection is required")
  | Some(_) => None
  }
  let priceRuleValidation = switch value->AlertModal_Value.priceRule {
  | Some({modifier}) if Js.String2.length(modifier) == 0 => Some("price rule modifier is required.")
  | Some({value: None}) => Some("price rule value is required.")
  | Some({value: Some(value)}) =>
    switch Belt.Float.fromString(value) {
    | Some(value) if value <= 0.00 => Some("price rule value must be a positive number.")
    | None => Some("price rule value must be a positive number.")
    | _ => None
    }
  | None => None
  }
  let propertiesRuleValidation = switch value->AlertModal_Value.propertiesRule {
  | Some(value) if Belt.Array.length(value) == 0 =>
    Some("properties rule value must include properties")
  | _ => None
  }
  let destinationValidation = switch value->AlertModal_Value.destination {
  | None => Some("destination is required.")
  | Some(DiscordAlertDestination({template: Some({fields: Some(fields)})})) =>
    if (
      Belt.Array.some(fields, field =>
        field->AlertRule_Destination_Types.DiscordTemplate.name->Js.String2.length == 0 ||
          field->AlertRule_Destination_Types.DiscordTemplate.value->Js.String2.length == 0
      )
    ) {
      Some("discord template fields must not contain empty name or value.")
    } else {
      None
    }
  | Some(_) => None
  }

  let quantityRuleValidation = switch value->AlertModal_Value.quantityRule {
  | Some({modifier}) if Js.String2.length(modifier) == 0 =>
    Some("quantity rule modifier is required.")
  | Some({value: None}) => Some("quantity rule value is required.")
  | Some({value: Some(value)}) =>
    switch value->Belt.Int.fromString {
    | Some(value) if value <= 0 => Some("quantity rule value must be a positive whole number.")
    | Some(parsedValue)
      if parsedValue->Belt.Float.fromInt !==
        value->Belt.Float.fromString->Belt.Option.getWithDefault(-1.) =>
      Some("quantity rule value must be a positive whole number.")
    | None => Some("quantity rule value must be a positive number.")
    | _ => None
    }
  | None => None
  }
  let macroRelativeChangeEventFilterValidation = switch (
    value->AlertModal_Value.eventType,
    value->AlertModal_Value.floorPriceChangeRule,
    value->AlertModal_Value.saleVolumeChangeRule,
  ) {
  | (#SALE_VOLUME_CHANGE, _, Some({relativeValueChange: None, absoluteValueChange: None}))
  | (#FLOOR_PRICE_CHANGE, Some({relativeValueChange: None, absoluteValueChange: None}), _) =>
    Some("at least one of (threshold percent change, threshold absolute change) is required")
  | (_, Some({absoluteValueChange: Some(absoluteValueChange)}), _)
    if absoluteValueChange->Belt.Float.fromString->Js.Option.isNone =>
    Some("absolute value change must be a number")
  | _ => None
  }

  [
    collectionValidation,
    priceRuleValidation,
    propertiesRuleValidation,
    quantityRuleValidation,
    destinationValidation,
    macroRelativeChangeEventFilterValidation,
  ]
  ->Belt.Array.keepMap(i => i)
  ->Belt.Array.get(0)
  ->Belt.Option.map(s => InvalidInput(s))
}

let validateAccountSubscription = (
  ~accountSubscriptionType,
  ~alertCount,
  ~updatingValue,
  ~value: AlertModal_Value.t,
) => {
  let alertCountValidation = switch accountSubscriptionType {
  | None if alertCount >= 3 && Js.Option.isNone(updatingValue) =>
    Some(
      AccountSubscriptionRequired({
        message: "upgrade your account to create more than 3 alerts.",
        requiredAccountSubscriptionType: #TELESCOPE,
      }),
    )
  | Some(#TELESCOPE) if alertCount >= 15 && Js.Option.isNone(updatingValue) =>
    Some(
      AccountSubscriptionRequired({
        message: "upgrade your account to create more than 15 alerts.",
        requiredAccountSubscriptionType: #OBSERVATORY,
      }),
    )
  | _ => None
  }
  let updateAlertCountValidation = {
    let isEnabling =
      updatingValue->Belt.Option.flatMap(v => v->AlertModal_Value.disabled)->Js.Option.isSome &&
        !(value->AlertModal_Value.disabled->Js.Option.isSome)
    switch accountSubscriptionType {
    | None if alertCount >= 3 && isEnabling =>
      Some(
        AccountSubscriptionRequired({
          message: "upgrade your account to have more than 3 alerts enabled.",
          requiredAccountSubscriptionType: #TELESCOPE,
        }),
      )
    | Some(#TELESCOPE) if alertCount >= 15 && isEnabling =>
      Some(
        AccountSubscriptionRequired({
          message: "upgrade your account to have more than 15 alert enabled.",
          requiredAccountSubscriptionType: #OBSERVATORY,
        }),
      )
    | _ => None
    }
  }

  let templateValidation = {
    let hasCustomTemplate = switch value->AlertModal_Value.destination {
    | Some(WebPushAlertDestination({template: Some(_)}))
    | Some(DiscordAlertDestination({template: Some(_)}))
    | Some(TwitterAlertDestination({template: Some(_)})) => true
    | _ => false
    }
    let message = "upgrade your account to customize alert text and formatting."

    switch accountSubscriptionType {
    | None if hasCustomTemplate =>
      Some(
        AccountSubscriptionRequired({
          message: message,
          requiredAccountSubscriptionType: #OBSERVATORY,
        }),
      )
    | Some(#TELESCOPE) if hasCustomTemplate =>
      Some(
        AccountSubscriptionRequired({
          message: message,
          requiredAccountSubscriptionType: #OBSERVATORY,
        }),
      )
    | _ => None
    }
  }
  let twitterDestinationValidation = switch (
    value->AlertModal_Value.destination,
    accountSubscriptionType,
  ) {
  | (Some(TwitterAlertDestination(_)), Some(#TELESCOPE))
  | (Some(TwitterAlertDestination(_)), None) =>
    Some(
      AccountSubscriptionRequired({
        message: "upgrade your account to use a twitter destination.",
        requiredAccountSubscriptionType: #OBSERVATORY,
      }),
    )
  | _ => None
  }

  [
    alertCountValidation,
    updateAlertCountValidation,
    templateValidation,
    twitterDestinationValidation,
  ]
  ->Belt.Array.keepMap(i => i)
  ->Belt.Array.get(0)
}

let execute = (~accountSubscriptionType, ~alertCount, ~updatingValue, ~value) =>
  switch (
    validateValue(value),
    validateAccountSubscription(~accountSubscriptionType, ~alertCount, ~updatingValue, ~value),
  ) {
  | (Some(s), _) | (_, Some(s)) => Some(s)
  | _ => None
  }
