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

  let rpcUrl =
    defaultChains
    ->Belt.Array.getBy(chain => id(chain) === chainId)
    ->Belt.Option.flatMap(chain => chain->rpcUrls->Belt.Array.get(0))
    ->Belt.Option.getWithDefault(
      chain
      ->Js.Dict.get("mainnet")
      ->Belt.Option.flatMap(chain => chain->rpcUrls->Belt.Array.get(0))
      ->Belt.Option.getExn,
    )

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

let infuraWebSocketProvider = ({chainId}: Externals.Wagmi.Provider.chainIdParam) =>
  Externals.Ethers.Provider.makeInfuraWebSocketProvider(chainId, Config.infuraId)

let default = (props: props): React.element => {
  let {component, pageProps} = props
  let elem = React.createElement(component, pageProps)

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
      <Contexts.Snackbar>
        <Externals.Wagmi.Provider
          connectors={wagmiConnector}
          autoConnect={true}
          provider={infuraProvider}
          webSocketProvider={infuraWebSocketProvider}>
          <Contexts.Auth>
            <Contexts.Apollo> <Contexts_Buy> {elem} </Contexts_Buy> </Contexts.Apollo>
          </Contexts.Auth>
        </Externals.Wagmi.Provider>
      </Contexts.Snackbar>
    </MaterialUi.ThemeProvider>
  </>
}
