module ContextProvider = {
  include React.Context

  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(Contexts_AccountSubscriptionDialog_Context.context)
}
module AccountSubscription = Query_AccountSubscription.GraphQL.AccountSubscription
module Mutation_UpdateAccountSubscription = %graphql(`
  mutation UpdateAccountSubscription($input: UpdateAccountSubscriptionInput!) {
    accountSubscription: updateAccountSubscription(input: $input) {
      ...AccountSubscription
    }
  }
`)

type dialogState =
  | Closed(option<React.element>)
  | Open(option<React.element>)

@react.component
let make = (~children) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let {authentication, signIn}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)

  let accountSubscriptionQuery = Query_AccountSubscription.GraphQL.Query_AccountSubscription.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {accountAddress: accountAddress}
    | _ => {accountAddress: ""}
    },
  )

  let prompt =
    router.asPath
    ->Services.Next.parseQuery
    ->Belt.Option.flatMap(q =>
      q->Externals.Webapi.URLSearchParams.get("prompt-account-subscription")->Js.Nullable.toOption
    )
  let (dialogState, setDialogState) = React.useState(_ =>
    switch prompt {
    | Some("ACCOUNT_SUBSCRIPTION_MIGRATION_IMPACTED") =>
      Open(
        Some(
          React.string(
            "one or more of your alerts have been disabled due to exceeding the free plan limits. upgrade your account to re-enable the disabled alerts.",
          ),
        ),
      )
    | Some("ACCOUNT_SUBSCRIPTION_EXPIRED") =>
      Open(
        Some(
          React.string(
            "your account upgrade has expired. one or more alerts have been disabled due to exceeding the free plan limits. upgrade your account to re-enable the disabled alerts.",
          ),
        ),
      )
    | _ => Closed(None)
    }
  )
  let (pendingPurchase, setPendingPurchase) = React.useState(_ => None)
  let (sendTransactionResult, sendTransaction) = Externals.Wagmi.UseTransaction.use()
  let (waitForTransactionResult, _) = Externals.Wagmi.UseWaitForTransaction.use(
    Externals.Wagmi.UseWaitForTransaction.config(
      ~wait=?sendTransactionResult
      ->Externals.Wagmi.UseTransaction.data
      ->Belt.Option.map(Externals_Ethers.TransactionResponse.wait),
      (),
    ),
  )
  let purchaseDeferred = React.useRef(None)

  let (
    updateAccountSubscriptionMutation,
    updateAccountSubscriptionMutationResult,
  ) = Mutation_UpdateAccountSubscription.use()

  let _ = React.useEffect2(() => {
    let _ = switch (authentication, pendingPurchase) {
    | (Authenticated(_), Some(type_)) =>
      let value = switch type_ {
      | #TELESCOPE => Externals.Ethers.Utils.parseUnits("0.033")
      | #OBSERVATORY => Externals.Ethers.Utils.parseUnits("0.099")
      }
      sendTransaction({
        request: {
          to_: Config.accountSubscriptionAddress,
          value: value,
        },
      })
      |> Js.Promise.then_((result: Externals.Wagmi.UseTransaction.result) => {
        switch result {
        | {error: Some(e)} if Obj.magic(e)["name"] === "UserRejectedRequestError" =>
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            ~message=React.string("account upgrade transaction rejected."),
            (),
          )
          Services.Logger.log("account subscription", "transaction rejected")
          setPendingPurchase(_ => None)
          let _ =
            purchaseDeferred.current->Belt.Option.forEach(deferred =>
              deferred->Externals.PDefer.resolve(None)
            )
          purchaseDeferred.current = None
        | {error: Some(e)} =>
          setPendingPurchase(_ => None)
          let _ =
            purchaseDeferred.current->Belt.Option.forEach(deferred =>
              deferred->Externals.PDefer.resolve(None)
            )
          let message = Obj.magic(e)["message"]
          let displayMessage = if Js.String2.startsWith(message, "insufficient funds") {
            "insufficient funds to upgrade account."
          } else {
            message
          }
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            ~message=React.string(displayMessage),
            (),
          )
          purchaseDeferred.current = None
          Services.Logger.logWithData(
            "account subscription",
            "transaction error",
            [("error", e->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->Js.Json.string)]
            ->Js.Dict.fromArray
            ->Js.Json.object_,
          )
        | _ =>
          Services.Logger.log("account subscription", "transaction sent")
          ()
        }
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(error => {
        Services.Logger.promiseError(
          "Contexts_AccountSubscriptionDialog handleClickPurchase",
          "error",
          error,
        )
        Services.Logger.logWithData(
          "account subscription",
          "transaction error",
          [("error", error->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->Js.Json.string)]
          ->Js.Dict.fromArray
          ->Js.Json.object_,
        )
        openSnackbar(
          ~type_=Contexts_Snackbar.TypeError,
          ~duration=8000,
          ~message=Obj.magic(error)["message"],
          (),
        )
        setPendingPurchase(_ => None)
        let _ =
          purchaseDeferred.current->Belt.Option.forEach(deferred =>
            deferred->Externals.PDefer.resolve(None)
          )
        purchaseDeferred.current = None
        Js.Promise.resolve()
      })
    | _ => Js.Promise.resolve()
    }

    None
  }, (authentication, pendingPurchase))

  let handleClickPurchase = type_ => {
    Services.Logger.logWithData(
      "account subscription",
      "click purchase",
      [
        (
          "type",
          switch type_ {
          | #TELESCOPE => Js.Json.string("telescope")
          | #OBSERVATORY => Js.Json.string("observatory")
          },
        ),
      ]
      ->Js.Dict.fromArray
      ->Js.Json.object_,
    )
    let _ = setPendingPurchase(_ => Some(type_))
    let _ = signIn()
  }

  let _ = React.useEffect3(() => {
    switch (waitForTransactionResult, authentication, pendingPurchase) {
    | (
        {data: Some({transactionHash})},
        Authenticated({jwt: {accountAddress}}),
        Some(accountSubscriptionType),
      ) if !updateAccountSubscriptionMutationResult.loading =>
      Services.Logger.log("account subscription", "transaction confirmed")
      let _ = updateAccountSubscriptionMutation(
        ~refetchQueries=[String("AlertRulesAndOAuthIntegrationsByAccountAddress")],
        {
          input: {
            transactionHash: transactionHash,
          },
        },
      ) |> Js.Promise.then_(result => {
        switch result {
        | Ok(_) =>
          Services.Logger.log("account subscription", "account upgraded")
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeSuccess,
            ~duration=8000,
            ~message=React.string("account upgraded."),
            (),
          )
          setDialogState(dialogState =>
            switch dialogState {
            | Open(h) => Closed(h)
            | _ => dialogState
            }
          )
          let _ =
            purchaseDeferred.current->Belt.Option.forEach(deferred =>
              deferred->Externals.PDefer.resolve(Some(accountSubscriptionType))
            )
          purchaseDeferred.current = None
        | Error(error) =>
          Services.Logger.apolloError(
            "Contexts_AccountSubscriptionDialog handleClickPurchase",
            "error",
            error,
          )
          Services.Logger.logWithData(
            "account subscription",
            "upgrade error",
            [("error", error->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->Js.Json.string)]
            ->Js.Dict.fromArray
            ->Js.Json.object_,
          )
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            ~message=<>
              {React.string("an error occurred while upgrading your account, ")}
              <a
                href={Config.discordGuildInviteUrl}
                target="_blank"
                className={Cn.make(["underline"])}>
                {React.string("contact support")}
              </a>
              {React.string(" for assistance")}
            </>,
            (),
          )
          let _ =
            purchaseDeferred.current->Belt.Option.forEach(deferred =>
              deferred->Externals.PDefer.resolve(None)
            )
          purchaseDeferred.current = None
        }
        setPendingPurchase(_ => None)
        Js.Promise.resolve()
      })
    | _ => ()
    }

    None
  }, (waitForTransactionResult.data, authentication, pendingPurchase))

  let handleClose = _ =>
    if !Js.Option.isSome(pendingPurchase) {
      Services.Logger.log("account subscription", "close dialog")
      setDialogState(dialogState =>
        switch dialogState {
        | Open(h) => Closed(h)
        | _ => Closed(None)
        }
      )
      let _ =
        purchaseDeferred.current->Belt.Option.forEach(deferred =>
          deferred->Externals.PDefer.resolve(None)
        )
      purchaseDeferred.current = None
      let _ = Externals.Next.Router.replaceWithParams(
        router,
        router.pathname,
        None,
        {Externals.Next.Router.shallow: true},
      )
    }

  let handleOpenDialog = header => {
    Services.Logger.log("account subscription", "open dialog")
    let deferred = Externals.PDefer.make()
    purchaseDeferred.current = Some(deferred)
    setDialogState(_ => Open(header))
    deferred->Externals.PDefer.promise
  }

  let accountSubscription =
    accountSubscriptionQuery.data->Belt.Option.flatMap(d => d.accountSubscription)

  <ContextProvider
    value={{
      Contexts_AccountSubscriptionDialog_Context.openDialog: handleOpenDialog,
    }}>
    <AccountSubscriptionDialog
      pendingPurchase
      isOpen={switch dialogState {
      | Open(_) => true
      | Closed(_) => false
      }}
      onClose={handleClose}
      accountSubscription=?{accountSubscription}
      onClickPurchase={handleClickPurchase}
      header=?{switch dialogState {
      | Open(header) | Closed(header) => header
      }}
    />
    {children}
  </ContextProvider>
}
