exception InvalidState_AlreadyAuthenticated
exception InvalidState_Web3Unavailable
exception InvalidState_Uninitalized
exception InvalidState_Desync
exception AuthenticationChallengeFailed
exception UnableToRefreshCredentials
exception UserDecline_ConnectFailed

type authentication =
  | Unauthenticated_ConnectRequired
  | Unauthenticated_AuthenticationChallengeRequired(Externals.Wagmi.UseAccount.data)
  | InProgress_PromptConnectWallet
  | InProgress_PromptAuthenticationChallenge(Externals.Wagmi.UseAccount.data)
  | InProgress_JWTRefresh(Contexts_Auth_Credentials.t)
  | Authenticated(Contexts_Auth_Credentials.t)

let authenticationToString = a =>
  switch a {
  | Unauthenticated_ConnectRequired => "Unauthenticated_ConnectRequired"
  | Unauthenticated_AuthenticationChallengeRequired(
      _,
    ) => "Unauthenticated_AuthenticationChallengeRequired"
  | InProgress_PromptConnectWallet => "InProgress_PromptConnectWallet"
  | InProgress_PromptAuthenticationChallenge(_) => "InProgress_PromptAuthenticationChallenge"
  | InProgress_JWTRefresh(_) => "InProgress_JWTRefresh"
  | Authenticated(_) => "Authenticated"
  }

type t = {
  authentication: authentication,
  signIn: unit => Js.Promise.t<authentication>,
  refreshCredentials: string => Js.Promise.t<option<Contexts_Auth_Credentials.t>>,
}

