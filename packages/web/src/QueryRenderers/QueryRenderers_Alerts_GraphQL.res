module Query_AlertRulesAndOAuthIntegrationsByAccountAddress = %graphql(
  `
  fragment AlertRule on AlertRule {
    id 
    eventType
    updatedAt
    contractAddress
    accountAddress
    disabled
    disabledReason
    disabledExpiresAt
    collection {
      slug
      name
      imageUrl
      contractAddress
    }
    destination {
      ... on WebPushAlertDestination {
        endpoint
        template {
          title
          body
          isThumbnailImageSize
        }
      }
      ... on DiscordAlertDestination {
        guildId
        channelId
        clientId
        roles {
          name
          id
        }
        template {
          title
          content
          description
          displayProperties
          isThumbnailImageSize
          fields {
            name
            value
            inline
          }
        }
      }
      ... on SlackAlertDestination {
        channelId
        incomingWebhookUrl
      }
      ... on TwitterAlertDestination {
        userId
        template {
          text
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
    eventFilters {
      ... on AlertQuantityEventFilter {
        numberValue: value
        direction
      }
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

  query AlertRulesAndOAuthIntegrationsByAccountAddress(
    $accountAddress: String!, 
    $limit: Int,
    $nextToken: String,
    $discordIntegrationsInput: DiscordIntegrationsByAccountAddressInput!,
    $slackIntegrationsInput: SlackIntegrationsByAccountAddressInput!,
    $twitterIntegrationsInput: TwitterIntegrationsByAccountAddressInput!
  ) {
    alertRules: alertRulesByAccountAddress(accountAddress: $accountAddress, limit: $limit, nextToken: $nextToken) {
      items {
        ...AlertRule
      }
      nextToken
    }
    discordIntegrations: discordIntegrationsByAccountAddress(input: $discordIntegrationsInput) {
      items {
        guildId
        clientId
        name
        iconUrl
        roles {
          name
          id
        }
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
`
  {inline: true}
)

let makeVariables = (~accountAddress) => {
  Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress.accountAddress: accountAddress,
  limit: None,
  nextToken: None,
  discordIntegrationsInput: {
    accountAddress: accountAddress,
  },
  slackIntegrationsInput: {
    accountAddress: accountAddress,
  },
  twitterIntegrationsInput: {
    accountAddress: accountAddress,
  },
}
