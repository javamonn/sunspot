module Query_AlertRulesByAccountAddress = %graphql(`
  query AlertRulesByAccountAddress($accountAddress: String!, $limit: Int, $nextToken: String) {
    alertRules: alertRulesByAccountAddress(accountAddress: $accountAddress, limit: $limit, nextToken: $nextToken) {
      items {
        id
      }
      nextToken
    }
  }
`)

@react.component
let make = () => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let query = Query_AlertRulesByAccountAddress.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {
        accountAddress: accountAddress,
        limit: Some(32),
        nextToken: None,
      }
    | _ => {accountAddress: "", limit: None, nextToken: None}
    },
  )

  let handleConnectWalletClicked = _ => {
    let _ = signIn()
  }

  Js.log2("queryData", query.data)

  <AlertsHeader eth onConnectWalletClicked={handleConnectWalletClicked} />
}
