let makeOpenSeaAssetsUrlForValue = value =>
  value
  ->AlertModal_DialogContent.Value.collection
  ->Belt.Option.map(collection => {
    let traitsFilter =
      value
      ->AlertModal_DialogContent.Value.propertiesRule
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.map(propertyRule =>
        switch propertyRule->CreateAlertRule_Properties.Value.value {
        | CreateAlertRule_Properties.StringValue({value}) =>
          Services.OpenSea.StringTrait({
            name: propertyRule->CreateAlertRule_Properties.Value.traitType,
            value: value,
          })
        | CreateAlertRule_Properties.NumberValue({value}) =>
          Services.OpenSea.NumberTrait({
            name: propertyRule->CreateAlertRule_Properties.Value.traitType,
            value: value,
          })
        }
      )
    let priceFilter =
      value
      ->AlertModal_DialogContent.Value.priceRule
      ->Belt.Option.flatMap(priceRule =>
        switch priceRule->CreateAlertRule_Price.value->Belt.Option.flatMap(Belt.Float.fromString) {
        | Some(value) if priceRule->CreateAlertRule_Price.modifier == ">" =>
          Some(Services.OpenSea.Min(value))
        | Some(value) if priceRule->CreateAlertRule_Price.modifier == "<" =>
          Some(Services.OpenSea.Max(value))
        | _ => None
        }
      )
    let eventType = switch value->AlertModal_DialogContent.Value.eventType {
    | #listing => #LISTING
    | #sale => #SALE
    }

    Services.OpenSea.makeAssetsUrl(
      ~collectionSlug=collection->AlertModal_Types.CollectionOption.slugGet,
      ~traitsFilter,
      ~priceFilter?,
      ~eventType,
      (),
    )
  })
