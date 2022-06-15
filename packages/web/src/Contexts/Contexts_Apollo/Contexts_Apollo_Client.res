exception CredentialsExpired
exception InvalidAuthConfiguration

let _ = Externals.AWSAmplify.configure(Externals.AWSAmplify.inst, Config.awsAmplifyConfig)

let makeAmplifyCredentials = awsCredentials => {
  Externals_AWSAmplify.Credentials.accessKeyId: awsCredentials->Contexts_Auth_Credentials.accessKeyId,
  secretAccessKey: awsCredentials->Contexts_Auth_Credentials.secretKey,
  sessionToken: awsCredentials->Contexts_Auth_Credentials.sessionToken,
  identityId: awsCredentials->Contexts_Auth_Credentials.identityId,
  authenticated: true,
}

let makeAuthOptions = (~credentials=?, ~apiKey=?, ~refreshCredentials=?, ()) =>
  switch (credentials, apiKey, refreshCredentials) {
  | (Some({awsCredentials, jwt}: Contexts_Auth_Credentials.t), _, Some(refreshCredentials)) =>
    Externals.AWSAppSync.LinkAuthOptions.withIAM(~credentials=() => {
      if Contexts_Auth_Credentials.isAwsCredentialValid(awsCredentials) {
        awsCredentials->makeAmplifyCredentials->Js.Promise.resolve
      } else if Contexts_Auth_Credentials.isJwtValid(jwt) {
        jwt
        |> Contexts_Auth_Credentials.JWT.raw
        |> refreshCredentials
        |> Js.Promise.then_(credentials =>
          switch credentials {
          | Some(credentials) =>
            credentials
            ->Contexts_Auth_Credentials.awsCredentials
            ->makeAmplifyCredentials
            ->Js.Promise.resolve
          | None => Js.Promise.reject(CredentialsExpired)
          }
        )
      } else {
        Js.Promise.reject(CredentialsExpired)
      }
    })
  | (_, Some(apiKey), _) => Externals.AWSAppSync.LinkAuthOptions.withAPIKey(~apiKey)
  | _ => raise(InvalidAuthConfiguration)
  }

let makeAuthLink = auth =>
  Externals.AWSAppSync.AuthLink.createAuthLink(
    Externals.AWSAppSync.AuthLink.params(
      ~auth,
      ~url=Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncGraphqlEndpointGet,
      ~region=Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncRegionGet,
    ),
  )

let makeSubscriptionHandshakeLink = auth => {
  let url = Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncGraphqlEndpointGet

  Externals.AWSAppSync.SubscriptionHandshakeLink.createSubscriptionHandshakeLink(
    Externals.AWSAppSync.SubscriptionHandshakeLink.params(
      ~auth,
      ~url,
      ~region=Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncRegionGet,
    ),
    ApolloClient.Link.HttpLink.make(~uri=_ => url, ()),
  )
}

let make = (~credentials=?, ~apiKey=?, ~refreshCredentials=?, ()) => {
  open ApolloClient

  let authOptions = makeAuthOptions(~credentials?, ~apiKey?, ~refreshCredentials?, ())

  make(
    ~cache=Cache.InMemoryCache.make(),
    ~connectToDevTools=true,
    ~defaultOptions=DefaultOptions.make(
      ~mutate=DefaultMutateOptions.make(~awaitRefetchQueries=true, ~errorPolicy=All, ()),
      ~query=DefaultQueryOptions.make(~fetchPolicy=NetworkOnly, ~errorPolicy=All, ()),
      ~watchQuery=DefaultWatchQueryOptions.make(~fetchPolicy=NetworkOnly, ~errorPolicy=All, ()),
      (),
    ),
    ~link=Link.from([
      // Contexts_Apollo_AnalyticsLink.link,
      makeAuthLink(authOptions),
      makeSubscriptionHandshakeLink(authOptions),
    ]),
    (),
  )
}

let unauthenticatedInst = make(
  ~apiKey=?Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncApiKeyGet,
  (),
)

let inst = ref(unauthenticatedInst)
