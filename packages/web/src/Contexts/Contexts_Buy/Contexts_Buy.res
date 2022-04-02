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

@react.component
let make = (~children) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let queryParams = router.asPath->parseQuery
  let buyParams = switch (
    queryParams->Belt.Option.flatMap(q =>
      q->Externals.Webapi.URLSearchParams.get("buyCollectionSlug")
    ),
    queryParams
    ->Belt.Option.flatMap(q => q->Externals.Webapi.URLSearchParams.get("buyOrderId"))
    ->Belt.Option.flatMap(Belt.Float.fromString),
  ) {
  | (Some(collectionSlug), Some(orderId)) => Some((collectionSlug, orderId))
  | _ => None
  }
  let (isBuyModalOpen, setIsBuyModalOpen) = React.useState(_ => Js.Option.isSome(buyParams))
  let (isQuickbuyTxPending, setIsQuickbuyTxPending) = React.useState(_ => isBuyModalOpen)

  let handleBuyModalClose = ev => {
    setIsBuyModalOpen(_ => false)
  }
  let handleBuyModalClosed = _ => {
    Externals.Next.Router.replaceWithParams(router, "/alerts", None, {shallow: true}) // clear query params
  }

  let _ = React.useEffect1(() => {
    let nextIsBuyModalOpen = Js.Option.isSome(buyParams)
    let _ = setIsBuyModalOpen(currentBuyParams => nextIsBuyModalOpen)
    Services.Logger.logWithData(
      "buy",
      "setIsBuyDrawerOpen",
      [("isOpen", buyParams->Js.Option.isSome->Js.Json.boolean)]
      ->Js.Dict.fromArray
      ->Js.Json.object_,
    )
    None
  }, [Js.Option.isSome(buyParams)])

  <ContextProvider
    value={
      Contexts_Buy_Context.isQuickbuyTxPending: isQuickbuyTxPending,
      setIsQuickbuyTxPending: newIsQuickbuyTxPending => {
        setIsQuickbuyTxPending(_ => newIsQuickbuyTxPending)
      },
      isBuyModalOpen: isBuyModalOpen,
    }>
    <MaterialUi.Dialog
      classes={MaterialUi.Dialog.Classes.make(~paper=Cn.make([styles["dialogPaper"]]), ())}
      _open={isBuyModalOpen}
      onClose={(_, _) => handleBuyModalClose()}
      onExited={_ => handleBuyModalClosed()}>
      <MaterialUi.DialogTitle
        disableTypography={true}
        classes={MaterialUi.DialogTitle.Classes.make(
          ~root=Cn.make([
            "flex",
            "justify-between",
            "items-center",
            "border-b",
            "border-solid",
            "border-darkBorder",
          ]),
          (),
        )}>
        <div className={Cn.make(["flex", "flex-row", "items-center"])}>
          <MaterialUi.IconButton
            onClick={_ => handleBuyModalClose()}
            size=#Small
            classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["mr-4"]), ())}>
            <Externals.MaterialUi_Icons.Close />
          </MaterialUi.IconButton>
          <MaterialUi.Typography
            color=#Primary
            variant=#H6
            classes={MaterialUi.Typography.Classes.make(
              ~root=Cn.make(["leading-none", "mt-1"]),
              (),
            )}>
            {React.string("execute buy")}
          </MaterialUi.Typography>
        </div>
      </MaterialUi.DialogTitle>
      <MaterialUi.DialogContent
        classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["p-4"]), ())}>
        {switch buyParams {
        | Some((collectionSlug, orderId)) =>
          <QueryRenderers_Buy
            collectionSlug={collectionSlug} orderId={orderId} onClose={handleBuyModalClose}
          />
        | _ => React.null
        }}
      </MaterialUi.DialogContent>
    </MaterialUi.Dialog>
    {children}
  </ContextProvider>
}
