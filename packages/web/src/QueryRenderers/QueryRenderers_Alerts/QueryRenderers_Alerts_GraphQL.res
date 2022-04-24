module Query_AlertRulesAndOAuthIntegrationsByAccountAddress = %graphql(
  `
  fragment AccountSubscription on AccountSubscription {
    ttl
    type
  }
  fragment AlertRule on AlertRule {
    id 
    eventType
    updatedAt
    contractAddress
    accountAddress
    disabled
    disabledReason
    disabledExpiresAt
    quickbuy
    collectionSlug
    collection {
      name
      imageUrl
    }
    destination {
      ... on WebPushAlertDestination {
        endpoint
        template {
          title
          body
          isThumbnailImageSize
          quickbuy
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
          quickbuy
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
        userAuthenticationToken {
          apiKey
          apiSecret
          userAccessSecret
          userAccessToken
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
      ... on AlertMacroRelativeChangeEventFilter {
        timeBucket
        timeWindow
        relativeValueChange
        absoluteValueChange
        emptyRelativeDiffAbsoluteValueChange
        direction
      }
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

  fragment TwitterIntegration on TwitterIntegration {
    accountAddress
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
    userAuthenticationToken {
      apiKey
      apiSecret
      userAccessSecret
      userAccessToken
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
    accountSubscription: getAccountSubscription(accountAddress: $accountAddress) {
      ...AccountSubscription
    }
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
        ...TwitterIntegration
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
