open QueryRenderers_OAuthIntegration_GraphQL

@react.component
let make = (~onCreated, ~params) => {
  let {authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let query = Query_OAuthIntegration.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {accountAddress: accountAddress}
    | _ => {accountAddress: ""}
    },
  )

  let alertCount = switch query {
  | {data: Some({alertRules: Some({items: Some(items)})})} =>
    items
    ->Belt.Array.keepMap(a =>
      switch a {
      | Some({disabled: None}) => a
      | _ => None
      }
    )
    ->Belt.Array.length
  | _ => 0
  }
  let accountSubscriptionType = switch query {
  | {data: Some({accountSubscription: Some({type_})})} => Some(type_)
  | _ => None
  }

  <Containers.OAuthIntegration
    onCreated={onCreated}
    params={params}
    alertCount={alertCount}
    accountSubscriptionType={accountSubscriptionType}
  />
}
