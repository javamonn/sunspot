exception CredentialsExpired

let _ = Externals.AWSAmplify.configure(Externals.AWSAmplify.inst, Config.awsAmplifyConfig)

let makeAmplifyCredentials = awsCredentials => {
  Externals_AWSAmplify.Credentials.accessKeyId: awsCredentials->Contexts_Auth_Credentials.accessKeyId,
  secretAccessKey: awsCredentials->Contexts_Auth_Credentials.secretKey,
  sessionToken: awsCredentials->Contexts_Auth_Credentials.sessionToken,
  identityId: awsCredentials->Contexts_Auth_Credentials.identityId,
  authenticated: true,
}

let makeAppSyncLink = (~credentials=?, ~apiKey=?, ~refreshCredentials=?, ()) => {
  let auth = switch (credentials, apiKey, refreshCredentials) {
  | (Some({awsCredentials, jwt}: Contexts_Auth_Credentials.t), _, Some(refreshCredentials)) =>
    Externals.AWSAppSync.Client.authWithIAM(~credentials=() => {
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
    })->Js.Option.some
  | (_, Some(apiKey), _) => Some(Externals.AWSAppSync.Client.authWithAPIKey(~apiKey))
  | _ => None
  }

  let options = Externals.AWSAppSync.Client.appSyncLinkOptions(
    ~url=Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncGraphqlEndpointGet,
    ~region=Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncRegionGet,
    ~auth,
    ~disableOffline=true,
    ~complexObjectsCredentials=() =>
      Externals.AWSAmplify.Auth.inst->Externals.AWSAmplify.Auth.currentCredentials,
    ~mandatorySignIn=false,
  )

  Externals.AWSAppSync.Client.createAppSyncLink(options)
}

let make = (~credentials=?, ~apiKey=?, ~refreshCredentials=?, ()) => {
  open ApolloClient

  make(
    ~cache=Cache.InMemoryCache.make(),
    ~connectToDevTools=true,
    ~defaultOptions=DefaultOptions.make(
      ~mutate=DefaultMutateOptions.make(~awaitRefetchQueries=true, ~errorPolicy=All, ()),
      ~query=DefaultQueryOptions.make(~fetchPolicy=NetworkOnly, ~errorPolicy=All, ()),
      ~watchQuery=DefaultWatchQueryOptions.make(~fetchPolicy=NetworkOnly, ~errorPolicy=All, ()),
      (),
    ),
    ~link=makeAppSyncLink(~credentials?, ~apiKey?, ~refreshCredentials?, ()),
    (),
  )
}

let inst = ref(
  make(~apiKey=?Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncApiKeyGet, ()),
)
