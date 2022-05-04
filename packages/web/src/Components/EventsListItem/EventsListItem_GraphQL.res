module OpenSeaAssetMedia_OpenSeaAsset = OpenSeaAssetMedia.Fragment_OpenSeaAssetMedia_OpenSeaAsset
module EventsListItem_Attributes_OpenSeaAsset = EventsListItem_Attributes.Fragment_EventsListItem_Attributes_OpenSeaAsset
module EventsListItem_EventFilters_AlertRulePartial = EventsListItem_EventFilters.Fragment_EventsListItem_EventFilters_AlertRulePartial

module Fragment_EventsListItem_AlertRuleSatisfiedEvent = %graphql(`
    fragment EventsListItem_AlertRuleSatisfiedEvent on AlertRuleSatisfiedEvent {
      id
      createdAt
      alertRule {
        ...EventsListItem_EventFilters_AlertRulePartial
      }
      context {
        ... on AlertRuleSatisfiedEvent_ListingContext {
          __typename
          openSeaOrder {
            id
            createdTime
            asset {
              ...OpenSeaAssetMedia_OpenSeaAsset
              ...EventsListItem_Attributes_OpenSeaAsset
              name
              tokenId
              collection {
                imageUrl
                name
                slug
              }
            }
            paymentTokenContract {
              imageUrl
              decimals
            }
            currentPrice 
          }
        }
      }
    }
  `)
