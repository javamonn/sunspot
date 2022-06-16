module Loading = {
  @react.component
  let make = (~invalidRedirect=false) => {
    let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
    let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)

    let _ = React.useEffect1(() => {
      if invalidRedirect {
        Services.Logger.log("buy", "invalid order redirect")
        Externals.Next.Router.replace(router, "/alerts")
        openSnackbar(
          ~type_=Contexts_Snackbar.TypeError,
          ~message=React.string("invalid order."),
          ~duration=5000,
          (),
        )
      }

      None
    }, [invalidRedirect])

    <>
      <div
        className={Cn.make([
          "border",
          "border-solid",
          "border-darkDisabled",
          "rounded",
          "p-6",
          "mb-8",
          "flex",
          "flex-row",
          "sm:flex-col",
          "sm:p-4",
          "sm:space-y-4",
        ])}>
        <div className={Cn.make(["flex", "flex-row", "flex-1"])}>
          <MaterialUi_Lab.Skeleton
            variant=#Text
            height={MaterialUi_Lab.Skeleton.Height.int(60)}
            width={MaterialUi_Lab.Skeleton.Width.int(160)}
          />
        </div>
        <div className={Cn.make(["flex-1"])}>
          <MaterialUi.Button
            disabled={true}
            color=#Primary
            variant=#Contained
            fullWidth={true}
            classes={MaterialUi.Button.Classes.make(
              ~root=Cn.make(["flex-1", "lowercase", "font-bold", "py-4", "text-base"]),
              (),
            )}>
            {React.string("loading...")}
            <MaterialUi.LinearProgress
              color=#Primary
              classes={MaterialUi.LinearProgress.Classes.make(
                ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
                (),
              )}
              variant=#Indeterminate
            />
          </MaterialUi.Button>
        </div>
      </div>
      <div
        className={Cn.make([
          "flex",
          "flex-row",
          "justify-space",
          "flex-1",
          "space-x-4",
          "mb-8",
          "sm:flex-col",
          "sm:space-x-0",
        ])}>
        <MaterialUi_Lab.Skeleton
          variant=#Rect
          classes={MaterialUi_Lab.Skeleton.Classes.make(
            ~root=Cn.make(["flex-1", "sm:order-last"]),
            (),
          )}
          style={ReactDOM.Style.make(~paddingBottom="50%", ())}
        />
        <div className={Cn.make(["flex", "flex-col", "justify-end", "flex-1", "space-y-2"])}>
          <MaterialUi_Lab.Skeleton
            variant=#Text
            height={MaterialUi_Lab.Skeleton.Height.int(44)}
            width={MaterialUi_Lab.Skeleton.Width.int(240)}
          />
          <MaterialUi_Lab.Skeleton
            variant=#Text
            height={MaterialUi_Lab.Skeleton.Height.int(36)}
            width={MaterialUi_Lab.Skeleton.Width.int(180)}
          />
        </div>
      </div>
      <div className={Cn.make(["grid-cols-4", "grid", "gap-2", "mb-8", "sm:grid-cols-2"])}>
        {Belt.Array.makeBy(8, _ =>
          <MaterialUi.Button
            fullWidth={true}
            size=#Small
            variant=#Outlined
            classes={MaterialUi.Button.Classes.make(
              ~label=Cn.make(["flex", "flex-col", "p-2", "space-y-2"]),
              (),
            )}>
            <MaterialUi_Lab.Skeleton
              height={MaterialUi_Lab.Skeleton.Height.int(16)}
              width={MaterialUi_Lab.Skeleton.Width.int(30 + Js.Math.random_int(0, 60))}
              variant=#Text
            />
            <MaterialUi_Lab.Skeleton
              height={MaterialUi_Lab.Skeleton.Height.int(16)}
              width={MaterialUi_Lab.Skeleton.Width.int(30 + Js.Math.random_int(0, 60))}
              variant=#Text
            />
          </MaterialUi.Button>
        )->React.array}
      </div>
      <div className={Cn.make(["grid-cols-2", "grid", "gap-2", "sm:grid-cols-1"])}>
        {["listing time", "expiration time", "contract address", "token id"]
        ->Belt.Array.map(label =>
          <MaterialUi.ListItem
            button={true}
            classes={MaterialUi.ListItem.Classes.make(
              ~root=Cn.make(["bg-gray-100", "rounded"]),
              (),
            )}>
            <MaterialUi.ListItemText
              primary={React.string(label)}
              secondary={<MaterialUi_Lab.Skeleton
                height={MaterialUi_Lab.Skeleton.Height.int(16)}
                width={MaterialUi_Lab.Skeleton.Width.int(40 + Js.Math.random_int(0, 100))}
                variant={#Text}
              />}
            />
          </MaterialUi.ListItem>
        )
        ->React.array}
      </div>
    </>
  }
}

