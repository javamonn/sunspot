module Loading = {
  @react.component
  let make = (~invalidRedirect=false) => {
    let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
    let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)

    let _ = React.useEffect1(() => {
      if invalidRedirect {
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

    React.null
  }
}

module Data = {
  @react.component
  let make = (~openSeaOrder, ~openSeaOrderFragment) => {
    let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)
    let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
    let (useAccountResult, _) = Externals.Wagmi.UseAccount.use()
    let (executionState, setExecutionState) = React.useState(_ =>
      OrderSection.AuthenticationPending
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
      | Contexts.Auth.Unauthenticated_AuthenticationChallengeRequired(_) =>
        let _ = signIn()
      | Unauthenticated_ConnectRequired => setExecutionState(_ => OrderSection.Buy)
      | _ => ()
      }
      None
    }, [authentication])

    let handleExecuteOrder = (~provider, ~accountAddress) => {
      setExecutionState(_ => WalletConfirmPending)
      let client = Externals.OpenSea.makeClient(
        provider,
        Externals.OpenSea.clientParams(~networkName=Externals.OpenSea.mainNetwork, ()),
      )
      openSeaClient.current = Some(client)

      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionCreated(
          ({transactionHash}) =>
            setExecutionState(_ => TransactionCreated({transactionHash: transactionHash})),
        ),
      )
      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionConfirmed(
          ({transactionHash}) => {
            setExecutionState(_ => TransactionConfirmed({transactionHash: transactionHash}))
            let _ = Externals.OpenSea.removeAllListeners(client)
          },
        ),
      )
      let _ = Externals.OpenSea.addListener(
        client,
        #TransactionFailed(
          ({transactionHash}) => {
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
          Js.log2("message", message)
          switch message {
          | Some(message)
            if Js.String2.startsWith(message, "Failed to authorize transaction") =>
            openSnackbar(
              ~type_=Contexts.Snackbar.TypeError,
              ~message=React.string("order authorization cancelled."),
              ~duration=5000,
              (),
            )
            setExecutionState(_ => OrderSection.Buy)
          | _ => setExecutionState(_ => InvalidOrder)
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
        ) if !didAutoExecuteOrder.current =>
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
let make = (~collectionSlug, ~orderId, ~onClose) => {
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

  let content = switch (
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
    <Data openSeaOrder={openSeaOrder} openSeaOrderFragment={openSeaOrderFragment} />
  }

  <div
    className={Cn.make(["flex", "flex-col", "p-4"])}
    style={ReactDOM.Style.make(~width="796px", ())}>
    <header
      style={ReactDOM.Style.make(~height="48px", ())}
      className={Cn.make(["flex", "flex-row", "items-center"])}>
      <MaterialUi.IconButton
        onClick={_ => onClose()}
        size=#Small
        classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["mr-4"]), ())}>
        <Externals.MaterialUi_Icons.Close />
      </MaterialUi.IconButton>
      <h1
        className={Cn.make([
          "font-mono",
          "text-darkPrimary",
          "font-bold",
          "leading-none",
          "text-lg",
        ])}>
        {React.string("execute buy order")}
      </h1>
    </header>
    {content}
  </div>
}
