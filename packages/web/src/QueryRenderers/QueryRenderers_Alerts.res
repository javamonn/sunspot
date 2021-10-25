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
  let (createAlertModalIsOpen, setCreateAlertModalIsOpen) = React.useState(_ => false)

  let handleConnectWalletClicked = _ => {
    let _ = signIn()
  }

  <>
    <AlertsHeader
      eth
      onConnectWalletClicked={handleConnectWalletClicked}
      onCreateAlertClicked={_ => setCreateAlertModalIsOpen(_ => true)}
    />
    <Containers.CreateAlertModal
      isOpen={createAlertModalIsOpen} onClose={_ => setCreateAlertModalIsOpen(_ => false)}
    />
  </>
}
