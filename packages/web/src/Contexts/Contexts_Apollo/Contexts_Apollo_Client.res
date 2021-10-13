let _ = Externals.AWSAmplify.configure(Externals.AWSAmplify.inst, Config.awsAmplifyConfig)

let makeAppSyncLink = (~credentials=?, ~apiKey=?, ()) => {
  let auth = switch (credentials, apiKey) {
  | (Some(credentials), _) =>
    Some(
      Externals.AWSAppSync.Client.authWithIAM(~credentials=() => credentials->Js.Promise.resolve),
    )
  | (_, Some(apiKey)) => Some(Externals.AWSAppSync.Client.authWithAPIKey(~apiKey))
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

let make = (~credentials=?, ~apiKey=?, ()) => {
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
    ~link=makeAppSyncLink(~credentials?, ~apiKey?, ()),
    ()
  )
}

let inst = ref(
  make(
    ~apiKey=?Config.awsAmplifyConfig->Externals.AWSAmplify.Config.appSyncApiKeyGet,
    (),
  ),
)
