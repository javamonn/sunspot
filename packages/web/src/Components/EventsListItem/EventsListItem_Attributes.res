module Fragment_EventsListItem_Attributes_OpenSeaAsset = %graphql(`
  fragment EventsListItem_Attributes_OpenSeaAsset on OpenSeaAsset {
    collectionSlug
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
`)

@react.component
let make = (~openSeaAsset: Fragment_EventsListItem_Attributes_OpenSeaAsset.t, ~className=?) => {
  let attributes =
    openSeaAsset.attributes
    ->Belt.Option.map(attributes =>
      attributes
      ->Belt.Array.keepMap(attribute =>
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
      )
      ->Belt.Array.map(trait => {
        <li className={Cn.make(["inline-block"])}>
          <OpenSeaAssetAttibute
            collectionSlug={openSeaAsset.collectionSlug}
            trait={trait}
            nameClassName={Cn.make(["whitespace-nowrap"])}
            valueClassName={Cn.make(["whitespace-nowrap"])}
            labelClassName={Cn.make(["p-0"])}
          />
        </li>
      })
    )
    ->Belt.Option.getWithDefault([])

  if attributes->Belt.Array.length > 0 {
    <div className={Cn.make(["flex", "flex-row", "items-center", "flex-2"])}>
      <div className={Cn.make(["w-40", "flex-shrink-0"])}>
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
