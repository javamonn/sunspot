type column = {
  label: string,
  minWidth: int,
}

let columns = [
  {
    label: "collection",
    minWidth: 200,
  },
  {
    label: "event",
    minWidth: 120,
  },
  {
    label: "rules",
    minWidth: 120,
  },
  {
    label: "destination",
    minWidth: 120,
  },
]

type quantityRule = {modifier: string, value: string}
type priceRule = {modifier: string, price: string, label: string}
type rarityRankRule = {modifier: string, value: string}
type propertyRule = {traitType: string, displayValue: string}

type rule =
  | PriceRule(priceRule)
  | PropertyRule(propertyRule)
  | QuantityRule(quantityRule)
  | RarityRankRule(rarityRankRule)
  | RelativeChangeRule(string)

@deriving(accessors)
type destination = {
  primary: string,
  secondary: option<string>,
  iconUrl: option<string>,
}

@deriving(accessors)
type row = {
  id: string,
  collectionName: option<string>,
  collectionSlug: string,
  collectionImageUrl: option<string>,
  externalUrl: string,
  eventType: string,
  rules: array<rule>,
  disabledInfo: option<string>,
  destination: option<destination>,
}
