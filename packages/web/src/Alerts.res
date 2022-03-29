@react.component
let default = () => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let buyParams = switch (
    router.query->Js.Dict.get("buyCollectionSlug"),
    router.query->Js.Dict.get("buyOrderId")->Belt.Option.flatMap(Belt.Float.fromString),
  ) {
  | (Some(collectionSlug), Some(orderId)) => Some((collectionSlug, orderId))
  | _ => None
  }
  let (isBuyDrawerOpen, setIsBuyDrawerOpen) = React.useState(_ => Js.Option.isSome(buyParams))

  let _ = React.useEffect1(() => {
    let _ = setIsBuyDrawerOpen(_ => Js.Option.isSome(buyParams))
    None
  }, [Js.Option.isSome(buyParams)])

  let handleBuyDrawerClose = ev => {
    Js.log2("handleBuyDrawerClose", ev)
    setIsBuyDrawerOpen(_ => false)
  }
  let handleBuyDrawerClosed = _ => {
    Js.log("handleBuyDrawerClosed")
    Externals.Next.Router.replaceWithParams(router, "/alerts", None, {shallow: true}) // clear query params
  }

  Js.log2("isBuyDrawerOpen", isBuyDrawerOpen)

  <>
    <MaterialUi.Drawer
      anchor=#Left
      _open={isBuyDrawerOpen}
      variant=#Temporary
      onClose={handleBuyDrawerClose}
      _SlideProps={{
        "onExited": handleBuyDrawerClosed,
      }}>
      {buyParams
      ->Belt.Option.map(((collectionSlug, orderId)) =>
        <QueryRenderers_Buy
          collectionSlug={collectionSlug} orderId={orderId} onClose={handleBuyDrawerClose}
        />
      )
      ->Belt.Option.getWithDefault(React.null)}
    </MaterialUi.Drawer>
    <main
      className={Cn.make([
        "px-4",
        "pt-4",
        "sm:px-0",
        "sm:pt-2",
        "font-mono",
        "flex",
        "flex-col",
        "flex-1",
        "overflow-y-auto",
        "bg-white",
        "mx-auto",
      ])}
      style={ReactDOM.Style.make(~maxWidth="100rem", ())}>
      <QueryRenderers_Alerts />
    </main>
  </>
}
