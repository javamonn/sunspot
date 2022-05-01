module GraphQL = %graphql(`
  fragment AccountSubscription on AccountSubscription {
    ttl
    type
  }
  query Query_AccountSubscription($accountAddress: String!) {
    accountSubscription: getAccountSubscription(accountAddress: $accountAddress) {
      ...AccountSubscription
    }
  }
`)
