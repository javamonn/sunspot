exception InvalidState_AlreadyAuthenticated
exception InvalidState_Web3Unavailable
exception InvalidState_Uninitalized
exception InvalidState_Desync
exception AuthenticationChallengeFailed
exception UnableToRefreshCredentials
exception UserDecline_ConnectFailed

type authentication =
  | Unauthenticated
  | AuthenticationChallengeRequired
  | RefreshRequired(Contexts_Auth_Credentials.t)
  | Authenticated(Contexts_Auth_Credentials.t)

type t = {
  authentication: authentication,
  signIn: unit => Js.Promise.t<authentication>,
  refreshCredentials: string => Js.Promise.t<option<Contexts_Auth_Credentials.t>>,
}

let context = React.createContext({
  authentication: Unauthenticated,
  signIn: () => Js.Promise.reject(InvalidState_Uninitalized),
  refreshCredentials: _ => Js.Promise.reject(InvalidState_Uninitalized),
})

module ContextProvider = {
  include React.Context
  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(context)
}

module Mutation_AuthenticationChallengeCreate = %graphql(`
    mutation AuthenticationChallengeCreate($input: AuthenticationChallengeCreateInput!) {
      challenge: authenticationChallengeCreate(input: $input) {
        message
      }
    }
  `)

module Mutation_AuthenticationChallengeVerify = %graphql(`
    mutation AuthenticationChallengeVerify($input: AuthenticationChallengeVerifyInput!) {
      credentials: authenticationChallengeVerify(input: $input) {
        jwt
        credentials {
          identityId
          accessKeyId
          secretKey
          sessionToken
          expiration
        }
      }
    }
  `)

module Mutation_AuthenticationCredentialsRefresh = %graphql(`
  mutation AuthenticationCredentialsRefresh($input: AuthenticationCredentialsRefreshInput!) {
    credentials: authenticationCredentialsRefresh(input: $input) {
      jwt
      credentials {
        identityId
        accessKeyId
        secretKey
        sessionToken
        expiration
      }
    }
  }
`)

