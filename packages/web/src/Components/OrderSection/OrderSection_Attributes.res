module Fragment_OrderSection_Attributes_OpenSeaAsset = %graphql(`
  fragment OrderSection_Attributes_OpenSeaAsset on OpenSeaAsset {
    collection {
      slug
      lastCollectionIndexEvent {
        completionReason
        successfulAssetIndexEventCount
        failedAssetIndexEventCount
        completedAt
      }
    }
    attributes {
      ... on OpenSeaAssetNumberAttribute {
        traitType
        displayType
        numberValue
        numberValueAlias: value
        maxValue
        frequency
      }
      ... on OpenSeaAssetStringAttribute {
        traitType
        displayType
        stringValue
        stringValueAlias: value
        maxValue
        frequency
      }
    }
  }
`)

let getFrequency = (a: Fragment_OrderSection_Attributes_OpenSeaAsset.t_attributes) =>
  switch a {
  | #OpenSeaAssetStringAttribute({frequency}) => frequency
  | #OpenSeaAssetNumberAttribute({frequency}) => frequency
  | #FutureAddedValue(_) => None
  }

let getTrait = (attribute: Fragment_OrderSection_Attributes_OpenSeaAsset.t_attributes) =>
  switch attribute {
  | #OpenSeaAssetNumberAttribute({traitType, numberValue: Some(numberValue)})
  | #OpenSeaAssetNumberAttribute({traitType, numberValueAlias: Some(numberValue)}) =>
    Some(
      Services.OpenSea.URL.NumberTrait({
        name: traitType,
        value: numberValue,
      }),
    )
  | #OpenSeaAssetStringAttribute({traitType, stringValue: Some(stringValue)})
    if Js.String2.length(stringValue) > 0 =>
    Some(
      Services.OpenSea.URL.StringTrait({
        name: traitType,
        value: stringValue,
      }),
    )
  | #OpenSeaAssetStringAttribute({traitType, stringValueAlias: Some(stringValue)})
    if Js.String2.length(stringValue) > 0 =>
    Some(
      Services.OpenSea.URL.StringTrait({
        name: traitType,
        value: stringValue,
      }),
    )
  | #FutureAddedValue(_) | _ => None
  }

@react.component
let make = (~openSeaAsset: Fragment_OrderSection_Attributes_OpenSeaAsset.t) => {
  openSeaAsset.attributes
  ->Belt.Option.map(attributes => {
    let sortedAttributes = attributes->Belt.SortArray.stableSortBy((a1, a2) => {
      switch (getFrequency(a1), getFrequency(a2)) {
      | (Some(f1), Some(f2)) => f1 - f2
      | (Some(_), None) => -1
      | (None, Some(_)) => 1
      | (None, None) => 0
      }
    })
    let totalAssetCount = switch openSeaAsset {
    | {
        collection: Some({
          lastCollectionIndexEvent: Some({
            completionReason: Some(#EXECUTED),
            successfulAssetIndexEventCount: Some(successfulAssetIndexEventCount),
            failedAssetIndexEventCount: Some(failedAssetIndexEventCount),
          }),
        }),
      } if successfulAssetIndexEventCount != 0 || failedAssetIndexEventCount != 0 =>
      Some(successfulAssetIndexEventCount + failedAssetIndexEventCount)
    | _ => None
    }

    <>
      <h1 className={Cn.make(["text-darkSecondary", "font-mono", "mb-2", "text-sm"])}>
        <Externals.MaterialUi_Icons.LabelOutlined
          style={ReactDOM.Style.make(~opacity="0.50", ~height="16px", ())}
        />
        {React.string("attributes")}
      </h1>
      <div className={Cn.make(["grid-cols-4", "grid", "gap-2", "mb-8", "sm:grid-cols-2"])}>
        {sortedAttributes
        ->Belt.Array.keepMap(attribute =>
          attribute
          ->getTrait
          ->Belt.Option.map(trait => {
            let frequency = switch (getFrequency(attribute), totalAssetCount) {
            | (Some(frequency), Some(totalAssetCount)) =>
              Some(Belt.Float.fromInt(frequency) /. Belt.Float.fromInt(totalAssetCount))
            | _ => None
            }
            <OpenSeaAssetAttibute
              collectionSlug={openSeaAsset.collection
              ->Belt.Option.map(c => c.slug)
              ->Belt.Option.getWithDefault("")}
              trait={trait}
              valueClassName={Cn.make(["font-semibold"])}
              ?frequency
            />
          })
        )
        ->React.array}
      </div>
    </>
  })
  ->Belt.Option.getWithDefault(React.null)
}