module Data = {
  @react.component
  let make = (~openSeaEvent, ~quickbuy) => {
    let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
    let {signIn, authentication}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)
    let {setIsQuickbuyTxPending}: Contexts_OpenSeaEventDialog_Context.t = React.useContext(
      Contexts_OpenSeaEventDialog_Context.context,
    )
    let (executionState, setExecutionState) = React.useState(_ =>
      if quickbuy {
        OrderSection_Types.ClientPending
      } else {
        Buy
      }
    )
    let (waitForTransactionResult, _) = Externals.Wagmi.UseWaitForTransaction.use({
      let hash = switch executionState {
      | TransactionCreated({transactionHash})
      | TransactionConfirmed({transactionHash})
      | TransactionFailed({transactionHash}) =>
        Some(transactionHash)
      | _ => None
      }

      Externals.Wagmi.UseWaitForTransaction.config(~hash?, ~skip=!Js.Option.isSome(hash), ())
    })
    let didAutoExecuteOrder = React.useRef(false)

    let _ = React.useEffect1(() => {
      let _ = switch authentication {
      | Contexts_Auth.Unauthenticated_AuthenticationChallengeRequired(_) if quickbuy =>
        let _ = signIn()
      | Unauthenticated_ConnectRequired => setExecutionState(_ => OrderSection_Types.Buy)
      | _ => ()
      }
      None
    }, [authentication])