@react.component
let make = (~children) => {
  let {eth}: Contexts_Eth.t = React.useContext(Contexts_Eth.context)
  let (authentication, setAuthentication) = React.useState(() =>
    Contexts_Auth_Credentials.LocalStorage.read()
    ->Belt.Option.map(credentials => {
      let isAwsCredentialValid =
        credentials
        ->Contexts_Auth_Credentials.awsCredentials
        ->Contexts_Auth_Credentials.isAwsCredentialValid
      let isJwtValid =
        credentials->Contexts_Auth_Credentials.jwt->Contexts_Auth_Credentials.isJwtValid

      if !isAwsCredentialValid && isJwtValid {
        RefreshRequired(credentials)
      } else if !isAwsCredentialValid && !isJwtValid {
        AuthenticationChallengeRequired
      } else {
        Authenticated(credentials)
      }
    })
    ->Belt.Option.getWithDefault(Unauthenticated)
  )

  let handleRefreshCredentials = jwt =>
    Contexts_Apollo_Client.inst.contents.mutate(
      ~mutation=module(Mutation_AuthenticationCredentialsRefresh),
      {input: {jwt: jwt}},
    )
    |> Js.Promise.then_(result => {
      switch result {
      | Ok(
          {
            data: {
              credentials: {
                credentials: {identityId, accessKeyId, secretKey, sessionToken, expiration},
                jwt,
              },
            },
          }: ApolloClient__Core_ApolloClient.FetchResult.t__ok<
            Mutation_AuthenticationCredentialsRefresh.t,
          >,
        ) =>
        switch Contexts_Auth_Credentials.JWT.makeFromString(jwt) {
        | Some(jwt) =>
          Js.Promise.resolve(
            Contexts_Auth_Credentials.make(
              ~identityId,
              ~accessKeyId,
              ~secretKey,
              ~sessionToken,
              ~expiration,
              ~jwt,
            ),
          )
        | None => Js.Promise.reject(UnableToRefreshCredentials)
        }
      | Ok(_)
      | Error(_) =>
        Js.Promise.reject(UnableToRefreshCredentials)
      }
    })
    |> Js.Promise.then_(credentials => {
      setAuthentication(_ => Authenticated(credentials))
      Js.Promise.resolve(Some(credentials))
    })
    |> Js.Promise.catch(err => {
      Services.Logger.promiseError("Contexts_Auth", "Unable to refresh credentials.", err)
      setAuthentication(_ => AuthenticationChallengeRequired)
      Js.Promise.resolve(None)
    })

  let _ = React.useEffect1(() => {
    Services.Logger.logWithData(
      "Contexts_Auth",
      "context changed",
      Js.Json.object_(
        Js.Dict.fromArray([
          (
            "state",
            Js.Json.string(
              switch authentication {
              | Unauthenticated => "Unauthenticated"
              | AuthenticationChallengeRequired => "AuthenticationChallengeRequired"
              | RefreshRequired(_) => "RefreshRequired"
              | Authenticated(_) => "Authenticated"
              },
            ),
          ),
        ]),
      ),
    )

    switch authentication {
    | Authenticated(credentials) => Contexts_Auth_Credentials.LocalStorage.write(credentials)
    | Unauthenticated => Contexts_Auth_Credentials.LocalStorage.clear()
    | RefreshRequired({jwt}) =>
      let _ =
        jwt
        |> Contexts_Auth_Credentials.JWT.raw
        |> handleRefreshCredentials
        |> Js.Promise.then_(credentials => {
          let _ = switch credentials {
          | Some(credentials) => setAuthentication(_ => Authenticated(credentials))
          | None => ()
          }
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(err => {
          Services.Logger.promiseError("Contexts_Auth", "Unable to refresh credentials.", err)
          let _ = setAuthentication(_ => AuthenticationChallengeRequired)
          Js.Promise.resolve()
        })
    | _ => ()
    }
    None
  }, [authentication])

  let _ = React.useEffect2(() => {
    switch (eth, authentication) {
    | (NotConnected(_), Authenticated(_))
    | (NotConnected(_), AuthenticationChallengeRequired) =>
      setAuthentication(_ => Unauthenticated)
    | (Connected(_), Unauthenticated) => setAuthentication(_ => AuthenticationChallengeRequired)
    | _ => ()
    }
    None
  }, (eth, authentication))

  let handleRequestAccount = (~provider, ~web3) =>
    provider
    |> Externals.Ethereum.requestAccounts
    |> Js.Promise.then_(addresses => {
      switch addresses->Externals.Ethereum.result->Belt.Array.get(0) {
      | Some(address) => Externals.Web3.toChecksumAddress(web3, address)->Js.Promise.resolve
      | None => Js.Promise.reject(UserDecline_ConnectFailed)
      }
    })

  let handleAuthenticationChallenge = (~web3, ~address) =>
    Contexts_Apollo_Client.inst.contents.mutate(
      ~mutation=module(Mutation_AuthenticationChallengeCreate),
      {input: {address: address}},
    )
    |> Js.Promise.then_(result =>
      switch result {
      | Ok(
          {data: {challenge: {message}}}: ApolloClient__Core_ApolloClient.FetchResult.t__ok<
            Mutation_AuthenticationChallengeCreate.t,
          >,
        ) =>
        Externals.Web3.personalSign(web3, message, address)
      | Error(_) => Js.Promise.reject(AuthenticationChallengeFailed)
      }
    )
    |> Js.Promise.then_(signedMessage =>
      Contexts_Apollo_Client.inst.contents.mutate(
        ~mutation=module(Mutation_AuthenticationChallengeVerify),
        {input: {address: address, signedMessage: signedMessage}},
      )
    )
    |> Js.Promise.then_(result => {
      switch result {
      | Ok(
          {
            data: {
              credentials: {
                credentials: {identityId, accessKeyId, secretKey, sessionToken, expiration},
                jwt,
              },
            },
          }: ApolloClient__Core_ApolloClient.FetchResult.t__ok<
            Mutation_AuthenticationChallengeVerify.t,
          >,
        ) =>
        switch Contexts_Auth_Credentials.JWT.makeFromString(jwt) {
        | Some(jwt) =>
          Js.Promise.resolve(
            Contexts_Auth_Credentials.make(
              ~identityId,
              ~accessKeyId,
              ~secretKey,
              ~sessionToken,
              ~expiration,
              ~jwt,
            ),
          )
        | None => Js.Promise.reject(AuthenticationChallengeFailed)
        }
      | Ok(_)
      | Error(_) =>
        Js.Promise.reject(AuthenticationChallengeFailed)
      }
    })

  let handleSignIn = () => {
    switch (authentication, eth) {
    | (Unauthenticated, NotConnected({provider, web3})) =>
      handleRequestAccount(~provider, ~web3)
      |> Js.Promise.then_(address => handleAuthenticationChallenge(~web3, ~address))
      |> Js.Promise.then_(credentials => {
        setAuthentication(_ => Authenticated(credentials))
        Js.Promise.resolve(Authenticated(credentials))
      })
      |> Js.Promise.catch(err => {
        Services_Logger.promiseError("Contexts_Auth", "Unable to sign in.", err)
        Js.Promise.resolve(authentication)
      })
    | (AuthenticationChallengeRequired, Connected({web3, address})) =>
      handleAuthenticationChallenge(~web3, ~address)
      |> Js.Promise.then_(credentials => {
        setAuthentication(_ => Authenticated(credentials))
        Js.Promise.resolve(Authenticated(credentials))
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError("Contexts_Auth", "Failed authentication challenge.", err)
        Js.Promise.resolve(authentication)
      })
    | (RefreshRequired({jwt}), _) =>
      jwt
      |> Contexts_Auth_Credentials.JWT.raw
      |> handleRefreshCredentials
      |> Js.Promise.then_(credentials => {
        switch credentials {
        | Some(credentials) => Js.Promise.resolve(Authenticated(credentials))
        | None => Js.Promise.resolve(authentication)
        }
      })
    | (_, Web3Unavailable)
    | (_, Unknown) =>
      Js.Promise.reject(InvalidState_Web3Unavailable)
    | (AuthenticationChallengeRequired(_), _)
    | (Unauthenticated, _) =>
      Js.Promise.reject(InvalidState_Desync)
    | (Authenticated(_), _) => Js.Promise.reject(InvalidState_AlreadyAuthenticated)
    }
  }

  <ContextProvider
    value={
      authentication: authentication,
      signIn: handleSignIn,
      refreshCredentials: handleRefreshCredentials,
    }>
    {children}
  </ContextProvider>
}
