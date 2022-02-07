module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRule

module Mutation_CreateAccessToken = %graphql(`
  mutation CreateAccessToken($input: CreateAccessTokenInput!) {
    accessToken: createAccessToken(input: $input) {
      accessToken 
      tokenType
      refreshToken
      expiresAt
      scope
    }
  }
`)

module Mutation_CreateDiscordOAuthIntegration = %graphql(`
  mutation CreateDiscordIntegration($input: CreateDiscordIntegrationInput!) {
    discordIntegration: createDiscordIntegration(input: $input) {
      guildId
      clientId
      iconUrl
      name
      channels {
        id
        name
      }
    }
  }
`)

module Mutation_CreateSlackOAuthIntegration = %graphql(`
  mutation CreateSlackIntegration($input: CreateSlackIntegrationInput!) {
    slackIntegration: createSlackIntegration(input: $input) {
      channelId
      channelName
      teamName
      incomingWebhookUrl
    }
  }
`)

module Mutation_CreateTwitterOAuthIntegration = %graphql(`
  mutation CreateTwitterIntegration($input: CreateTwitterIntegrationInput!) {
    twitterIntegration: createTwitterIntegration(input: $input) {
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
`)

module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRule($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)
