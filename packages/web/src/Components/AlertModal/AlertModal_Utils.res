let makeOpenSeaAssetsUrlForValue = value =>
  value
  ->AlertModal_Value.collection
  ->Belt.Option.map(collection => {
    let traitsFilter =
      value
      ->AlertModal_Value.propertiesRule
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
      ->AlertModal_Value.priceRule
      ->Belt.Option.flatMap(priceRule =>
        switch priceRule->AlertRule_Price.value->Belt.Option.flatMap(Belt.Float.fromString) {
        | Some(value) if priceRule->AlertRule_Price.modifier == ">" =>
          Some(Services.OpenSea.Min(value))
        | Some(value) if priceRule->AlertRule_Price.modifier == "<" =>
          Some(Services.OpenSea.Max(value))
        | _ => None
        }
      )
    let eventType = value->AlertModal_Value.eventType

    Services.OpenSea.makeAssetsUrl(
      ~collectionSlug=collection->AlertModal_Types.CollectionOption.slugGet,
      ~traitsFilter,
      ~priceFilter?,
      ~eventType,
      (),
    )
  })
