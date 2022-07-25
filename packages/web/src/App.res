type pageProps

module PageComponent = {
  type t = React.component<pageProps>
}

type props = {
  @as("Component")
  component: PageComponent.t,
  pageProps: pageProps,
}

let theme = MaterialUi.Theme.create({
  open MaterialUi.ThemeOptions
  make(
    ~palette=PaletteOptions.make(
      ~primary=Primary.make(~main="#212121", ()),
      ~secondary=Secondary.make(~main="#e64a19", ()),
      (),
    ),
    ~typography=Typography.make(
      ~fontFamily=[
        "Roboto Mono",
        "Menlo",
        "Monaco",
        "Consolas",
        "Roboto Mono",
        "SFMono-Regular",
        "Segoe UI",
        "Courier",
        "monospace",
      ]->Belt.Array.joinWith(", ", i => i),
      (),
    ),
    (),
  )
})
Services.Logger.initialize()

let wagmiConnector = ({chainId}: Externals.Wagmi.Provider.chainIdParam) => {
  open Externals.Wagmi

  [
    makeInjectedConnector({
      chains: defaultChains,
      options: {
        shimDisconnect: true,
      },
    }),
    makeWalletConectConnector({
      options: {
        qrcode: true,
        infuraId: Config.infuraId,
      },
    }),
  ]
}

let infuraProvider = ({chainId}: Externals.Wagmi.Provider.chainIdParam) =>
  Externals.Ethers.Provider.makeInfuraProvider(chainId, Config.infuraId)

let default = (props: props): React.element => {
  let {component, pageProps} = props
  let elem = React.createElement(component, pageProps)
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()

  let _ = React.useEffect1(() => {
    let query = router.asPath->Services.Next.parseQuery
    let isFlareCTA = switch (
      query->Belt.Option.flatMap(q =>
        q
        ->Externals.Webapi.URLSearchParams.get("createAlertCollectionContractAddress")
        ->Js.Nullable.toOption
      ),
      query->Belt.Option.flatMap(q =>
        q->Externals.Webapi.URLSearchParams.get("createAlertCollectionSlug")->Js.Nullable.toOption
      ),
    ) {
    | (Some(_), Some(_)) => true
    | _ => false
    }

    Services.Logger.logWithData(
      "route",
      "changed",
      [
        ("pathname", router.pathname->Js.Json.string),
        ("isFlareCTA", isFlareCTA->Js.Json.boolean),
        (
          "query",
          query
          ->Belt.Option.map(Externals.Webapi.URLSearchParams.toString)
          ->Belt.Option.getWithDefault("")
          ->Js.Json.string,
        ),
      ]
      ->Js.Dict.fromArray
      ->Js.Json.object_,
    )
    None
  }, [router.pathname])

  <>
    <Externals.Next.Head>
      <title> {React.string("sunspot")} </title>
      <meta
        name="description"
        content="sunspot alerts you when events occur within eth nft secondary markets."
      />
      <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
      <link rel="icon" type_="image/png" sizes="32x32" href="/favicon-32x32.png" />
      <link rel="icon" type_="image/png" sizes="16x16" href="/favicon-16x16.png" />
      <link rel="manifest" href="/manifest.json" />
    </Externals.Next.Head>
    <MaterialUi.ThemeProvider theme={theme}>
      <Contexts_Snackbar>
        <Externals.Wagmi.Provider
          connectors={wagmiConnector} autoConnect={true} provider={infuraProvider}>
          <Contexts_Auth>
            <Contexts_Apollo>
              <Contexts_AccountSubscriptionDialog>
                <Contexts_AlertCreateAndUpdateDialog>
                  <Contexts_OpenSeaEventDialog>
                    {switch router.pathname {
                    | "/events"
                    | "/alerts" =>
                      <Layouts.PageWithHeader>
                        <QueryRenderers.Header> {elem} </QueryRenderers.Header>
                      </Layouts.PageWithHeader>
                    | _ => elem
                    }}
                  </Contexts_OpenSeaEventDialog>
                </Contexts_AlertCreateAndUpdateDialog>
              </Contexts_AccountSubscriptionDialog>
            </Contexts_Apollo>
          </Contexts_Auth>
        </Externals.Wagmi.Provider>
      </Contexts_Snackbar>
    </MaterialUi.ThemeProvider>
  </>
}
