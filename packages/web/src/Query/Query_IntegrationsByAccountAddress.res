module GraphQL = %graphql(`
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

  query Query_IntegrationsByAccountAddress(
    $discordIntegrationsInput: DiscordIntegrationsByAccountAddressInput!,   
    $slackIntegrationsInput: SlackIntegrationsByAccountAddressInput!,
    $twitterIntegrationsInput: TwitterIntegrationsByAccountAddressInput!
  ) {
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
`)

let makeVariables = (~accountAddress): GraphQL.Query_IntegrationsByAccountAddress.t_variables => {
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

let toAlertRuleDestinationOptions = (data: GraphQL.Query_IntegrationsByAccountAddress.t) => {
  let discordIntegrationOptions = switch data {
  | {discordIntegrations: Some({items: Some(discordItems)})} =>
    discordItems
    ->Belt.Array.keepMap(item =>
      item->Belt.Option.map(item =>
        item.channels->Belt.Array.map(channel => {
          AlertRule_Destination.Types.Option.DiscordAlertDestinationOption({
            clientId: item.clientId->Belt.Option.getWithDefault(Config.discord1ClientId),
            channelId: channel.id,
            channelName: channel.name,
            guildId: item.guildId,
            guildName: item.name,
            guildIconUrl: item.iconUrl,
            roles: item.roles->Belt.Array.map(r => {
              AlertRule_Destination.Types.DiscordAlertDestination.name: r.name,
              id: r.id,
            }),
          })
        })
      )
    )
    ->Belt.Array.concatMany
  | _ => []
  }
  let slackIntegrationOptions = switch data {
  | {slackIntegrations: Some({items: Some(slackItems)})} =>
    slackItems->Belt.Array.keepMap(item =>
      item->Belt.Option.map(item => AlertRule_Destination.Types.Option.SlackAlertDestinationOption({
        teamName: item.teamName,
        channelName: item.channelName,
        channelId: item.channelId,
        incomingWebhookUrl: item.incomingWebhookUrl,
      }))
    )
  | _ => []
  }
  let twitterIntegrationOptions = switch data {
  | {twitterIntegrations: Some({items: Some(twitterItems)})} =>
    twitterItems->Belt.Array.keepMap(item =>
      item->Belt.Option.flatMap(item =>
        item.user->Belt.Option.map(
          user => AlertRule_Destination.Types.Option.TwitterAlertDestinationOption({
            userId: user.id,
            username: user.username,
            profileImageUrl: user.profileImageUrl,
            accessToken: item.accessToken->Belt.Option.map(accessToken => {
              AlertRule_Destination.Types.accessToken: accessToken.accessToken,
              refreshToken: accessToken.refreshToken,
              scope: accessToken.scope,
              expiresAt: accessToken.expiresAt,
              tokenType: accessToken.tokenType,
            }),
            userAuthenticationToken: item.userAuthenticationToken->Belt.Option.map(
              userAuthenticationToken => {
                AlertRule_Destination.Types.apiKey: userAuthenticationToken.apiKey,
                apiSecret: userAuthenticationToken.apiSecret,
                userAccessToken: userAuthenticationToken.userAccessToken,
                userAccessSecret: userAuthenticationToken.userAccessSecret,
              },
            ),
          }),
        )
      )
    )
  | _ => []
  }

  Belt.Array.concatMany([
    discordIntegrationOptions,
    slackIntegrationOptions,
    twitterIntegrationOptions,
  ])
}
