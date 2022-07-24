let styles = %raw("require('./Contexts_OpenSeaEventDialog.module.css')")

module ContextProvider = {
  include React.Context

  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(Contexts_OpenSeaEventDialog_Context.context)
}

type params = {
  contractAddress: string,
  tokenId: string,
  id: float,
  quickbuy: bool,
}

@react.component
let make = (~children) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let params = {
    let queryParams = router.asPath->Services.Next.parseQuery
    switch (
      queryParams->Belt.Option.flatMap(q =>
        q->Externals.Webapi.URLSearchParams.get("openSeaEventContractAddress")->Js.Nullable.toOption
      ),
      queryParams->Belt.Option.flatMap(q =>
        q->Externals.Webapi.URLSearchParams.get("openSeaEventTokenId")->Js.Nullable.toOption
      ),
      queryParams
      ->Belt.Option.flatMap(q =>
        q->Externals.Webapi.URLSearchParams.get("openSeaEventId")->Js.Nullable.toOption
      )
      ->Belt.Option.flatMap(Belt.Float.fromString),
    ) {
    | (Some(contractAddress), Some(tokenId), Some(id)) =>
      Some({
        contractAddress: contractAddress,
        tokenId: tokenId,
        id: id,
        quickbuy: queryParams
        ->Belt.Option.flatMap(q =>
          q->Externals.Webapi.URLSearchParams.get("openSeaEventQuickbuy")->Js.Nullable.toOption
        )
        ->Belt.Option.map(q => q === "true")
        ->Belt.Option.getWithDefault(false),
      })
    | _ => None
    }
  }
  Js.log2("params", params)
  let (isOpen, setIsOpen) = React.useState(_ => Js.Option.isSome(params))
  let (isQuickbuyTxPending, setIsQuickbuyTxPending) = React.useState(_ => isOpen)

  let handleClose = ev => {
    Js.log2("handleClose", ev)
    setIsOpen(_ => false)
  }
  let handleClosed = _ => {
    Externals.Next.Router.replaceWithParams(router, router.pathname, None, {shallow: true}) // clear query params
  }

  let _ = React.useEffect1(() => {
    let nextIsOpen = Js.Option.isSome(params)
    let _ = setIsOpen(_ => nextIsOpen)
    Services.Logger.logWithData(
      "buy",
      "setIsBuyDrawerOpen",
      [("isOpen", params->Js.Option.isSome->Js.Json.boolean)]->Js.Dict.fromArray->Js.Json.object_,
    )
    None
  }, [Js.Option.isSome(params)])

  <ContextProvider
    value={
      Contexts_OpenSeaEventDialog_Context.isQuickbuyTxPending: isQuickbuyTxPending,
      setIsQuickbuyTxPending: newIsQuickbuyTxPending => {
        setIsQuickbuyTxPending(_ => newIsQuickbuyTxPending)
      },
      isOpen: isOpen,
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
      _open={isOpen}
      onClose={(_, _) => handleClose()}
      onExited={_ => handleClosed()}>
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
          <MaterialUi.IconButton onClick={_ => handleClose()} size=#Small>
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
        {switch params {
        | Some({quickbuy}) if !quickbuy => <QuickbuyPrompt className={Cn.make(["sm:hidden"])} />
        | _ => React.null
        }}
      </MaterialUi.DialogTitle>
      <MaterialUi.DialogContent
        classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["p-4"]), ())}>
        {switch params {
        | Some({contractAddress, tokenId, id, quickbuy}) =>
          <QueryRenderers_OpenSeaEvent
            contractAddress={contractAddress} tokenId={tokenId} id={id} quickbuy={quickbuy}
          />
        | _ => React.null
        }}
      </MaterialUi.DialogContent>
    </MaterialUi.Dialog>
    {children}
  </ContextProvider>
}