    let _ = React.useEffect1(() => {
      setExecutionState(executionState =>
        switch (executionState, waitForTransactionResult) {
        | (TransactionCreated({transactionHash}), {data: Some({status} as transactionReceipt)})
          if status =>
          Services.Logger.logWithData(
            "buy",
            "transaction confirmed",
            [
              (
                "transactionReceipt",
                transactionReceipt
                ->Js.Json.stringifyAny
                ->Belt.Option.getWithDefault("")
                ->Js.Json.string,
              ),
            ]
            ->Js.Dict.fromArray
            ->Js.Json.object_,
          )
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeSuccess,
            ~message=React.string("transaction confirmed."),
            (),
          )
          TransactionConfirmed({transactionHash: transactionHash})
        | (TransactionCreated({transactionHash}), {error: Some(error)}) =>
          Services.Logger.jsExn(
            ~tag="buy",
            ~message="transaction failed",
            ~extra=[("transactionHash", Js.Json.string(transactionHash))],
            error,
          )
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~message=React.string("transaction failed."),
            (),
          )
          TransactionFailed({transactionHash: transactionHash})
        | (TransactionCreated({transactionHash}), {data: Some({status} as transactionReceipt)})
          if !status =>
          Services.Logger.logWithData(
            "buy",
            "transaction failed",
            [
              ("transactionHash", Js.Json.string(transactionHash)),
              (
                "transactionReceipt",
                transactionReceipt
                ->Js.Json.stringifyAny
                ->Belt.Option.getWithDefault("")
                ->Js.Json.string,
              ),
            ]
            ->Js.Dict.fromArray
            ->Js.Json.object_,
          )
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~message=React.string("transaction reverted."),
            (),
          )
          TransactionFailed({transactionHash: transactionHash})
        | _ => executionState
        }
      )
      None
    }, [waitForTransactionResult.loading])

    let _ = React.useEffect1(() => {
      let _ = switch executionState {
      | OrderSection_Types.Buy
      | InvalidOrder(_)
      | TransactionConfirmed(_)
      | TransactionFailed(_)
      | TransactionCreated(_) =>
        setIsQuickbuyTxPending(false)
      | _ => ()
      }
      None
    }, [executionState])

    let handleExecuteOrder = () => {
      Js.log("handleExecuteOrder")
      /**
      setExecutionState(_ => WalletConfirmPending)

      let feeValue = input.feeValue->Externals.Ethers.BigNumber.makeFromString
      let wyvernExchangeValue = input.wyvernExchangeValue->Externals.Ethers.BigNumber.makeFromString

      Services.TelescopeManual.estimateGasAtomicMatch(
        contract,
        feeValue,
        wyvernExchangeValue,
        input.wyvernExchangeData,
        input.signature,
        Externals.Ethers.Contract.transactionOverrides(
          ~value=Externals.Ethers.BigNumber.add(wyvernExchangeValue, feeValue),
          (),
        ),
      )
      |> Js.Promise.then_(gasEstimate =>
        Services.TelescopeManual.atomicMatch(
          contract,
          feeValue,
          wyvernExchangeValue,
          input.wyvernExchangeData,
          input.signature,
          Externals.Ethers.Contract.transactionOverrides(
            ~value=Externals.Ethers.BigNumber.add(wyvernExchangeValue, feeValue),
            ~gasLimit={
              open Externals.Ethers.BigNumber
              gasEstimate
              ->mul(makeFromString("100"))
              ->div(makeFromString(Config.bigNumberInverseBasisPoint))
              ->add(gasEstimate)
            },
            (),
          ),
        )
      )
      |> Js.Promise.then_(transaction => {
        setExecutionState(_ => TransactionCreated({
          transactionHash: transaction->Externals.Ethers.Transaction.hash,
        }))
        let _ = Services.Logger.logWithData(
          "buy",
          "transaction created",
          [
            (
              "transaction",
              transaction->Js.Json.stringifyAny->Belt.Option.getWithDefault("")->Js.Json.string,
            ),
          ]
          ->Js.Dict.fromArray
          ->Js.Json.object_,
        )
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(error => {
        let message = Js.Nullable.toOption(Obj.magic(error)["message"])
        let dataMessage =
          Obj.magic(error)["data"]
          ->Js.Nullable.toOption
          ->Belt.Option.flatMap(data => data["message"])

        let _ = Services.Logger.logWithData(
          "buy",
          "invalid order",
          [("message", message->Belt.Option.getWithDefault("")->Js.Json.string)]
          ->Js.Dict.fromArray
          ->Js.Json.object_,
        )
        switch (message, dataMessage) {
        | (_, Some(dataMessage)) if Js.String2.startsWith(dataMessage, "execution reverted") =>
          let _ = Services.Logger.log("buy", "invalid order")
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~message=React.string("invalid order."),
            (),
          )
          setExecutionState(_ => OrderSection_Types.InvalidOrder(None))
        | (Some(message), _)
          if Js.String2.startsWith(message, "Failed to authorize transaction") ||
          Js.String2.startsWith(
            message,
            "MetaMask Tx Signature: User denied transaction signature.",
          ) =>
          let _ = Services.Logger.log("buy", "failed to authorize transaction")
          openSnackbar(
            ~type_=Contexts_Snackbar.TypeError,
            ~message=React.string("order authorization cancelled."),
            (),
          )
          setExecutionState(executionState =>
            switch executionState {
            | OrderSection_Types.TransactionFailed(_)
            | OrderSection_Types.TransactionConfirmed(_) => executionState
            | _ => OrderSection_Types.Buy
            }
          )
        | (Some(message), _) =>
          openSnackbar(~type_=Contexts_Snackbar.TypeError, ~message=React.string(message), ())
          setExecutionState(executionState =>
            switch executionState {
            | TransactionFailed(_) | TransactionConfirmed(_) => executionState
            | _ => InvalidOrder(None)
            }
          )
        | _ =>
          setExecutionState(executionState =>
            switch executionState {
            | TransactionFailed(_) | TransactionConfirmed(_) => executionState
            | _ => InvalidOrder(None)
            }
          )
        }
        Js.Promise.resolve()
      })
      **/
    }

    let handleClickBuy = () => {
      handleExecuteOrder()
    }

    <OrderSection
      executionState={executionState}
      openSeaEvent={openSeaEvent}
      onClickBuy={() => handleClickBuy()}
      quickbuy={quickbuy}
    />
  }
}

@react.component
let make = (~contractAddress, ~id, ~quickbuy) => {
  let (invalidRedirect, setInvalidRedirect) = React.useState(_ => false)
  let query = QueryRenderers_OpenSeaEvent_GraphQL.Query_OpenSeaEvent.use({
    contractAddress: contractAddress,
    id: Obj.magic(id), // schema typed as int but numbers are large enough to want to use float
  })

  switch query {
  | _ if invalidRedirect => <Loading invalidRedirect={true} />
  | {loading: true} => <Loading />
  | {data: Some({openSeaEvent: Some({orderSection_OpenSeaEvent})})} =>
    <Data openSeaEvent={orderSection_OpenSeaEvent} quickbuy={quickbuy} />
  | _ => <Loading invalidRedirect=true />
  }
}
