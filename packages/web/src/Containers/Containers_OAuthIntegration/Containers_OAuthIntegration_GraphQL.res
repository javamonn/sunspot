module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_CreateDiscordOAuthIntegration = %graphql(`
  mutation CreateDiscordIntegration($input: CreateDiscordIntegrationInput!) {
    discordIntegration: createDiscordIntegration(input: $input) {
      guildId
      iconUrl
      name
      channels {
        id
        name
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
