module OpenSeaAssetMedia_OpenSeaAsset = OpenSeaAssetMedia.Fragment_OpenSeaAssetMedia_OpenSeaAsset
module EventsListItem_Attributes_OpenSeaAsset = EventsListItem_Attributes.Fragment_EventsListItem_Attributes_OpenSeaAsset
module EventsListItem_EventFilters_AlertRulePartial = EventsListItem_EventFilters.Fragment_EventsListItem_EventFilters_AlertRulePartial

module Fragment_EventsListItem_AlertRuleSatisfiedEvent = %graphql(`
    fragment EventsListItem_AlertRuleSatisfiedEvent on AlertRuleSatisfiedEvent {
      id
      createdAt
      alertRule {
        eventType
        ...EventsListItem_EventFilters_AlertRulePartial
      }
      context {
        ... on AlertRuleSatisfiedEvent_MacroRelativeChangeContext {
          changeDirection
          absoluteChangeValue
          relativeChangePercent
          targetEndAtMinuteTime
          anchorEndAtMinuteTime
          paymentToken {
            decimals
            symbol
            imageUrl
          }
          collection {
            imageUrl
            name
            slug
          }
          collectionFloorPrice
          timeBucket
          targetCount
        }
        ... on AlertRuleSatisfiedEvent_SaleContext {
          __typename
          openSeaEvent {
            id
            createdDate
            asset {
              ...OpenSeaAssetMedia_OpenSeaAsset
              ...EventsListItem_Attributes_OpenSeaAsset
              id
              permalink
              name
              tokenId
              collection {
                imageUrl
                name
                slug
              }
            }
            paymentToken {
              id
              decimals
              symbol
              imageUrl
            }
            totalPrice
          }
        }
        ... on AlertRuleSatisfiedEvent_OpenSeaEventListingContext {
          __typename
          openSeaEvent {
            id
            createdDate
            asset {
              ...OpenSeaAssetMedia_OpenSeaAsset
              ...EventsListItem_Attributes_OpenSeaAsset
              id
              permalink
              name
              tokenId
              collection {
                imageUrl
                name
                slug
                contractAddress
              }
            }
            paymentToken {
              decimals
              symbol
              imageUrl
            }
            startingPrice
          }
        }
      }
    }
  `)
