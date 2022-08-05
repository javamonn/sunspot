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

let makeVariables = (~accountAddress) => {
  GraphQL.Query_AccountSubscription.accountAddress: accountAddress,
}
