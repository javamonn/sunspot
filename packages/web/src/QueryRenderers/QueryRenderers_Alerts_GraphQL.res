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
      ... on DiscordAlertDestination {
        guildId
        channelId
      }
      ... on SlackAlertDestination {
        channelId
        incomingWebhookUrl
      }
      ... on TwitterAlertDestination {
        userId
        accessToken {
          accessToken 
          tokenType
          refreshToken
          expiresAt
          scope
        }
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

module Query_OAuthIntegrationsByAccountAddress = %graphql(`
  query OAuthIntegrationsByAccountAddress(
    $discordIntegrationsInput: DiscordIntegrationsByAccountAddressInput!
    $slackIntegrationsInput: SlackIntegrationsByAccountAddressInput!
    $twitterIntegrationsInput: TwitterIntegrationsByAccountAddressInput!
  ) {
    discordIntegrations: discordIntegrationsByAccountAddress(input: $discordIntegrationsInput) {
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
    slackIntegrations: slackIntegrationsByAccountAddress(input: $slackIntegrationsInput) {
      items {
        channelId
        channelName
        teamName
        incomingWebhookUrl
      }
    }
    twitterIntegrations: twitterIntegrationsByAccountAddress(input: $twitterIntegrationsInput) {
      items {
        userId  
        user {
          id
          username
          profileImageUrl
        }
        accessToken {
          accessToken 
          tokenType
          refreshToken
          expiresAt
          scope
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
