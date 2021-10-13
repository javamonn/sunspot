@react.component
let make = (~children) => {
  let {authentication}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)
  let makeClient = () =>
    switch authentication {
    | Authenticated({accessKeyId, secretKey, sessionToken, identityId}) =>
      Contexts_Apollo_Client.make(
        ~credentials={
          Externals.AWSAmplify.Credentials.accessKeyId: accessKeyId,
          secretAccessKey: secretKey,
          sessionToken: sessionToken,
          identityId: identityId,
          authenticated: true,
        },
        (),
      )
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
