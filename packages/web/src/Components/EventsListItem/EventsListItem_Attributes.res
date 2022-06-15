module Fragment_EventsListItem_Attributes_OpenSeaAsset = %graphql(`
  fragment EventsListItem_Attributes_OpenSeaAsset on OpenSeaAsset {
    collectionSlug
    collection {
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

let getFrequency = (a: Fragment_EventsListItem_Attributes_OpenSeaAsset.t_attributes) =>
  switch a {
  | #OpenSeaAssetStringAttribute({frequency}) => frequency
  | #OpenSeaAssetNumberAttribute({frequency}) => frequency
  | #FutureAddedValue(_) => None
  }

let getTrait = (attribute: Fragment_EventsListItem_Attributes_OpenSeaAsset.t_attributes) =>
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
let make = (~openSeaAsset: Fragment_EventsListItem_Attributes_OpenSeaAsset.t, ~className=?) => {
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

  let attributes = {
    let data = switch openSeaAsset {
    | {attributes: Some(attributes)} =>
      attributes->Belt.SortArray.stableSortBy((a1, a2) => {
        switch (getFrequency(a1), getFrequency(a2)) {
        | (Some(f1), Some(f2)) => f1 - f2
        | (Some(f), None) => -1
        | (None, Some(f)) => 1
        | (None, None) => 0
        }
      })
    | _ => []
    }

    data->Belt.Array.keepMap(attribute => {
      attribute
      ->getTrait
      ->Belt.Option.map(trait => {
        let frequency = switch (getFrequency(attribute), totalAssetCount) {
        | (Some(frequency), Some(totalAssetCount)) =>
          Some(Belt.Float.fromInt(frequency) /. Belt.Float.fromInt(totalAssetCount))
        | _ => None
        }

        <li className={Cn.make(["inline-block"])}>
          <OpenSeaAssetAttibute
            ?frequency
            collectionSlug={openSeaAsset.collectionSlug}
            trait={trait}
            nameClassName={Cn.make(["whitespace-nowrap"])}
            valueClassName={Cn.make(["whitespace-nowrap"])}
            labelClassName={Cn.make(["p-0"])}
          />
        </li>
      })
    })
  }

  if attributes->Belt.Array.length > 0 {
    <div className={Cn.make(["flex", "flex-row", "flex-2"])}>
      <div className={Cn.make(["w-40", "flex-shrink-0", "pt-3"])}>
        <Externals.MaterialUi_Icons.LabelOutlined
          style={ReactDOM.Style.make(~opacity="0.42", ~height="16px", ())}
        />
        <span className={Cn.make(["text-darkSecondary", "text-sm"])}>
          {React.string("attributes")}
        </span>
      </div>
      <ul className={Cn.make(["overflow-x-scroll", "space-x-2", "whitespace-nowrap"])}>
        {attributes->React.array}
      </ul>
    </div>
  } else {
    <div className={Cn.make(["flex", "flex-2"])} />
  }
}
