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
    apiKey: string,
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

  type makeWithApolloOptions<'serialized> = {
    link: option<ReasonMLCommunity__ApolloClient.Link.t>,
    cache: option<ReasonMLCommunity__ApolloClient.Cache.t<'serialized>>,
  }
}

module LinkAuthOptions = {
  @deriving(abstract)
  type t = {
    @as("type")
    type_: string,
    @optional
    jwtToken: unit => Js.Promise.t<Js.Json.t>,
    @optional
    credentials: unit => Js.Promise.t<Externals_AWSAmplify.Credentials.t>,
    @optional
    apiKey: string,
  }

  let make = t

  let withCognitoUserPools = (~jwtToken) => make(~type_="AMAZON_COGNITO_USER_POOLS", ~jwtToken, ())
  let withIAM = (~credentials) => make(~type_="AWS_IAM", ~credentials, ())
  let withAPIKey = (~apiKey) => make(~type_="API_KEY", ~apiKey, ())
}

module AuthLink = {
  @deriving(abstract)
  type params = {
    url: string,
    region: string,
    auth: LinkAuthOptions.t,
  }

  @val @module("aws-appsync-auth-link")
  external createAuthLink: params => ReasonMLCommunity__ApolloClient.Link.t = "createAuthLink"
}

module SubscriptionHandshakeLink = {
  @deriving(abstract)
  type params = {
    url: string,
    region: string,
    auth: LinkAuthOptions.t,
  }

  @val @module("aws-appsync-subscription-link")
  external createSubscriptionHandshakeLink: (
    params,
    ReasonMLCommunity__ApolloClient.Link.t,
  ) => ReasonMLCommunity__ApolloClient.Link.t = "createSubscriptionHandshakeLink"
}

module Rehydrated = {
  type renderProps = {rehydrated: bool}
  @module("aws-appsync-react") @react.component
  external make: (
    ~render: renderProps => React.element=?,
    ~children: React.element=?,
  ) => React.element = "Rehydrated"
}
