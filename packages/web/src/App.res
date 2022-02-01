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
    </Externals.Next.Head>
    <MaterialUi.ThemeProvider theme={theme}>
      <Contexts.Eth>
        <Contexts.Auth> <Contexts.Apollo> {elem} </Contexts.Apollo> </Contexts.Auth>
      </Contexts.Eth>
    </MaterialUi.ThemeProvider>
  </>
}
