module Loading = {
  @react.component
  let make = (~invalidRedirect=false) => {
    let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
    let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)

    let _ = React.useEffect1(() => {
      if invalidRedirect {
        Services.Logger.log("buy", "invalid order redirect")
        Externals.Next.Router.replace(router, "/alerts")
        openSnackbar(
          ~type_=Contexts.Snackbar.TypeError,
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
        className={Cn.make(["flex", "flex-row", "justify-space", "flex-1", "space-x-4", "mb-8"])}>
        <MaterialUi_Lab.Skeleton
          variant=#Rect
          classes={MaterialUi_Lab.Skeleton.Classes.make(~root=Cn.make(["flex-1"]), ())}
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
      <div className={Cn.make(["grid-cols-4", "grid", "gap-2", "mb-8"])}>
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
      <div className={Cn.make(["grid-cols-2", "grid", "gap-2"])}>
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
  let make = (~openSeaOrder, ~openSeaOrderFragment, ~quickbuy) => {
    let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)
    let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
    let (useAccountResult, _) = Externals.Wagmi.UseAccount.use()
    let {setIsQuickbuyTxPending}: Contexts_Buy_Context.t = React.useContext(
      Contexts_Buy_Context.context,
    )
    let (executionState, setExecutionState) = React.useState(_ =>
      quickbuy ? OrderSection.AuthenticationPending : Buy
    )
    let openSeaClient = React.useRef(None)
    let didAutoExecuteOrder = React.useRef(false)

    let _ = React.useEffect0(() => {
      Some(
        () => {
          openSeaClient.current->Belt.Option.forEach(Externals.OpenSea.removeAllListeners)
        },
      )
    })

    let _ = React.useEffect1(() => {
      let _ = switch authentication {
      | Contexts.Auth.Unauthenticated_AuthenticationChallengeRequired(_) if quickbuy =>
        let _ = signIn()
      | Unauthenticated_ConnectRequired => setExecutionState(_ => OrderSection.Buy)
      | _ => ()
      }
      None
    }, [authentication])

    let _ = React.useEffect1(() => {
      switch executionState {
      | OrderSection.Buy
      | InvalidOrder(_)
      | TransactionConfirmed(_)
      | TransactionFailed(_)
      | TransactionCreated(_) =>
        setIsQuickbuyTxPending(false)
      | _ => ()
      }
      None
    }, [executionState])

    let handleExecuteOrder = (~provider, ~accountAddress) => {
      setExecutionState(_ => WalletConfirmPending)
      Services.Logger.log("buy", "handleExecuteOrder")
      let client = Externals.OpenSea.makeClient(
        provider,
        Externals.OpenSea.clientParams(~networkName=Externals.OpenSea.mainNetwork, ()),
      )
      openSeaClient.current = Some(client)

      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionCreated(
          ({transactionHash}) => {
            Services.Logger.log("buy", "transaction created")
            setExecutionState(_ => TransactionCreated({transactionHash: transactionHash}))
          },
        ),
      )
      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionConfirmed(
          ({transactionHash}) => {
            let _ = Services.Logger.logWithData(
              "buy",
              "transaction confirmed",
              [("transactionHash", Js.Json.string(transactionHash))]
              ->Js.Dict.fromArray
              ->Js.Json.object_,
            )
            setExecutionState(_ => TransactionConfirmed({transactionHash: transactionHash}))
            let _ = Externals.OpenSea.removeAllListeners(client)
          },
        ),
      )
      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionFailed(
          ({transactionHash}) => {
            let _ = Services.Logger.logWithData(
              "buy",
              "transaction failed",
              [("transactionHash", Js.Json.string(transactionHash))]
              ->Js.Dict.fromArray
              ->Js.Json.object_,
            )
            setExecutionState(_ => TransactionFailed({transactionHash: transactionHash}))
            let _ = Externals.OpenSea.removeAllListeners(client)
          },
        ),
      )

      let _ =
        Externals.OpenSea.fulfillOrder(
          client,
          Externals.OpenSea.orderParams(
            ~order=openSeaOrder,
            ~accountAddress,
            ~referrerAddress=Config.donationsAddress,
            (),
          ),
        )
        |> Js.Promise.then_(tx => {
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(error => {
          let message = Js.Nullable.toOption(Obj.magic(error)["message"])
          let _ = Services.Logger.logWithData(
            "buy",
            "invalid order",
            [("message", message->Belt.Option.getWithDefault("")->Js.Json.string)]
            ->Js.Dict.fromArray
            ->Js.Json.object_,
          )
          switch message {
          | Some(message) if Js.String2.startsWith(message, "Failed to authorize transaction") =>
            let _ = Services.Logger.log("buy", "failed to authorize transaction")
            openSnackbar(
              ~type_=Contexts.Snackbar.TypeError,
              ~message=React.string("order authorization cancelled."),
              (),
            )
            setExecutionState(executionState =>
              switch executionState {
              | OrderSection.TransactionFailed(_)
              | OrderSection.TransactionConfirmed(_) => executionState
              | _ => OrderSection.Buy
              }
            )
          | Some(message) =>
            openSnackbar(~type_=Contexts.Snackbar.TypeError, ~message=React.string(message), ())
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
    }

    let handleClickBuy = () => {
      switch useAccountResult {
      | {Externals.Wagmi.UseAccount.data: Some({connector, address})} =>
        let _ = handleExecuteOrder(
          ~provider=connector->Externals.Wagmi.Connector.getProvider,
          ~accountAddress=address,
        )
      | {data: None} =>
        setExecutionState(_ => AuthenticationPending)
        let _ =
          signIn()
          |> Js.Promise.then_(_ => Js.Promise.resolve())
          |> Js.Promise.catch(error => {
            setExecutionState(_ => Buy)
            Js.Promise.resolve()
          })
      }
    }

    let _ = React.useEffect2(() => {
      switch (executionState, authentication, useAccountResult) {
      | (
          AuthenticationPending,
          Contexts.Auth.Authenticated(_),
          {Externals.Wagmi.UseAccount.data: Some({connector, address})},
        ) if !didAutoExecuteOrder.current && quickbuy =>
        didAutoExecuteOrder.current = true
        handleExecuteOrder(
          ~provider=connector->Externals.Wagmi.Connector.getProvider,
          ~accountAddress=address,
        )
      | _ => ()
      }
      None
    }, (authentication, useAccountResult.data->Belt.Option.map(data => data.connector.ready)))

    <OrderSection
      executionState={executionState}
      openSeaOrderFragment={openSeaOrderFragment}
      onClickBuy={() => handleClickBuy()}
    />
  }
}

let parseOpenSeaOrder = (
  order: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrder.t_openSeaOrder,
) => {
  let parseMetadataAsset = (
    a: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrderMetadataAsset.t,
  ) => {
    Externals_OpenSea.id: a.id,
    address: a.address,
    quantity: a.quantity,
  }

  let parseMetadataBundle = (
    a: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrderMetadataBundle.t,
  ) => {
    Externals_OpenSea.assets: a.assets->Belt.Array.map(parseMetadataAsset),
    schemas: a.schemas->Belt.Array.map(Obj.magic),
    name: a.name,
    description: a.description,
    externalLink: a.externalLink,
  }

  let parseMetadata = (
    m: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrder.t_openSeaOrder_metadata,
  ) => {
    Externals_OpenSea.asset: m.asset->Belt.Option.map(parseMetadataAsset),
    bundle: m.bundle->Belt.Option.map(parseMetadataBundle),
    schema: m.schema->Belt.Option.map(Obj.magic),
    referrerAddress: None,
  }

  let parseUser = (u: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrderUser.t) => {
    Externals_OpenSea.address: u.address,
    config: u.config,
    profileImgUrl: u.profileImgUrl,
    user: u.userId->Belt.Option.flatMap(Belt.Int.fromString),
  }

  let parseOpenSeaFungibleToken = (
    t: QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrder.t_openSeaOrder_paymentTokenContract,
  ) => {
    Externals_OpenSea.name: t.name,
    symbol: t.symbol,
    decimals: t.decimals,
    address: t.address,
    imageUrl: t.imageUrl,
    ethPrice: t.ethPrice,
    usdPrice: t.usdPrice,
  }

  switch (order.v, order.r, order.s) {
  | (Some(v), Some(r), Some(s)) =>
    let parsedOrder = {
      Externals_OpenSea.exchange: order.exchange,
      hash: Some(order.orderHash),
      cancelledOrFinalized: order.cancelled || order.finalized,
      markedInvalid: order.markedInvalid,
      metadata: parseMetadata(order.metadata),
      quantity: order.quantity->Externals_BigNumber.make,
      makerAccount: order.maker->parseUser,
      takerAccount: order.taker->parseUser,
      maker: order.maker.address,
      taker: order.taker.address,
      makerRelayerFee: order.makerRelayerFee->Externals_BigNumber.make,
      takerRelayerFee: order.takerRelayerFee->Externals_BigNumber.make,
      makerProtocolFee: order.makerProtocolFee->Externals_BigNumber.make,
      takerProtocolFee: order.takerProtocolFee->Externals_BigNumber.make,
      makerReferrerFee: order.makerReferrerFee->Externals_BigNumber.make,
      waitingForBestCounterOrder: order.feeRecipient.address === Config.nullAddress,
      feeMethod: order.feeMethod,
      feeRecipientAccount: order.feeRecipient->parseUser,
      feeRecipient: order.feeRecipient.address,
      side: order.side,
      saleKind: order.saleKind,
      target: order.target,
      howToCall: order.howToCall,
      calldata: order.calldata,
      replacementPattern: order.replacementPattern,
      staticTarget: order.staticTarget,
      staticExtradata: order.staticExtradata,
      paymentToken: order.paymentToken,
      basePrice: order.basePrice->Externals_BigNumber.make,
      extra: order.extra->Externals_BigNumber.make,
      currentBounty: order.currentBounty->Externals_BigNumber.make,
      currentPrice: order.currentPrice->Externals_BigNumber.make,
      createdTime: order.createdTime
      ->Js.Json.decodeNumber
      ->Belt.Option.getExn
      ->Externals_BigNumber.makeWithFloat,
      listingTime: order.listingTime
      ->Js.Json.decodeNumber
      ->Belt.Option.getExn
      ->Externals_BigNumber.makeWithFloat,
      expirationTime: order.expirationTime
      ->Js.Json.decodeNumber
      ->Belt.Option.getExn
      ->Externals_BigNumber.makeWithFloat,
      salt: order.salt->Externals_BigNumber.make,
      v: v,
      r: r,
      s: s,
      paymentTokenContract: order.paymentTokenContract->parseOpenSeaFungibleToken,
      englishAuctionReservePrice: None,
      nonce: None,
    }

    Some({
      ...parsedOrder,
      currentPrice: Externals_OpenSea.estimateCurrentPrice(parsedOrder),
    })
  | _ => None
  }
}

@react.component
let make = (~collectionSlug, ~orderId, ~quickbuy) => {
  let (orderQueryData, setOrderQueryData) = React.useState(_ => None)
  let (invalidRedirect, setInvalidRedirect) = React.useState(_ => false)

  let _ = React.useEffect0(() => {
    let _ = Contexts_Apollo_Client.inst.contents.query(
      ~query=module(QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrder),
      {
        collectionSlug: collectionSlug,
        id: Obj.magic(orderId), // schema typed as int but numbers are large enough to want to use float
      },
    ) |> Js.Promise.then_(result => {
      let _ = switch result {
      | Ok(
          {data}: ApolloClient__Core_Types.ApolloQueryResult.t__ok<
            QueryRenderers_Buy_GraphQL.Query_OpenSeaOrder.OpenSeaOrder.t,
          >,
        ) =>
        setOrderQueryData(_ => Some(data))
      | Error(_) => setInvalidRedirect(_ => true)
      }
      Js.Promise.resolve()
    })
    None
  })

  switch (
    orderQueryData
    ->Belt.Option.flatMap(({openSeaOrder}) => openSeaOrder)
    ->Belt.Option.flatMap(parseOpenSeaOrder),
    orderQueryData
    ->Belt.Option.flatMap(({openSeaOrder}) => openSeaOrder)
    ->Belt.Option.map(({orderSection_OpenSeaOrder}) => orderSection_OpenSeaOrder),
  ) {
  | _ if invalidRedirect => <Loading invalidRedirect={true} />
  | (None, None) => <Loading />
  | (None, _)
  | (_, None) =>
    <Loading invalidRedirect={true} />
  | (Some(openSeaOrder), Some(openSeaOrderFragment)) =>
    <Data
      openSeaOrder={openSeaOrder} openSeaOrderFragment={openSeaOrderFragment} quickbuy={quickbuy}
    />
  }
}
