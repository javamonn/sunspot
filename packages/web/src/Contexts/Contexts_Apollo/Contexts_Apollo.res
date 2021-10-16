@react.component
let make = (~children) => {
  let {authentication, refreshCredentials}: Contexts_Auth.t = React.useContext(
    Contexts_Auth.context,
  )

  let makeClient = () =>
    switch authentication {
    | Authenticated(credentials) =>
      Contexts_Apollo_Client.make(~credentials, ~refreshCredentials, ())
    | _ =>
      Contexts_Apollo_Client.make(
        ~apiKey=?Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncApiKeyGet,
        (),
      )
    }
  let (innerClient, setClient) = React.useState(() => makeClient())
  let _ = React.useEffect1(() => {
    let _ = setClient(_ => makeClient())
    None
  }, [authentication])
  let _ = React.useEffect1(() => {
    Contexts_Apollo_Client.inst := innerClient
    None
  }, [innerClient])

  <ApolloClient.React.ApolloProvider client={innerClient}>
    {children}
  </ApolloClient.React.ApolloProvider>
}
