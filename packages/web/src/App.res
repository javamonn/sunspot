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
      ~secondary=Secondary.make(~main="#9E9E9E", ()),
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

let default = (props: props): React.element => {
  let {component, pageProps} = props

  let elem = React.createElement(component, pageProps)

  <MaterialUi.ThemeProvider theme={theme}>
    <Contexts.Eth>
      <Contexts.Auth> <Contexts.Apollo> {elem} </Contexts.Apollo> </Contexts.Auth>
    </Contexts.Eth>
  </MaterialUi.ThemeProvider>
}
