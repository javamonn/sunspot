module OpenSeaAssetMedia_OpenSeaAsset = OpenSeaAssetMedia.Fragment_OpenSeaAssetMedia_OpenSeaAsset

module Fragment_EventsListItem_AlertRuleSatisfiedEvent = %graphql(`
    fragment EventsListItem_AlertRuleSatisfiedEvent on AlertRuleSatisfiedEvent {
      id
      createdAt
      context {
        ... on AlertRuleSatisfiedEvent_ListingContext {
          openSeaOrder {
            asset {
              ...OpenSeaAssetMedia_OpenSeaAsset
            }
          }
        }
      }
    }
  `)

@react.component
let make = (
  ~alertRuleSatisfiedEvent: option<Fragment_EventsListItem_AlertRuleSatisfiedEvent.t>,
  ~style,
  ~onAssetMediaClick,
) => {
  /**
  let price =
    item.basePrice
    ->Services.PaymentToken.parseTokenPrice(Services.PaymentToken.ethPaymentToken.decimals)
    ->Belt.Option.map(Belt.Float.toString)
    ->Belt.Option.getWithDefault("N/A")
    ->React.string
  **/

  switch alertRuleSatisfiedEvent {
  | Some({
      context: #AlertRuleSatisfiedEvent_ListingContext({openSeaOrder: {asset: Some(asset)}}),
    }) =>
    <li style={style} className={Cn.make(["list-none", "flex", "flex-row", "pb-4"])}>
      <OpenSeaAssetMedia
        onClick={onAssetMediaClick} openSeaAsset={asset} className={Cn.make(["h-44", "w-44"])}
      />
    </li>
  | _ => <li style={style}> {React.string("loading...")} </li>
  }
}
