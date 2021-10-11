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
      ~primary=Primary.make(~main="#FFF", ()),
      ~secondary=Secondary.make(~main="#000", ()),
      (),
    ),
    (),
  )
})

let default = (props: props): React.element => {
  let {component, pageProps} = props

  let elem = React.createElement(component, pageProps)

  <MaterialUi.ThemeProvider theme={theme}> {elem} </MaterialUi.ThemeProvider>
}
