@react.component
let make = () => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)

  let handleConnectWalletClicked = _ => {
    let _ = signIn()
  }

  <AlertsHeader eth onConnectWalletClicked={handleConnectWalletClicked} />
}
