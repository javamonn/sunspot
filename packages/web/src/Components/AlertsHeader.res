@react.component
let make = (
  ~authentication: Contexts.Auth.authentication,
  ~onConnectWalletClicked,
  ~onWalletButtonClicked,
  ~onCreateAlertClicked,
) => {
  let ({data: account}: Externals.Wagmi.UseAccount.result, _) = Externals.Wagmi.UseAccount.use()

  <header className={Cn.make(["flex", "flex-row", "justify-between", "items-center"])}>
    <h1 className={Cn.make(["font-mono", "text-darkPrimary", "font-bold", "leading-none"])}>
      <Externals.Next.Link href="/"> {React.string("sunspot")} </Externals.Next.Link>
      {React.string(" / alerts")}
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
      {switch account {
      | Some({address, connector}) =>
        <WalletButton
          onClick={onWalletButtonClicked}
          authentication={authentication}
          address={address}
          provider={connector->Externals_Wagmi.Connector.provider}
        />
      | None => <ConnectWalletButton onClick={onConnectWalletClicked} />
      }}
      <AboutPopover />
    </div>
  </header>
}
