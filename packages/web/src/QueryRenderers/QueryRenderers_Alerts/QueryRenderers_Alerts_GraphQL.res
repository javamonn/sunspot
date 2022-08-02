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
    quickbuy
    collectionSlug
    collection {
      slug
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
          imageUrl
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
      ... on AlertRarityRankEventFilter {
        numberValue: value
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

  query AlertRulesAndOAuthIntegrationsByAccountAddress(
    $accountAddress: String!, 
    $limit: Int,
    $nextToken: String,
  ) {
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
  Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress.accountAddress: accountAddress,
  limit: None,
  nextToken: None,
}
