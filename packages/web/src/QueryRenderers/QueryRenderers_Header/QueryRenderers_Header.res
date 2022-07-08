@react.component
let make = (~children) => {
  let {authentication, signIn}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)
  let {openCreateAlertModal}: Contexts_AlertCreateAndUpdateDialog_Context.t = React.useContext(
    Contexts_AlertCreateAndUpdateDialog_Context.context,
  )

  let accountSubscriptionQuery = Query_AccountSubscription.GraphQL.Query_AccountSubscription.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {accountAddress: accountAddress}
    | _ => {accountAddress: ""}
    },
  )

  let handleWalletButtonClicked = _ => {
    let _ = signIn()
  }
  let handleCreateAlertClicked = () => {
    openCreateAlertModal(None)
  }

  let isLoadingAccountSubscription = switch authentication {
  | Contexts_Auth.InProgress_JWTRefresh(_) => true
  | Authenticated(_) => accountSubscriptionQuery.loading
  | _ => false
  }
  let accountSubscription =
    accountSubscriptionQuery.data->Belt.Option.flatMap(a => a.accountSubscription)

  <>
    <Header
      authentication
      onConnectWalletClicked={handleWalletButtonClicked}
      onWalletButtonClicked={handleWalletButtonClicked}
      onCreateAlertClicked={handleCreateAlertClicked}
      accountSubscription={accountSubscription}
      isLoadingAccountSubscription={isLoadingAccountSubscription}
    />
    {children}
  </>
}
