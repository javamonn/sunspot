module Query_AlertRulesByAccountAddress = %graphql(
  `
  fragment AlertRule on AlertRule {
    id 
    eventType
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
        guildId
        channelId
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

module Query_DiscordIntegrationsByAccountAddress = %graphql(`
  query DiscordIntegrationsByAccountAddress($input: DiscordIntegrationsByAccountAddressInput!) {
    discordIntegrations: discordIntegrationsByAccountAddress(input: $input) {
      items {
        guildId
        name
        iconUrl
        channels {
          name 
          id
        }
      }
    }
  }
`)

let makeVariables = (~accountAddress) => {
  Query_AlertRulesByAccountAddress.AlertRulesByAccountAddress.accountAddress: accountAddress,
  limit: None,
  nextToken: None,
}
