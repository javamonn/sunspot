module Client = {
  @deriving(abstract)
  type authOptions = {
    @as("type")
    type_: string,
    @optional
    jwtToken: unit => Js.Promise.t<Js.Json.t>,
    @optional
    credentials: unit => Js.Promise.t<Externals_AWSAmplify.Credentials.t>,
    @optional
    apiKey: string
  }

  let authWithCognitoUserPools = (~jwtToken) =>
    authOptions(~type_="AMAZON_COGNITO_USER_POOLS", ~jwtToken, ())
  let authWithIAM = (~credentials) => authOptions(~type_="AWS_IAM", ~credentials, ())
  let authWithAPIKey = (~apiKey) => authOptions(~type_="API_KEY", ~apiKey, ())

  @deriving(abstract)
  type appSyncLinkOptions = {
    url: string,
    region: string,
    auth: option<authOptions>,
    disableOffline: bool,
    mandatorySignIn: bool,
    complexObjectsCredentials: unit => Js.Promise.t<Externals_AWSAmplify.Credentials.t>,
  }
  @module("aws-appsync")
  external createAppSyncLink: appSyncLinkOptions => ReasonMLCommunity__ApolloClient.Link.t =
    "createAppSyncLink"

  @new @module("aws-appsync")
  external make: appSyncLinkOptions => ReasonMLCommunity__ApolloClient.t = "default"

  type makeWithApolloOptions<'serialized> = {
    link: option<ReasonMLCommunity__ApolloClient.Link.t>,
    cache: option<ReasonMLCommunity__ApolloClient.Cache.t<'serialized>>,
  }

  @new @module("aws-appsync")
  external makeWithOptions: (
    appSyncLinkOptions,
    makeWithApolloOptions<'serialized>,
  ) => ReasonMLCommunity__ApolloClient.t = "default"
}

module Rehydrated = {
  type renderProps = {rehydrated: bool}
  @module("aws-appsync-react") @react.component
  external make: (
    ~render: renderProps => React.element=?,
    ~children: React.element=?,
  ) => React.element = "Rehydrated"
}
