@react.component
let make = (
  ~eth: Contexts.Eth.state,
  ~authentication: Contexts.Auth.authentication,
  ~onConnectWalletClicked,
  ~onWalletButtonClicked,
  ~onCreateAlertClicked,
) => {
  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center"])}>
    <h1 className={Cn.make(["font-mono", "text-darkPrimary", "font-bold", "leading-none"])}>
      {React.string("sunspot / alerts")}
    </h1>
    <div className={Cn.make(["flex", "flex-row", "justify-center", "items-center"])}>
      <MaterialUi.Button
        onClick={_ => {
          Services.Logger.log("create alert", "display modal")
          onCreateAlertClicked()
        }}
        startIcon={<Externals.MaterialUi_Icons.Add />}
        variant=#Contained
        color=#Primary
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-8"]),
          ~label=Cn.make(["normal-case"]),
          (),
        )}>
        {React.string("create alert")}
      </MaterialUi.Button>
      {switch eth {
      | Connected({address, provider}) =>
        <WalletButton
          provider onClick={onWalletButtonClicked} authentication={authentication} address={address}
        />
      | _ => <ConnectWalletButton onClick={onConnectWalletClicked} />
      }}
      <AboutPopover />
    </div>
  </header>
}
