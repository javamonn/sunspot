@react.component
let make = (~children) => {
  let {authentication, refreshCredentials}: Contexts_Auth.t = React.useContext(
    Contexts_Auth.context,
  )
  let previousAuthentication = React.useRef(authentication)

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
    switch (previousAuthentication.current, authentication) {
    | (_, Contexts_Auth.Authenticated(_))
    | (Authenticated(_), _) =>
      let newClient = makeClient()
      let _ = setClient(_ => newClient)
      Contexts_Apollo_Client.inst.contents = newClient
    | _ => ()
    }
    previousAuthentication.current = authentication
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
