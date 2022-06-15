module Query_OAuthIntegration = %graphql(`
  query OAuthIntegration($accountAddress: String!) {
    accountSubscription: getAccountSubscription(accountAddress: $accountAddress) {
      ttl
      type_: type
    }
    alertRules: alertRulesByAccountAddress(accountAddress: $accountAddress, limit: 15) {
      items {
        id
        disabled
      }
    }
  }
`)
