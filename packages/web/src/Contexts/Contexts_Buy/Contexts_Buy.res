let styles = %raw("require('./Contexts_Buy.module.css')")

module ContextProvider = {
  include React.Context

  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(Contexts_Buy_Context.context)
}

let parseQuery = path => {
  let queryIndex = Js.String2.indexOf(path, "?")
  if queryIndex !== -1 {
    try {
      Js.String2.substringToEnd(~from=queryIndex, path)
      ->Externals.Webapi.URLSearchParams.make
      ->Js.Option.some
    } catch {
    | _ => None
    }
  } else {
    None
  }
}

type params = {
  collectionSlug: string,
  orderId: float,
  quickbuy: bool,
}

let makeSeaportClient = (useAccountResult: Externals.Wagmi.UseAccount.data) => {
  switch useAccountResult {
  | {connector, address} if connector.ready =>
    connector
    |> Externals.Wagmi.Connector.getSigner
    |> Js.Promise.then_(signer =>
      Js.Promise.resolve(
        Some({
          Contexts_Buy_Types.wyvernExchangeContract: Services.OpenSea.Seaport.makeWyvernExchangeContract(
            Services.OpenSea.Seaport.makeWyvernExchangeContractParams(~web3=signer),
          ),
          accountAddress: address,
        }),
      )
    )
  | _ => Js.Promise.resolve(None)
  }
}

@react.component
let make = (~children) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let (
    {data: useAccountData}: Externals.Wagmi.UseAccount.result,
    _,
  ) = Externals.Wagmi.UseAccount.use()
  let {authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let queryParams = router.asPath->parseQuery
  let buyParams = switch (
    queryParams->Belt.Option.flatMap(q =>
      q->Externals.Webapi.URLSearchParams.get("buyCollectionSlug")
    ),
    queryParams
    ->Belt.Option.flatMap(q => q->Externals.Webapi.URLSearchParams.get("buyOrderId"))
    ->Belt.Option.flatMap(Belt.Float.fromString),
    queryParams->Belt.Option.flatMap(q =>
      q->Externals.Webapi.URLSearchParams.get("orderCollectionSlug")
    ),
    queryParams
    ->Belt.Option.flatMap(q => q->Externals.Webapi.URLSearchParams.get("orderId"))
    ->Belt.Option.flatMap(Belt.Float.fromString),
    queryParams
    ->Belt.Option.flatMap(q => q->Externals.Webapi.URLSearchParams.get("orderQuickbuy"))
    ->Belt.Option.map(q => q === "true"),
  ) {
  | (Some(collectionSlug), Some(orderId), _, _, _) =>
    Some({collectionSlug: collectionSlug, orderId: orderId, quickbuy: true})
  | (_, _, Some(collectionSlug), Some(orderId), Some(quickbuy)) =>
    Some({collectionSlug: collectionSlug, orderId: orderId, quickbuy: quickbuy})
  | _ => None
  }
  let (isBuyModalOpen, setIsBuyModalOpen) = React.useState(_ => Js.Option.isSome(buyParams))
  let (isQuickbuyTxPending, setIsQuickbuyTxPending) = React.useState(_ => isBuyModalOpen)
  let (seaportClient, setSeaportClient) = React.useState(_ => None)

  let handleBuyModalClose = ev => {
    setIsBuyModalOpen(_ => false)
  }
  let handleBuyModalClosed = _ => {
    Externals.Next.Router.replaceWithParams(router, "/alerts", None, {shallow: true}) // clear query params
  }

  let _ = React.useEffect1(() => {
    let nextIsBuyModalOpen = Js.Option.isSome(buyParams)
    let _ = setIsBuyModalOpen(_ => nextIsBuyModalOpen)
    Services.Logger.logWithData(
      "buy",
      "setIsBuyDrawerOpen",
      [("isOpen", buyParams->Js.Option.isSome->Js.Json.boolean)]
      ->Js.Dict.fromArray
      ->Js.Json.object_,
    )
    None
  }, [Js.Option.isSome(buyParams)])

  let _ = React.useEffect3(() => {
    let _ = switch (useAccountData, authentication) {
    | (Some(useAccountData), Authenticated(_)) =>
      let _ = makeSeaportClient(useAccountData) |> Js.Promise.then_(seaportClient => {
        let _ = setSeaportClient(_ => seaportClient)
        Js.Promise.resolve()
      })
    | _ => ()
    }
    None
  }, (
    useAccountData->Belt.Option.map(data => data.connector.ready),
    useAccountData->Belt.Option.map(data => data.address),
    authentication,
  ))

  <ContextProvider
    value={
      Contexts_Buy_Context.isQuickbuyTxPending: isQuickbuyTxPending,
      setIsQuickbuyTxPending: newIsQuickbuyTxPending => {
        setIsQuickbuyTxPending(_ => newIsQuickbuyTxPending)
      },
      isBuyModalOpen: isBuyModalOpen,
    }>
    <MaterialUi.Dialog
      classes={MaterialUi.Dialog.Classes.make(
        ~paper=Cn.make([
          styles["dialogPaper"],
          "sm:w-full",
          "sm:h-full",
          "sm:max-w-full",
          "sm:max-h-full",
          "sm:m-0",
          "sm:rounded-none",
        ]),
        (),
      )}
      _open={isBuyModalOpen}
      onClose={(_, _) => handleBuyModalClose()}
      onExited={_ => handleBuyModalClosed()}>
      <MaterialUi.DialogTitle
        disableTypography={true}
        classes={MaterialUi.DialogTitle.Classes.make(
          ~root=Cn.make([
            "flex",
            "p-4",
            "border-b",
            "border-solid",
            "border-darkBorder",
            "grid",
            "grid-cols-2",
            "sm:px-4",
            "sm:py-4",
            "sm:block",
          ]),
          (),
        )}>
        <div className={Cn.make(["flex", "flex-row", "items-center"])}>
          <MaterialUi.IconButton onClick={_ => handleBuyModalClose()} size=#Small>
            <Externals.MaterialUi_Icons.Close />
          </MaterialUi.IconButton>
          <MaterialUi.Typography
            color=#Primary
            variant=#H6
            classes={MaterialUi.Typography.Classes.make(
              ~root=Cn.make(["leading-none", "mt-1", "ml-2", "bold"]),
              (),
            )}>
            {React.string("listing")}
          </MaterialUi.Typography>
        </div>
        {switch buyParams {
        | Some({quickbuy}) if !quickbuy => <QuickbuyPrompt className={Cn.make(["sm:hidden"])} />
        | _ => React.null
        }}
      </MaterialUi.DialogTitle>
      <MaterialUi.DialogContent
        classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["p-4"]), ())}>
        {switch buyParams {
        | Some({collectionSlug, orderId, quickbuy}) =>
          <QueryRenderers_Buy
            collectionSlug={collectionSlug}
            orderId={orderId}
            quickbuy={quickbuy}
            seaportClient={seaportClient}
          />
        | _ => React.null
        }}
      </MaterialUi.DialogContent>
    </MaterialUi.Dialog>
    {children}
  </ContextProvider>
}
