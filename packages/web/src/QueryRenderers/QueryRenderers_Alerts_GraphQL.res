module Query_AlertRulesByAccountAddress = %graphql(
  `
  fragment AlertRule on AlertRule {
    id 
    updatedAt
    contractAddress
    accountAddress
    collection {
      slug
      name
      imageUrl
      contractAddress
    }
    destination {
      ... on WebPushAlertDestination {
        endpoint
      }
      ...on DiscordAlertDestination {
        endpoint
      }
    }
    eventFilters {
      ... on AlertPriceThresholdEventFilter {
        value
        direction
        paymentToken {
          id
          decimals
        }
      }
      ... on AlertAttributesEventFilter {
        attributes {
          ... on OpenSeaAssetNumberAttribute {
            traitType
            displayType
            numberValue: value
            maxValue
          }
          ... on OpenSeaAssetStringAttribute {
            traitType
            displayType
            stringValue: value
            maxValue
          }
        }
      }
    }
  }

  query AlertRulesByAccountAddress($accountAddress: String!, $limit: Int, $nextToken: String) {
    alertRules: alertRulesByAccountAddress(accountAddress: $accountAddress, limit: $limit, nextToken: $nextToken) {
      items {
        ...AlertRule
      }
      nextToken
    }
  }
`
  {inline: true}
)

let makeVariables = (~accountAddress) => {
  Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress.accountAddress: accountAddress,
  limit: None,
  nextToken: None,
}