let context = React.createContext({
  authentication: Unauthenticated_ConnectRequired,
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

let getInitialAuthenticationState = account =>
  Contexts_Auth_Credentials.LocalStorage.read()
  ->Belt.Option.map(credentials => {
    let isAwsCredentialValid =
      credentials
      ->Contexts_Auth_Credentials.awsCredentials
      ->Contexts_Auth_Credentials.isAwsCredentialValid
    let isJwtValid =
      credentials->Contexts_Auth_Credentials.jwt->Contexts_Auth_Credentials.isJwtValid

    if !isAwsCredentialValid && isJwtValid {
      InProgress_JWTRefresh(credentials)
    } else if !isAwsCredentialValid && !isJwtValid {
      switch account {
      | Some(account) => Unauthenticated_AuthenticationChallengeRequired(account)
      | None => Unauthenticated_ConnectRequired
      }
    } else {
      Authenticated(credentials)
    }
  })
  ->Belt.Option.getWithDefault(Unauthenticated_ConnectRequired)

let refreshCredentials = jwt =>
  Contexts_Apollo_Client.inst.contents.mutate(
    ~mutation=module(Mutation_AuthenticationCredentialsRefresh),
    {input: {jwt: jwt}},
  ) |> Js.Promise.then_(result => {
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

let handleAuthenticationChallenge = (~address, ~waitForMetamaskClose=false, ~signMessage, ()) =>
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
      Js.Promise.make((~resolve, ~reject) => {
        let unit_ = ()
        if waitForMetamaskClose {
          // wait a bit to ensure MM window has closed
          let _ = Js.Global.setTimeout(() => {
            resolve(. unit_)
          }, 3000)
        } else {
          resolve(. unit_)
        }
      })
      |> Js.Promise.then_(_ => signMessage({Externals.Wagmi.UseSignMessage.message: message}))
      |> Js.Promise.then_(({data, error}: Externals.Wagmi.UseSignMessage.result) =>
        switch (data, error) {
        | (Some(data), _) => Js.Promise.resolve(data)
        | (_, Some(error)) => Js.Promise.reject(AuthenticationChallengeFailed) // todo handle error
        | _ => Js.Promise.reject(AuthenticationChallengeFailed)
        }
      )
      |> Js.Promise.catch(err => Js.Promise.reject(AuthenticationChallengeFailed))
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
    | Error(_) => Js.Promise.reject(AuthenticationChallengeFailed)
    }
  })

@react.component
let make = (~children) => {
  let (
    {data: account, loading: isAccountLoading}: Externals.Wagmi.UseAccount.result,
    _,
  ) = Externals.Wagmi.UseAccount.use()
  let {state: {connecting}} = Externals.Wagmi.UseContext.use()
  let (authentication, setAuthentication) = React.useState(_ =>
    getInitialAuthenticationState(account)
  )
  let (_, signMessage) = Externals.Wagmi.UseSignMessage.use()
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let previousAuthentication = React.useRef(authentication)
  let authenticationDeferred = React.useRef(None)

  let handleRefreshCredentials = jwt =>
    refreshCredentials(jwt)
    |> Js.Promise.then_(credentials => {
      setAuthentication(_ => Authenticated(credentials))
      Js.Promise.resolve(Some(credentials))
    })
    |> Js.Promise.catch(err => {
      Services.Logger.promiseError("Contexts_Auth", "Unable to refresh credentials.", err)
      setAuthentication(_ =>
        switch account {
        | Some(account) => Unauthenticated_AuthenticationChallengeRequired(account)
        | None => Unauthenticated_ConnectRequired
        }
      )
      Js.Promise.resolve(None)
    })
  let handleAuthenticatedEffect = credentials =>
    Contexts_Auth_Credentials.LocalStorage.write(credentials)
  let handleUnauthenticatedConnectRequiredEffect = () =>
    switch previousAuthentication.current {
    | Authenticated(_)
    | InProgress_JWTRefresh(_) =>
      Contexts_Auth_Credentials.LocalStorage.clear()
    | _ => ()
    }
  let handleInProgressJWTRefreshEffect = jwt => {
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
        Services.Logger.promiseError("Contexts_Auth", "handleInProgressJWTRefreshEffect error", err)
        let _ = setAuthentication(_ =>
          switch account {
          | Some(account) => Unauthenticated_AuthenticationChallengeRequired(account)
          | None => Unauthenticated_ConnectRequired
          }
        )
        Js.Promise.resolve()
      })
  }
  let handleInProgressPromptAuthenticationChallengeEffect = account => {
    let _ =
      handleAuthenticationChallenge(
        ~address=account->Externals.Wagmi.UseAccount.address,
        ~waitForMetamaskClose=switch previousAuthentication.current {
        | InProgress_PromptConnectWallet => true
        | _ => false
        },
        ~signMessage,
        (),
      )
      |> Js.Promise.then_(credentials => {
        let _ = setAuthentication(_ => Authenticated(credentials))
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError(
          "Contexts_Auth",
          "handleInProgressPromptAuthenticationChallengeEffect error",
          err,
        )
        let _ = setAuthentication(_ => Unauthenticated_AuthenticationChallengeRequired(account))
        let _ = openSnackbar(
          ~message=<>
            {React.string("authentication challenge failed. try again, and ")}
            <a
              href={Config.discordGuildInviteUrl}
              target="_blank"
              className={Cn.make(["underline"])}>
              {React.string("contact support")}
            </a>
            {React.string(" if the issue persists.")}
          </>,
          ~type_=Contexts_Snackbar.TypeError,
          ~duration=8000,
          (),
        )
        Js.Promise.resolve()
      })
  }

  let _ = React.useEffect2(() => {
    let _ = switch (authentication, account) {
    | (Unauthenticated_ConnectRequired, Some(account)) =>
      setAuthentication(_ => Unauthenticated_AuthenticationChallengeRequired(account))
    | (InProgress_PromptConnectWallet, Some(account)) =>
      setAuthentication(_ => InProgress_PromptAuthenticationChallenge(account))
    | (Authenticated(_), None) if !connecting && !isAccountLoading =>
      setAuthentication(_ => Unauthenticated_ConnectRequired)
    | (Unauthenticated_AuthenticationChallengeRequired(_), None)
      if !connecting && !isAccountLoading =>
      setAuthentication(_ => Unauthenticated_ConnectRequired)
    | _ => ()
    }

    None
  }, (authentication, account))

  let _ = React.useEffect1(() => {
    Services.Logger.logWithData(
      "Contexts_Auth",
      "context changed",
      Js.Json.object_(
        Js.Dict.fromArray([("state", authentication->authenticationToString->Js.Json.string)]),
      ),
    )

    switch authentication {
    | Authenticated(credentials) => handleAuthenticatedEffect(credentials)
    | Unauthenticated_ConnectRequired => handleUnauthenticatedConnectRequiredEffect()
    | InProgress_JWTRefresh({jwt}) => handleInProgressJWTRefreshEffect(jwt)
    | InProgress_PromptAuthenticationChallenge(account) =>
      handleInProgressPromptAuthenticationChallengeEffect(account)
    | _ => ()
    }

    switch (authentication, authenticationDeferred.current) {
    | (Authenticated(_), Some(d))
    | (Unauthenticated_ConnectRequired(_), Some(d))
    | (Unauthenticated_AuthenticationChallengeRequired(_), Some(d)) =>
      d->Externals.PDefer.resolve(authentication)
      authenticationDeferred.current = None
    | _ => ()
    }
    previousAuthentication.current = authentication

    None
  }, [authentication])

  let handleConnectWalletModalClose = connected => {
    if !connected {
      setAuthentication(_ => Unauthenticated_ConnectRequired)
      openSnackbar(
        ~message=<>
          {React.string("failed to connect wallet. try again, and ")}
          <a href={Config.discordGuildInviteUrl} target="_blank" className={Cn.make(["underline"])}>
            {React.string("contact support")}
          </a>
          {React.string(" if the issue persists.")}
        </>,
        ~type_=Contexts_Snackbar.TypeError,
        ~duration=8000,
        (),
      )
    }
  }

  let handleSignIn = () => {
    let deferred = Externals.PDefer.make()
    authenticationDeferred.current = Some(deferred)
    setAuthentication(authentication =>
      switch authentication {
      | Unauthenticated_ConnectRequired => InProgress_PromptConnectWallet
      | Unauthenticated_AuthenticationChallengeRequired(account) =>
        InProgress_PromptAuthenticationChallenge(account)
      | s => s
      }
    )

    deferred->Externals.PDefer.promise
  }

  <ContextProvider
    value={
      authentication: authentication,
      signIn: handleSignIn,
      refreshCredentials: handleRefreshCredentials,
    }>
    {children}
    <ConnectWalletModal
      isOpen={switch authentication {
      | InProgress_PromptConnectWallet => true
      | _ => false
      }}
      onClose={connected => handleConnectWalletModalClose(connected)}
    />
  </ContextProvider>
}
