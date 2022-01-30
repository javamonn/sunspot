let makeOpenSeaAssetsUrlForValue = value =>
  value
  ->AlertModal_DialogContent.Value.collection
  ->Belt.Option.map(collection => {
    let traitsFilter =
      value
      ->AlertModal_DialogContent.Value.propertiesRule
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.map(propertyRule =>
        switch propertyRule->AlertRule_Properties.Value.value {
        | AlertRule_Properties.StringValue({value}) =>
          Services.OpenSea.StringTrait({
            name: propertyRule->AlertRule_Properties.Value.traitType,
            value: value,
          })
        | AlertRule_Properties.NumberValue({value}) =>
          Services.OpenSea.NumberTrait({
            name: propertyRule->AlertRule_Properties.Value.traitType,
            value: value,
          })
        }
      )
    let priceFilter =
      value
      ->AlertModal_DialogContent.Value.priceRule
      ->Belt.Option.flatMap(priceRule =>
        switch priceRule->AlertRule_Price.value->Belt.Option.flatMap(Belt.Float.fromString) {
        | Some(value) if priceRule->AlertRule_Price.modifier == ">" =>
          Some(Services.OpenSea.Min(value))
        | Some(value) if priceRule->AlertRule_Price.modifier == "<" =>
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
