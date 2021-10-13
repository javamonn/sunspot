exception InvalidState_AlreadyAuthenticated
exception InvalidState_Web3Unavailable
exception InvalidState_Uninitalized
exception InvalidState_Desync
exception AuthenticationChallengeFailed
exception UserDecline_ConnectFailed

type authentication =
  | Unauthenticated
  | AuthenticationChallengeRequired
  | Authenticated(Contexts_Auth_Credentials.t)

type t = {
  authentication: authentication,
  signIn: unit => Js.Promise.t<unit>,
}

let context = React.createContext({
  authentication: Unauthenticated,
  signIn: () => Js.Promise.reject(InvalidState_Uninitalized),
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
        identityId
        accessKeyId
        secretKey
        sessionToken
        expiration
      }
    }
  `)

@react.component
let make = (~children) => {
  let {eth}: Contexts_Eth.t = React.useContext(Contexts_Eth.context)
  let (authentication, setAuthentication) = React.useState(() =>
    Contexts_Auth_Credentials.LocalStorage.read()
    ->Belt.Option.map(credentials => {
      let credentialExp =
        credentials->Contexts_Auth_Credentials.expiration->Js.Date.fromString->Js.Date.valueOf
      let now = Js.Date.make()->Js.Date.valueOf
      if credentialExp > now {
        AuthenticationChallengeRequired
      } else {
        Authenticated(credentials)
      }
    })
    ->Belt.Option.getWithDefault(Unauthenticated)
  )

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
    | _ => ()
    }
    None
  }, [authentication])
  let _ = React.useEffect1(() => {
    switch (eth, authentication) {
    | (NotConnected(_), Authenticated(_))
    | (NotConnected(_), AuthenticationChallengeRequired) =>
      setAuthentication(_ => Unauthenticated)
    | _ => ()
    }
    None
  }, [eth])

  let handleRequestAccount = (~provider) =>
    provider
    |> Externals.Ethereum.requestAccounts
    |> Js.Promise.then_(addresses => {
      switch addresses->Externals.Ethereum.result->Belt.Array.get(0) {
      | Some(address) => Js.Promise.resolve(address)
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
            data: {credentials: {identityId, accessKeyId, secretKey, sessionToken, expiration}},
          }: ApolloClient__Core_ApolloClient.FetchResult.t__ok<
            Mutation_AuthenticationChallengeVerify.t,
          >,
        ) =>
        Js.Promise.resolve(
          Contexts_Auth_Credentials.make(
            ~identityId,
            ~accessKeyId,
            ~secretKey,
            ~sessionToken,
            ~expiration,
          ),
        )
      | Ok(_)
      | Error(_) =>
        Js.Promise.reject(AuthenticationChallengeFailed)
      }
    })

  let handleSignIn = () => {
    switch (authentication, eth) {
    | (Unauthenticated, NotConnected({provider, web3})) =>
      handleRequestAccount(~provider) |> Js.Promise.then_(address =>
        handleAuthenticationChallenge(~web3, ~address) |> Js.Promise.then_(credentials => {
          setAuthentication(_ => Authenticated(credentials))
          Js.Promise.resolve()
        })
      )
    | (AuthenticationChallengeRequired, Connected({provider, web3, address})) =>
      handleAuthenticationChallenge(~web3, ~address) |> Js.Promise.then_(credentials => {
        setAuthentication(_ => Authenticated(credentials))
        Js.Promise.resolve()
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
    }>
    {children}
  </ContextProvider>
}
