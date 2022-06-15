/**
 * Amplify Typescript types: https://github.com/aws-amplify/amplify-js/blob/d5efee16181e108da52598f13b2eb05c15320244/packages/amazon-cognito-identity-js/index.d.ts
 */
module Config = {
  @deriving(abstract)
  type cloudLogicCustom = {
    name: string,
    mutable endpoint: string,
    region: string,
  }

  @deriving(abstract)
  type oauth = {
    domain: string,
    redirectSignIn: string,
    responseType: string,
    scope: array<string>,
  }

  @deriving(abstract)
  type t = {
    @as("aws_project_region")
    projectRegion: string,
    @as("aws_user_pools_id")
    userPoolsId: string,
    @as("aws_user_pools_web_client_id")
    userPoolsWebClientId: string,
    @as("aws_appsync_region")
    appSyncRegion: string,
    @as("aws_appsync_authenticationType")
    appSyncAuthenticationType: string,
    @as("aws_appsync_graphqlEndpoint")
    appSyncGraphqlEndpoint: string,
    @as("aws_appsync_apiKey") @optional
    appSyncApiKey: string,
    @as("aws_user_files_s3_bucket")
    userFilesS3Bucket: string,
    @as("aws_user_files_s3_bucket_region")
    userFilesS3BucketRegion: string,
    @as("aws_cloud_logic_custom") @optional
    cloudLogicCustom: array<cloudLogicCustom>,
    oauth: oauth,
  }
  let make = t
}

module Credentials = {
  @deriving(accessors)
  type t = {
    accessKeyId: string,
    sessionToken: string,
    secretAccessKey: string,
    identityId: string,
    authenticated: bool,
  }

  @module("@aws-amplify/core") external inst: t = "Credentials"

  @send
  external setGuest: (t, @as(json`false`) _, @as("guest") _) => Js.Promise.t<t> = "set"

  @send
  external loadCredentials: (
    t,
    Js.Promise.t<t>,
    string,
    bool,
    Js.Nullable.t<Js.Json.t>,
  ) => Js.Promise.t<t> = "_loadCredentials"

  external unsafeOfJson: Js.Json.t => t = "%identity"
}

module Auth = {
  module JwtToken = {
    type t

    external unsafeOfString: string => t = "%identity"
  }

  module CurrentUserInfo = {
    @deriving(accessors)
    type attributes = {
      email: string,
      @as("email_verified")
      emailVerified: bool,
      identities: string,
      sub: string,
    }

    @deriving(accessors)
    type t = {
      id: string,
      username: string,
      attributes: attributes,
    }
  }

  type t

  @module("@aws-amplify/auth") external inst: t = "default"

  @send external configure: (t, Config.t) => unit = "configure"

  @send
  external currentCredentials: t => Js.Promise.t<Credentials.t> = "currentCredentials"

  @send
  external currentUserInfo: t => Js.Promise.t<Js.Nullable.t<CurrentUserInfo.t>> = "currentUserInfo"

  type federatedSignInOptions = {
    provider: string,
    customState: option<string>,
  }
  @send
  external federatedSignInWithOptions: (t, federatedSignInOptions) => unit = "federatedSignIn"

  type federatedSignInResponse = {
    @as("expires_at")
    expiresAt: option<int>,
    @as("identity_id")
    identityId: option<string>,
    token: string,
  }

  @send
  external federatedSignInWithResponse: (t, string, federatedSignInResponse) => unit =
    "federatedSignIn"
}

type t
@module("@aws-amplify/core") external inst: t = "default"
@send external configure: (t, Config.t) => unit = "configure"
